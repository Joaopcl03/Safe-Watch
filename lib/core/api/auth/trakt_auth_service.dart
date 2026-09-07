import 'dart:async';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:safe_watch/core/api/api_config.dart';
import 'package:safe_watch/core/api/clients/trakt_client.dart';
import 'package:safe_watch/core/config/env_config.dart';

// ============================================================================
// Safe Watch — Trakt Auth Service
// ============================================================================
// Implementa o fluxo OAuth 2.0 do Trakt.tv.
//
// Fluxo:
//   1. [authorize()]     → gera URL + abre no browser
//   2. [handleCallback()] → recebe o code via deep link
//   3. [_exchangeCode()]  → troca code por access + refresh token
//   4. [_persistTokens()] → salva tokens no SharedPreferences
//   5. Auto-refresh       → renova access token quando necessário
//
// Deep link configurado: safewatch://trakt/callback?code=XXX
// Registre este scheme no AndroidManifest.xml e Info.plist.
// ============================================================================

/// Serviço responsável pelo fluxo OAuth 2.0 do Trakt.tv.
///
/// Singleton — use [TraktAuthService.instance].
class TraktAuthService {
  TraktAuthService._();

  static final TraktAuthService instance = TraktAuthService._();

  // Chaves de persistência no SharedPreferences.
  static const _keyAccessToken = 'trakt_access_token';
  static const _keyRefreshToken = 'trakt_refresh_token';
  static const _keyExpiresAt = 'trakt_expires_at';
  static const _keyUserId = 'trakt_user_slug';

  /// Completer usado para aguardar o callback do OAuth.
  Completer<String>? _pendingCodeCompleter;

  // --------------------------------------------------------------------------
  // Estado de Autenticação
  // --------------------------------------------------------------------------

