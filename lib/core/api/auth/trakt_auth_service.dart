import 'package:safe_watch/core/api/api_config.dart';
import 'package:safe_watch/core/api/clients/trakt_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================================
// Safe Watch — Trakt OAuth 2.0 Service
// ============================================================================
// Gerencia o fluxo completo de autenticação OAuth 2.0 do Trakt.tv.
//
// Fluxo:
// 1. Abre URL de autorização no browser
// 2. Usuário autoriza → callback com code
// 3. Troca code por access_token + refresh_token
// 4. Persiste tokens em SharedPreferences
// 5. Auto-refresh quando token expirar (3 meses)
// ============================================================================

/// Serviço de autenticação OAuth 2.0 do Trakt.tv.
///
/// Gerencia login, logout, persistência e refresh de tokens.
class TraktAuthService {
  TraktAuthService({required TraktClient traktClient})
      : _traktClient = traktClient;

  final TraktClient _traktClient;

  // Keys para SharedPreferences.
  static const _keyAccessToken = 'trakt_access_token';
  static const _keyRefreshToken = 'trakt_refresh_token';
  static const _keyExpiresAt = 'trakt_expires_at';

  /// Abre o browser para o usuário autorizar o app.
  ///
  /// Após autorização, o Trakt redireciona para o redirect URI
  /// com um `code` que deve ser passado para [handleAuthCallback].
  Future<bool> startAuthFlow() async {
    final url = Uri.parse(ApiConfig.traktAuthUrl);
    if (await canLaunchUrl(url)) {
      return launchUrl(url, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Processa o callback OAuth e troca o code por tokens.
  ///
  /// [code]: código de autorização recebido no redirect URI.
  /// Retorna true se a autenticação foi bem-sucedida.
  Future<bool> handleAuthCallback(String code) async {
    try {
      final tokenData = await _traktClient.exchangeCodeForToken(code);
      await _persistTokens(tokenData);
      _traktClient.updateAccessToken(tokenData['access_token'] as String);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Verifica se o usuário está autenticado no Trakt.
  ///
  /// Tenta restaurar tokens persistidos e verifica validade.
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_keyAccessToken);
    final expiresAt = prefs.getInt(_keyExpiresAt);

    if (accessToken == null || accessToken.isEmpty) return false;

    // Verificar expiração.
    if (expiresAt != null) {
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
      if (DateTime.now().isAfter(expiryDate)) {
        // Token expirado, tentar refresh.
        return _tryRefreshToken();
      }
    }

    // Token válido, atualizar no client.
    _traktClient.updateAccessToken(accessToken);
    return true;
  }

  /// Restaura o access token persistido no client.
  ///
  /// Chamado no startup do app para restaurar a sessão.
  Future<String?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_keyAccessToken);

    if (accessToken != null && accessToken.isNotEmpty) {
      // Verificar se precisa de refresh.
      final expiresAt = prefs.getInt(_keyExpiresAt);
      if (expiresAt != null) {
        final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
        // Refresh se falta menos de 7 dias para expirar.
        if (DateTime.now().isAfter(expiryDate.subtract(const Duration(days: 7)))) {
          await _tryRefreshToken();
          return prefs.getString(_keyAccessToken);
        }
      }
      _traktClient.updateAccessToken(accessToken);
      return accessToken;
    }
    return null;
  }

  /// Realiza logout: revoga token e limpa persistência.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_keyAccessToken);

    if (accessToken != null && accessToken.isNotEmpty) {
      try {
        await _traktClient.revokeToken(accessToken);
      } catch (_) {
        // Ignora erro na revogação (token pode já estar expirado).
      }
    }

    await _clearTokens();
    _traktClient.updateAccessToken('');
  }

  /// Tenta renovar o access token usando o refresh token.
  Future<bool> _tryRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_keyRefreshToken);

    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final tokenData = await _traktClient.refreshAccessToken(refreshToken);
      await _persistTokens(tokenData);
      _traktClient.updateAccessToken(tokenData['access_token'] as String);
      return true;
    } catch (e) {
      // Refresh falhou, limpar tokens.
      await _clearTokens();
      return false;
    }
  }

  /// Persiste tokens no SharedPreferences.
  Future<void> _persistTokens(Map<String, dynamic> tokenData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, tokenData['access_token'] as String);
    await prefs.setString(_keyRefreshToken, tokenData['refresh_token'] as String);

    // Calcular timestamp de expiração.
    final createdAt = tokenData['created_at'] as int;
    final expiresIn = tokenData['expires_in'] as int;
    await prefs.setInt(_keyExpiresAt, createdAt + expiresIn);
  }

  /// Limpa tokens persistidos.
  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyExpiresAt);
  }
}
