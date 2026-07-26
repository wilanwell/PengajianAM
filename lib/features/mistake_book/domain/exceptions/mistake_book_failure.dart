class MistakeBookFailure implements Exception {
  const MistakeBookFailure(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}
