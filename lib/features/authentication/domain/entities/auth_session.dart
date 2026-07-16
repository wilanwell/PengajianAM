class AuthSession {
  const AuthSession({
    required this.isAuthenticated,
    this.userId,
    this.email,
    this.signedInAt,
  });

  static const AuthSession signedOut = AuthSession(isAuthenticated: false);

  final bool isAuthenticated;
  final String? userId;
  final String? email;
  final DateTime? signedInAt;

  bool get hasValidUser {
    return isAuthenticated && userId != null && userId!.trim().isNotEmpty;
  }
}
