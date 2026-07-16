import 'auth_session.dart';

class AuthRegistrationResult {
  const AuthRegistrationResult({
    required this.userId,
    required this.email,
    required this.session,
  });

  final String userId;
  final String email;
  final AuthSession? session;

  bool get requiresEmailConfirmation {
    return session == null;
  }

  bool get isSignedIn {
    return session?.isAuthenticated == true;
  }
}
