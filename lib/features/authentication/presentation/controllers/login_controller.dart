import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/validators/auth_validators.dart';
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
    final emailError = AuthValidators.email(state.email);
    final passwordError = AuthValidators.password(state.password);

    if (emailError != null || passwordError != null) {
      state = state.copyWith(
        status: LoginStatus.failure,
        errorMessage: 'Sila semak semula maklumat log masuk anda.',
      );
      return;
    }

    state = state.copyWith(
      status: LoginStatus.loading,
      clearErrorMessage: true,
    );

    // Temporary mock authentication.
    // This will later be replaced by AuthRepository and Supabase.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    state = state.copyWith(
      status: LoginStatus.success,
      clearErrorMessage: true,
    );
  }

  void reset() {
    state = const LoginState();
  }
}
