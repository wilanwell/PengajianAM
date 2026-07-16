import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/exceptions/authentication_failure.dart';
import 'auth_session_controller.dart';
import 'login_state.dart';

final loginControllerProvider = NotifierProvider<LoginController, LoginState>(
  LoginController.new,
);

class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() {
    return const LoginState();
  }

  void emailChanged(String value) {
    state = state.copyWith(
      email: value,
      status: LoginStatus.initial,
      clearErrorMessage: true,
    );
  }

  void passwordChanged(String value) {
    state = state.copyWith(
      password: value,
      status: LoginStatus.initial,
      clearErrorMessage: true,
    );
  }

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  Future<void> login() async {
    if (state.isLoading) {
      return;
    }

    state = state.copyWith(
      status: LoginStatus.loading,
      clearErrorMessage: true,
    );

    try {
      await ref
          .read(authSessionControllerProvider.notifier)
          .signInWithPassword(
            email: state.email.trim(),
            password: state.password,
          );

      state = state.copyWith(
        status: LoginStatus.success,
        clearErrorMessage: true,
      );
    } on AuthenticationFailure catch (error) {
      state = state.copyWith(
        status: LoginStatus.failure,
        errorMessage: error.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: LoginStatus.failure,
        errorMessage: 'Log masuk tidak dapat diselesaikan.',
      );
    }
  }

  void reset() {
    state = const LoginState();
  }
}
