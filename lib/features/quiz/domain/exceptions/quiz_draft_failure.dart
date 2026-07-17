class QuizDraftFailure implements Exception {
  const QuizDraftFailure(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}
