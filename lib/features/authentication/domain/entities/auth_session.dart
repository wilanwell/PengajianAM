class AuthSession {
  const AuthSession({required this.isAuthenticated, this.signedInAt});

  static const int schemaVersion = 1;

  static const AuthSession signedOut = AuthSession(isAuthenticated: false);

  final bool isAuthenticated;
  final DateTime? signedInAt;

  Map<String, Object?> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'isAuthenticated': isAuthenticated,
      'signedInAt': signedInAt?.toIso8601String(),
    };
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    final authenticatedValue = json['isAuthenticated'];

    if (version is! num || version.toInt() != schemaVersion) {
      throw const FormatException('Unsupported authentication session schema.');
    }

    if (authenticatedValue is! bool) {
      throw const FormatException('Invalid authentication status.');
    }

    final rawSignedInAt = json['signedInAt'];

    DateTime? signedInAt;

    if (rawSignedInAt != null) {
      if (rawSignedInAt is! String) {
        throw const FormatException('Invalid authentication session date.');
      }

      signedInAt = DateTime.tryParse(rawSignedInAt);

      if (signedInAt == null) {
        throw const FormatException('Invalid authentication session date.');
      }
    }

    return AuthSession(
      isAuthenticated: authenticatedValue,
      signedInAt: signedInAt,
    );
  }
}
