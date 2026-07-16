class UserProgressFailure implements Exception {
  const UserProgressFailure(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}
