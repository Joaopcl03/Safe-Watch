import 'package:safe_watch/features/auth/models/auth_state.dart';
import 'package:safe_watch/features/auth/repositories/auth_repository_interface.dart';

// ============================================================================
// Safe Watch — Auth Repository (Mock)
// ============================================================================
// Implementação mockada do repositório de autenticação.
// TODO: Substituir por Firebase Auth ou API REST real.
// ============================================================================

/// Implementação mockada do [AuthRepositoryInterface].
///
/// Simula autenticação com delay para desenvolvimento.
/// Substitua por implementação real (Firebase, API, etc.).
class AuthRepository implements AuthRepositoryInterface {
  AuthState _currentState = const AuthState.initial();

  @override
  Future<AuthState> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // Simula delay de rede.
    await Future<void>.delayed(const Duration(seconds: 1));

    // Mock: aceita qualquer email/senha não-vazios.
    if (email.isNotEmpty && password.isNotEmpty) {
      _currentState = AuthState(
        status: AuthStatus.authenticated,
        userId: 'mock-user-id-001',
        userName: 'Usuário Safe Watch',
        userEmail: email,
      );
      return _currentState;
    }

    _currentState = const AuthState(
      status: AuthStatus.error,
      errorMessage: 'Email e senha são obrigatórios.',
    );
    return _currentState;
  }

  @override
  Future<AuthState> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 1));

    if (name.isNotEmpty && email.isNotEmpty && password.length >= 6) {
      _currentState = AuthState(
        status: AuthStatus.authenticated,
        userId: 'mock-user-id-${DateTime.now().millisecondsSinceEpoch}',
        userName: name,
        userEmail: email,
      );
      return _currentState;
    }

    _currentState = const AuthState(
      status: AuthStatus.error,
      errorMessage: 'Preencha todos os campos. Senha deve ter ao menos 6 caracteres.',
    );
    return _currentState;
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _currentState = const AuthState.initial();
  }

  @override
  Future<AuthState> getCurrentAuthState() async {
    return _currentState;
  }
}
