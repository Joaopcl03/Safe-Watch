// ============================================================================
// Safe Watch — Auth State Model
// ============================================================================
// Modelo de estado de autenticação.
// Fluxo: LoginTemplate → AuthController → AuthRepository → AuthState
// ============================================================================

/// Representa o estado de autenticação do usuário.
///
/// O [AuthController] gerencia transições entre os estados
/// e o [LoginTemplate] reage a mudanças via `ref.watch`.
enum AuthStatus {
  /// Usuário não autenticado.
  unauthenticated,

  /// Processo de autenticação em andamento.
  authenticating,

  /// Usuário autenticado com sucesso.
  authenticated,

  /// Falha na autenticação.
  error,
}

/// Modelo imutável do estado de autenticação.
class AuthState {
  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.userId,
    this.userName,
    this.userEmail,
    this.errorMessage,
  });

  /// Estado inicial — usuário não autenticado.
  const AuthState.initial()
      : status = AuthStatus.unauthenticated,
        userId = null,
        userName = null,
        userEmail = null,
        errorMessage = null;

  /// Status atual da autenticação.
  final AuthStatus status;

  /// ID do usuário autenticado.
  final String? userId;

  /// Nome do usuário autenticado.
  final String? userName;

  /// Email do usuário autenticado.
  final String? userEmail;

  /// Mensagem de erro, se houver.
  final String? errorMessage;

  /// Se o usuário está autenticado.
  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Se está em processo de autenticação.
  bool get isLoading => status == AuthStatus.authenticating;

  /// Cria uma cópia do estado com valores alterados.
  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? userName,
    String? userEmail,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
