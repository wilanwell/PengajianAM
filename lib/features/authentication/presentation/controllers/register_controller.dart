import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/exceptions/authentication_failure.dart';
import 'auth_session_controller.dart';
import 'register_state.dart';

final registerControllerProvider =
    NotifierProvider<RegisterController, RegisterState>(RegisterController.new);

class RegisterController extends Notifier<RegisterState> {
  @override
  RegisterState build() {
    return const RegisterState();
  }

  void nameChanged(String value) {
    state = state.copyWith(
      name: value,
      status: RegisterStatus.initial,
      requiresEmailConfirmation: false,
      clearErrorMessage: true,
    );
  }

  void emailChanged(String value) {
    state = state.copyWith(
      email: value,
      status: RegisterStatus.initial,
      requiresEmailConfirmation: false,
      clearErrorMessage: true,
    );
  }

  void passwordChanged(String value) {
    state = state.copyWith(
      password: value,
      status: RegisterStatus.initial,
      requiresEmailConfirmation: false,
      clearErrorMessage: true,
    );
  }

  void confirmPasswordChanged(String value) {
    state = state.copyWith(
      confirmPassword: value,
      status: RegisterStatus.initial,
      requiresEmailConfirmation: false,
      clearErrorMessage: true,
    );
  }

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(
      isConfirmPasswordVisible: !state.isConfirmPasswordVisible,
    );
  }

  Future<void> register() async {
    if (state.isLoading) {
      return;
    }

    state = state.copyWith(
      status: RegisterStatus.loading,
      requiresEmailConfirmation: false,
      clearErrorMessage: true,
    );

    try {
      final result = await ref
          .read(authSessionControllerProvider.notifier)
          .signUp(
            displayName: state.name.trim(),
            email: state.email.trim(),
            password: state.password,
          );

      state = state.copyWith(
        status: RegisterStatus.success,
        requiresEmailConfirmation: result.requiresEmailConfirmation,
        clearErrorMessage: true,
      );
    } on AuthenticationFailure catch (error) {
      state = state.copyWith(
        status: RegisterStatus.failure,
        errorMessage: error.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: RegisterStatus.failure,
        errorMessage: 'Pendaftaran tidak dapat diselesaikan.',
      );
    }
  }

  void reset() {
    state = const RegisterState();
  }
}
