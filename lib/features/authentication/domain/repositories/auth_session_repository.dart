import '../entities/auth_session.dart';

abstract interface class AuthSessionRepository {
  Future<AuthSession?> loadSession();

  Future<void> saveSession(AuthSession session);

  Future<void> clearSession();
}
