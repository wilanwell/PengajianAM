class TopicsFailure implements Exception {
  const TopicsFailure(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}
