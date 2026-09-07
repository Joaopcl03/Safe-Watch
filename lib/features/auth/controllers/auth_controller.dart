import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safe_watch/core/api/auth/trakt_auth_service.dart';
import 'package:safe_watch/features/auth/models/auth_state.dart';
import 'package:safe_watch/features/auth/repositories/auth_repository.dart';
import 'package:safe_watch/features/auth/repositories/auth_repository_interface.dart';

// ============================================================================
// Safe Watch — Auth Controller (Riverpod)
// ============================================================================
// Fluxo de dados:
//   LoginTemplate (UI) → AuthController (lógica) → AuthRepository (dados) → AuthState (modelo)
//
// O controller NÃO contém lógica de UI.
// Ele expõe estado via Notifier e orquestra chamadas ao repository.
// ============================================================================

/// Provider do repositório de autenticação.
///
/// Pode ser sobrescrito em testes com `overrides` para injetar mocks.
final authRepositoryProvider = Provider<AuthRepositoryInterface>((ref) {
  return AuthRepository();
});

/// Provider do serviço OAuth do Trakt.
///
/// Pode ser sobrescrito em testes para injetar mock.
final traktAuthServiceProvider = Provider<TraktAuthService>((ref) {
  return TraktAuthService.instance;
});

/// Provider do controller de autenticação.
///
/// Expõe [AuthState] e métodos de autenticação para a UI.
final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Controller de autenticação usando Riverpod [Notifier].
///
/// Responsável por:
/// - Orquestrar chamadas ao [AuthRepositoryInterface] (login/registro local)
/// - Gerenciar o fluxo OAuth 2.0 do Trakt.tv via [TraktAuthService]
/// - Expor o [AuthState] para a UI via `ref.watch(authControllerProvider)`
/// - NÃO contém lógica de UI
///
/// Fluxo Trakt:
/// ```
/// LoginTemplate
///   └─► ref.read(authControllerProvider.notifier).signInWithTrakt()
///         └─► TraktAuthService.authorize()    → abre browser
///         └─► TraktAuthService.handleCallback() → recebe code
///         └─► state = AuthState.authenticated (com userId Trakt)
/// ```
class AuthController extends Notifier<AuthState> {
  late final AuthRepositoryInterface _repository;
  late final TraktAuthService _traktAuth;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    _traktAuth = ref.watch(traktAuthServiceProvider);
    return const AuthState.initial();
  }

  // --------------------------------------------------------------------------
  // Autenticação Local (email/senha)
  // --------------------------------------------------------------------------

  /// Realiza login com email e senha.
  ///
  /// Atualiza o estado para [AuthStatus.authenticating] durante o processo
  /// e para [AuthStatus.authenticated] ou [AuthStatus.error] ao finalizar.
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
        errorMessage: 'Erro ao fazer login: ${e.toString()}',
      );
    }
  }

  /// Registra um novo usuário.
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
        errorMessage: 'Erro ao registrar: ${e.toString()}',
      );
    }
  }

  // --------------------------------------------------------------------------
  // Autenticação Trakt.tv (OAuth 2.0)
  // --------------------------------------------------------------------------

  /// Inicia o fluxo OAuth 2.0 do Trakt.tv.
  ///
  /// Abre o browser do dispositivo na página de autorização do Trakt.
  /// O fluxo é concluído quando o deep link `safewatch://trakt/callback`
  /// é recebido pelo app e [handleTraktCallback] é chamado.
  ///
  /// Retorna a URL de autorização (útil para exibir em WebView se necessário).
  Future<String?> signInWithTrakt() async {
    state = state.copyWith(status: AuthStatus.authenticating);

    try {
      final authUrl = await _traktAuth.authorize();
      // Estado permanece como authenticating enquanto aguarda o callback.
      // A UI pode usar esse estado para exibir um loader ou cancelar.
      return authUrl;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Erro ao iniciar autenticação Trakt: ${e.toString()}',
      );
      return null;
    }
  }

  /// Processa o callback do OAuth do Trakt.
  ///
  /// Deve ser chamado quando o app receber o deep link
  /// `safewatch://trakt/callback?code=XXX`.
  ///
  /// Extrai o code, troca por tokens e atualiza o estado de autenticação.
  Future<void> handleTraktCallback(Uri callbackUri) async {
    final success = await _traktAuth.handleCallback(callbackUri);

    if (success) {
      state = const AuthState(
        status: AuthStatus.authenticated,
        userId: 'trakt-user',
        userName: 'Trakt User',
      );
    } else {
      state = const AuthState(
        status: AuthStatus.error,
        errorMessage: 'Autenticação com Trakt cancelada ou falhou.',
      );
    }
  }

  /// Verifica e restaura a sessão Trakt persistida.
  ///
  /// Deve ser chamado no startup do app para restaurar sessões anteriores.
  Future<void> restoreTraktSession() async {
    final isAuth = await _traktAuth.isAuthenticated;

    if (isAuth) {
      state = const AuthState(
        status: AuthStatus.authenticated,
        userId: 'trakt-user',
        userName: 'Trakt User',
      );
    }
  }

  // --------------------------------------------------------------------------
  // Logout
  // --------------------------------------------------------------------------

  /// Realiza logout (local e Trakt).
  Future<void> signOut() async {
    await _repository.signOut();
    await _traktAuth.signOut();
    state = const AuthState.initial();
  }
}
