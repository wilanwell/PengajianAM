class LeaderboardPreferenceFailure implements Exception {
  const LeaderboardPreferenceFailure(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}
