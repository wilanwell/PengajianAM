class TopicAnalyticsFailure implements Exception {
  const TopicAnalyticsFailure(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}
