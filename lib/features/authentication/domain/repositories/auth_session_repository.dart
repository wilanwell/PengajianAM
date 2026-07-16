import '../entities/auth_registration_result.dart';
import '../entities/auth_session.dart';

abstract interface class AuthSessionRepository {
  AuthSession? get currentSession;

  Stream<AuthSession?> get authStateChanges;

  Future<AuthSession> signInWithPassword({
    required String email,
    required String password,
  });

  Future<AuthRegistrationResult> signUp({
    required String displayName,
    required String email,
    required String password,
  });

  Future<void> signOut();
}
