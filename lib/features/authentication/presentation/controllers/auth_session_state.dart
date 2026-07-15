import '../../domain/entities/auth_session.dart';

enum AuthSessionStatus { initial, loading, authenticated, unauthenticated }

class AuthSessionState {
  const AuthSessionState({
    this.status = AuthSessionStatus.initial,
    this.session = AuthSession.signedOut,
  });

  final AuthSessionStatus status;
  final AuthSession session;

  bool get isAuthenticated {
    return status == AuthSessionStatus.authenticated && session.isAuthenticated;
  }
}
