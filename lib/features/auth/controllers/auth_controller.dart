import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safe_watch/core/api/auth/trakt_auth_service.dart';
import 'package:safe_watch/core/api/clients/trakt_client.dart';
import 'package:safe_watch/core/config/env_config.dart';
import 'package:safe_watch/features/auth/models/auth_state.dart';
import 'package:safe_watch/features/auth/repositories/auth_repository.dart';
import 'package:safe_watch/features/auth/repositories/auth_repository_interface.dart';

// ============================================================================
// Safe Watch — Auth Controller (Riverpod)
// ============================================================================
// Fluxo de dados:
//   LoginTemplate (UI) → AuthController (lógica) → AuthRepository (dados) → AuthState (modelo)
//                                                → TraktAuthService (OAuth)
//
// O controller NÃO contém lógica de UI.
// Ele expõe estado via Notifier e orquestra chamadas ao repository + Trakt OAuth.
// ============================================================================

/// Provider do repositório de autenticação.
final authRepositoryProvider = Provider<AuthRepositoryInterface>((ref) {
  return AuthRepository();
});

/// Provider do serviço OAuth do Trakt.
final traktAuthServiceProvider = Provider<TraktAuthService?>((ref) {
  if (!EnvConfig.isTraktConfigured) return null;
  final traktClient = TraktClient();
  return TraktAuthService(traktClient: traktClient);
});

/// Provider do controller de autenticação.
final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Controller de autenticação usando Riverpod [Notifier].
///
/// Gerencia:
/// - Login/registro local (mock)
/// - Autenticação OAuth com Trakt.tv
/// - Estado de autenticação do usuário
///
/// Fluxo:
/// ```
/// LoginTemplate
///   └─► ref.read(authControllerProvider.notifier).signIn(...)
///         └─► AuthRepository.signInWithEmail(...)
///               └─► retorna AuthState
///         └─► state = authState
///   └─► ref.read(authControllerProvider.notifier).signInWithTrakt()
///         └─► TraktAuthService.startAuthFlow()
///               └─► Abre browser → OAuth → callback
///         └─► TraktAuthService.handleAuthCallback(code)
///               └─► TraktClient.exchangeCodeForToken(code)
///   └─► ref.watch(authControllerProvider) → rebuida UI
/// ```
class AuthController extends Notifier<AuthState> {
  late final AuthRepositoryInterface _repository;
  TraktAuthService? _traktAuthService;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    _traktAuthService = ref.watch(traktAuthServiceProvider);
    return const AuthState.initial();
  }

  /// Realiza login com email e senha (mock).
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.authenticating);

    try {
      final result = await _repository.signInWithEmail(
        email: email,
        password: password,
      );
      state = result;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Erro ao fazer login: $e',
      );
    }
  }

  /// Registra um novo usuário (mock).
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.authenticating);

    try {
      final result = await _repository.signUpWithEmail(
        name: name,
        email: email,
        password: password,
      );
      state = result;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Erro ao registrar: $e',
      );
    }
  }

  /// Inicia o fluxo OAuth do Trakt.tv.
  ///
  /// Abre o browser para o usuário autorizar o app.
  /// Após autorização, chamar [handleTraktCallback] com o code.
  Future<void> signInWithTrakt() async {
    if (_traktAuthService == null) {
      state = const AuthState(
        status: AuthStatus.error,
        errorMessage: 'Trakt não configurado. Defina TRAKT_CLIENT_ID e TRAKT_CLIENT_SECRET.',
      );
      return;
    }

    state = state.copyWith(status: AuthStatus.authenticating);

    final launched = await _traktAuthService!.startAuthFlow();
    if (!launched) {
      state = const AuthState(
        status: AuthStatus.error,
        errorMessage: 'Não foi possível abrir o browser para autenticação.',
      );
    }
    // O estado será atualizado em handleTraktCallback quando o user voltar.
  }

  /// Processa o callback OAuth do Trakt.
  ///
  /// [code]: código de autorização recebido no redirect URI.
  Future<void> handleTraktCallback(String code) async {
    if (_traktAuthService == null) return;

    state = state.copyWith(status: AuthStatus.authenticating);

    final success = await _traktAuthService!.handleAuthCallback(code);
    if (success) {
      state = const AuthState(
        status: AuthStatus.authenticated,
        userId: 'trakt-user',
        userName: 'Trakt User',
      );
    } else {
      state = const AuthState(
        status: AuthStatus.error,
        errorMessage: 'Falha na autenticação com o Trakt.',
      );
    }
  }

  /// Restaura sessão do Trakt (chamado no startup).
  Future<void> restoreTraktSession() async {
    if (_traktAuthService == null) return;

    final token = await _traktAuthService!.restoreSession();
    if (token != null) {
      state = const AuthState(
        status: AuthStatus.authenticated,
        userId: 'trakt-user',
        userName: 'Trakt User',
      );
    }
  }

  /// Realiza logout.
  Future<void> signOut() async {
    await _repository.signOut();
    if (_traktAuthService != null) {
      await _traktAuthService!.logout();
    }
    state = const AuthState.initial();
  }
}
