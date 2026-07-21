class AccountDeletionFailure implements Exception {
  const AccountDeletionFailure(this.message);

  final String message;

  @override
  String toString() {
    return message;
  }
}