  /// Retorna true se há um access token válido persistido.
  Future<bool> get isAuthenticated async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyAccessToken);
    final expiresAt = prefs.getInt(_keyExpiresAt);

    if (token == null || expiresAt == null) return false;

    // Verifica se o token ainda não expirou (com margem de 1 hora).
    final expiry = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
    return DateTime.now().isBefore(expiry.subtract(const Duration(hours: 1)));
  }

  /// Retorna o access token atual, renovando se necessário.
  ///
  /// Retorna null se não autenticado.
  Future<String?> getValidAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_keyAccessToken);
    final refreshToken = prefs.getString(_keyRefreshToken);
    final expiresAt = prefs.getInt(_keyExpiresAt);

    if (accessToken == null) return null;

    // Verifica se o token está próximo do vencimento (margem de 7 dias).
    if (expiresAt != null) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
      final needsRefresh = DateTime.now()
          .isAfter(expiry.subtract(const Duration(days: 7)));

      if (needsRefresh && refreshToken != null) {
        return _refreshAccessToken(refreshToken);
      }
    }

    // Injeta o token no TraktClient para requisições futuras.
    TraktClient.instance.accessToken = accessToken;
    return accessToken;
  }

  // --------------------------------------------------------------------------
  // Fluxo de Autorização
  // --------------------------------------------------------------------------

  /// Inicia o fluxo OAuth: gera a URL e abre no browser.
  ///
  /// Retorna a URL de autorização para que a UI possa exibi-la
  /// ou para que o [url_launcher] a abra automaticamente.
  Future<String> authorize() async {
    _pendingCodeCompleter = Completer<String>();

    final authUrl = Uri.parse(ApiConfig.traktAuthUrl).replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': EnvConfig.traktClientId,
        'redirect_uri': EnvConfig.traktRedirectUri,
      },
    );

    developer.log(
      '[TraktAuth] Abrindo URL de autorização: $authUrl',
      name: 'SafeWatch.Auth',
    );

    final canOpen = await canLaunchUrl(authUrl);
    if (canOpen) {
      await launchUrl(authUrl, mode: LaunchMode.externalApplication);
    }

    return authUrl.toString();
  }

  /// Processa o callback do OAuth com o código de autorização.
  ///
  /// Deve ser chamado quando o deep link `safewatch://trakt/callback`
  /// é recebido pelo app. Extrai o `code` e completa o fluxo.
  ///
  /// Retorna true se a autenticação foi concluída com sucesso.
  Future<bool> handleCallback(Uri callbackUri) async {
    final code = callbackUri.queryParameters['code'];
    final error = callbackUri.queryParameters['error'];

    if (error != null) {
      developer.log(
        '[TraktAuth] Erro no callback: $error',
        name: 'SafeWatch.Auth',
      );
      _pendingCodeCompleter?.completeError(
        TraktAuthException('OAuth negado pelo usuário: $error'),
      );
      _pendingCodeCompleter = null;
      return false;
    }

    if (code == null) {
      developer.log(
        '[TraktAuth] Callback sem código de autorização',
        name: 'SafeWatch.Auth',
      );
      return false;
    }

    try {
      await _exchangeCode(code);
      _pendingCodeCompleter?.complete(code);
      _pendingCodeCompleter = null;
      return true;
    } catch (e) {
      _pendingCodeCompleter?.completeError(e);
      _pendingCodeCompleter = null;
      return false;
    }
  }

  /// Troca o código de autorização por access + refresh token.
  Future<void> _exchangeCode(String code) async {
    final tokenData = await TraktClient.instance.exchangeCode(
      code: code,
      redirectUri: EnvConfig.traktRedirectUri,
    );

    await _persistTokens(tokenData);

    developer.log(
      '[TraktAuth] Tokens obtidos com sucesso',
      name: 'SafeWatch.Auth',
    );
  }

  // --------------------------------------------------------------------------
  // Refresh Token
  // --------------------------------------------------------------------------

  /// Renova o access token usando o refresh token.
  ///
  /// Persiste os novos tokens e atualiza o TraktClient.
  /// Retorna o novo access token, ou null em caso de falha.
  Future<String?> _refreshAccessToken(String refreshToken) async {
    try {
      developer.log(
        '[TraktAuth] Renovando access token...',
        name: 'SafeWatch.Auth',
      );

      final tokenData = await TraktClient.instance.refreshToken(
        refreshToken: refreshToken,
        redirectUri: EnvConfig.traktRedirectUri,
      );

      await _persistTokens(tokenData);

      final newToken = tokenData['access_token'] as String?;
      TraktClient.instance.accessToken = newToken;

      developer.log(
        '[TraktAuth] Access token renovado com sucesso',
        name: 'SafeWatch.Auth',
      );

      return newToken;
    } catch (e) {
      developer.log(
        '[TraktAuth] Falha ao renovar token: $e',
        name: 'SafeWatch.Auth',
        error: e,
      );
      // Token inválido — força novo login.
      await signOut();
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // Persistência
  // --------------------------------------------------------------------------

  /// Salva os tokens OAuth no SharedPreferences.
  Future<void> _persistTokens(Map<String, dynamic> tokenData) async {
    final prefs = await SharedPreferences.getInstance();

    final accessToken = tokenData['access_token'] as String?;
    final refreshToken = tokenData['refresh_token'] as String?;
    final expiresIn = tokenData['expires_in'] as int?;

    if (accessToken != null) {
      await prefs.setString(_keyAccessToken, accessToken);
      TraktClient.instance.accessToken = accessToken;
    }

    if (refreshToken != null) {
      await prefs.setString(_keyRefreshToken, refreshToken);
    }

    if (expiresIn != null) {
      // Armazena como timestamp Unix de expiração.
      final expiresAt =
          DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresIn;
      await prefs.setInt(_keyExpiresAt, expiresAt);
    }
  }

  // --------------------------------------------------------------------------
  // Logout
  // --------------------------------------------------------------------------

  /// Revoga o token e limpa todos os dados de autenticação persistidos.
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_keyAccessToken);

    // Tenta revogar o token na API do Trakt.
    if (accessToken != null) {
      try {
        await TraktClient.instance.revokeToken(accessToken);
      } catch (e) {
        // Ignora erros de revogação — limpa localmente de qualquer forma.
        developer.log(
          '[TraktAuth] Erro ao revogar token (ignorado): $e',
          name: 'SafeWatch.Auth',
        );
      }
    }

    // Limpa tokens locais.
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyExpiresAt);
    await prefs.remove(_keyUserId);

    // Limpa token do cliente.
    TraktClient.instance.accessToken = null;

    developer.log(
      '[TraktAuth] Logout do Trakt concluído',
      name: 'SafeWatch.Auth',
    );
  }

  /// Inicializa o serviço restaurando tokens persistidos.
  ///
  /// Deve ser chamado no `main()` antes de usar qualquer funcionalidade Trakt.
  Future<void> init() async {
    final token = await getValidAccessToken();
    if (token != null) {
      developer.log(
        '[TraktAuth] Token Trakt restaurado da persistência',
        name: 'SafeWatch.Auth',
      );
    }
  }
}

// ----------------------------------------------------------------------------
// Exceções
// ----------------------------------------------------------------------------

/// Exceção específica para erros no fluxo OAuth do Trakt.
class TraktAuthException implements Exception {
  const TraktAuthException(this.message);

  final String message;

  @override
  String toString() => 'TraktAuthException: $message';
}
