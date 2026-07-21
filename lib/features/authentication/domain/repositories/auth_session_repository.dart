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

  /// Menghantar e-mel pemulihan kata laluan.
  ///
  /// Pautan dalam e-mel akan membuka semula
  /// aplikasi melalui Android deep link.
  Future<void> sendPasswordResetEmail({required String email});

  /// Menetapkan kata laluan baharu selepas
  /// recovery session diwujudkan oleh Supabase.
  Future<void> updatePassword({required String newPassword});

  Future<void> signOut();
}
