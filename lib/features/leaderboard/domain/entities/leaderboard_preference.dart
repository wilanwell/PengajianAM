class LeaderboardPreference {
  const LeaderboardPreference({
    required this.isOptedIn,
    required this.requiredConsentVersion,
    required this.serverTime,
    this.consentAt,
    this.consentVersion,
  });

  static const String fallbackConsentVersion = '1.0';

  /// True apabila pengguna memilih untuk
  /// muncul dalam leaderboard.
  final bool isOptedIn;

  /// Masa consent diberikan.
  ///
  /// Nilai ini null apabila pengguna opt-out.
  final DateTime? consentAt;

  /// Versi privacy disclosure yang telah
  /// dipersetujui oleh pengguna.
  ///
  /// Nilai ini null apabila pengguna opt-out.
  final String? consentVersion;

  /// Versi consent yang diperlukan oleh server.
  final String requiredConsentVersion;

  /// Masa server ketika preference diperoleh.
  final DateTime serverTime;

  /// Menentukan sama ada consent pengguna
  /// masih sepadan dengan versi yang diperlukan.
  bool get hasCurrentConsent {
    return isOptedIn &&
        consentAt != null &&
        consentVersion != null &&
        consentVersion == requiredConsentVersion;
  }

  LeaderboardPreference copyWith({
    bool? isOptedIn,
    DateTime? consentAt,
    String? consentVersion,
    String? requiredConsentVersion,
    DateTime? serverTime,
    bool clearConsentAt = false,
    bool clearConsentVersion = false,
  }) {
    return LeaderboardPreference(
      isOptedIn: isOptedIn ?? this.isOptedIn,
      consentAt: clearConsentAt ? null : consentAt ?? this.consentAt,
      consentVersion: clearConsentVersion
          ? null
          : consentVersion ?? this.consentVersion,
      requiredConsentVersion:
          requiredConsentVersion ?? this.requiredConsentVersion,
      serverTime: serverTime ?? this.serverTime,
    );
  }
}
