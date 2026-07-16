class QuizHistoryFailure implements Exception {
  const QuizHistoryFailure(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}
