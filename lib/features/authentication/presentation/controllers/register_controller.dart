import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/validators/auth_validators.dart';
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
      clearErrorMessage: true,
    );
  }

  void emailChanged(String value) {
    state = state.copyWith(
      email: value,
      status: RegisterStatus.initial,
      clearErrorMessage: true,
    );
  }

  void passwordChanged(String value) {
    state = state.copyWith(
      password: value,
      status: RegisterStatus.initial,
      clearErrorMessage: true,
    );
  }

  void confirmPasswordChanged(String value) {
    state = state.copyWith(
      confirmPassword: value,
      status: RegisterStatus.initial,
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
    final nameError = AuthValidators.name(state.name);
    final emailError = AuthValidators.email(state.email);
    final passwordError = AuthValidators.password(state.password);
    final confirmPasswordError = AuthValidators.confirmPassword(
      state.confirmPassword,
      state.password,
    );

    if (nameError != null ||
        emailError != null ||
        passwordError != null ||
        confirmPasswordError != null) {
      state = state.copyWith(
        status: RegisterStatus.failure,
        errorMessage: 'Sila semak semula maklumat pendaftaran anda.',
      );
      return;
    }

    state = state.copyWith(
      status: RegisterStatus.loading,
      clearErrorMessage: true,
    );

    // Temporary mock registration.
    // This will later be replaced by AuthRepository and Supabase.
    await Future<void>.delayed(const Duration(milliseconds: 700));

    state = state.copyWith(
      status: RegisterStatus.success,
      clearErrorMessage: true,
    );
  }

  void reset() {
    state = const RegisterState();
  }
}
