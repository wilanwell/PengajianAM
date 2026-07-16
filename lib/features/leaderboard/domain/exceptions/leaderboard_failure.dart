class LeaderboardFailure implements Exception {
  const LeaderboardFailure(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}
