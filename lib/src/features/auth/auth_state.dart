enum AuthStatus { loading, unauthenticated, authenticated }

class AuthState {
  const AuthState._({required this.status, this.token});

  factory AuthState.loading() => const AuthState._(status: AuthStatus.loading);

  factory AuthState.unauthenticated() =>
      const AuthState._(status: AuthStatus.unauthenticated);

  factory AuthState.authenticated(String token) =>
      AuthState._(status: AuthStatus.authenticated, token: token);

  final AuthStatus status;
  final String? token;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && token != null;
}
