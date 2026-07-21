enum AccountDeletionStatus { initial, deleting, success, failure }

class AccountDeletionState {
  const AccountDeletionState({
    this.status = AccountDeletionStatus.initial,
    this.errorMessage,
  });

  final AccountDeletionStatus status;
  final String? errorMessage;

  bool get isDeleting {
    return status == AccountDeletionStatus.deleting;
  }

  bool get isSuccess {
    return status == AccountDeletionStatus.success;
  }

  bool get hasFailure {
    return status == AccountDeletionStatus.failure;
  }

  AccountDeletionState copyWith({
    AccountDeletionStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AccountDeletionState(
      status: status ?? this.status,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
