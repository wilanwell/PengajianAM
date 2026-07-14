enum RegisterStatus { initial, loading, success, failure }

class RegisterState {
  const RegisterState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.isPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
    this.status = RegisterStatus.initial,
    this.errorMessage,
  });

  final String name;
  final String email;
  final String password;
  final String confirmPassword;
  final bool isPasswordVisible;
  final bool isConfirmPasswordVisible;
  final RegisterStatus status;
  final String? errorMessage;

  bool get isLoading => status == RegisterStatus.loading;

  RegisterState copyWith({
    String? name,
    String? email,
    String? password,
    String? confirmPassword,
    bool? isPasswordVisible,
    bool? isConfirmPasswordVisible,
    RegisterStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return RegisterState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isConfirmPasswordVisible:
          isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
      status: status ?? this.status,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
