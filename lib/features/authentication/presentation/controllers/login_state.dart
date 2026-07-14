enum LoginStatus { initial, loading, success, failure }

class LoginState {
  const LoginState({
    this.email = '',
    this.password = '',
    this.isPasswordVisible = false,
    this.status = LoginStatus.initial,
    this.errorMessage,
  });

  final String email;
  final String password;
  final bool isPasswordVisible;
  final LoginStatus status;
  final String? errorMessage;

  bool get isLoading => status == LoginStatus.loading;

  LoginState copyWith({
    String? email,
    String? password,
    bool? isPasswordVisible,
    LoginStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      status: status ?? this.status,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
