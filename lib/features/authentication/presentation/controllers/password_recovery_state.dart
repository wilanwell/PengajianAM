enum PasswordRecoveryStatus {
  initial,
  sendingEmail,
  emailSent,
  updatingPassword,
  passwordUpdated,
  failure,
}

class PasswordRecoveryState {
  const PasswordRecoveryState({
    this.email = '',
    this.newPassword = '',
    this.confirmPassword = '',
    this.isNewPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
    this.status = PasswordRecoveryStatus.initial,
    this.errorMessage,
  });

  final String email;
  final String newPassword;
  final String confirmPassword;

  final bool isNewPasswordVisible;
  final bool isConfirmPasswordVisible;

  final PasswordRecoveryStatus status;
  final String? errorMessage;

  bool get isSendingEmail {
    return status == PasswordRecoveryStatus.sendingEmail;
  }

  bool get isUpdatingPassword {
    return status == PasswordRecoveryStatus.updatingPassword;
  }

  bool get isBusy {
    return isSendingEmail || isUpdatingPassword;
  }

  bool get isEmailSent {
    return status == PasswordRecoveryStatus.emailSent;
  }

  bool get isPasswordUpdated {
    return status == PasswordRecoveryStatus.passwordUpdated;
  }

  PasswordRecoveryState copyWith({
    String? email,
    String? newPassword,
    String? confirmPassword,
    bool? isNewPasswordVisible,
    bool? isConfirmPasswordVisible,
    PasswordRecoveryStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return PasswordRecoveryState(
      email: email ?? this.email,
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isNewPasswordVisible: isNewPasswordVisible ?? this.isNewPasswordVisible,
      isConfirmPasswordVisible:
          isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
      status: status ?? this.status,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
