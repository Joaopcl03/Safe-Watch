import 'package:safe_watch/features/auth/models/auth_state.dart';

// ============================================================================
// Safe Watch — Auth Repository Interface
// ============================================================================
// Contrato abstrato para o repositório de autenticação.
// Permite trocar implementações (mock, Firebase, API custom)
// sem alterar o controller ou a UI.
// ============================================================================

/// Interface abstrata do repositório de autenticação.
///
/// Qualquer implementação (mock, Firebase Auth, API REST)
/// deve implementar esta interface.
abstract interface class AuthRepositoryInterface {
  /// Realiza login com email e senha.
  ///
  /// Retorna [AuthState] com status de sucesso ou erro.
  Future<AuthState> signInWithEmail({
    required String email,
    required String password,
  });

  /// Registra um novo usuário com email e senha.
  ///
  /// Retorna [AuthState] com status de sucesso ou erro.
  Future<AuthState> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  });

  /// Realiza logout do usuário atual.
  Future<void> signOut();

  /// Retorna o estado de autenticação atual.
  Future<AuthState> getCurrentAuthState();
}
