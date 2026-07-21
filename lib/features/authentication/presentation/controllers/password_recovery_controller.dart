import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/exceptions/authentication_failure.dart';
import 'auth_session_controller.dart';
import 'password_recovery_state.dart';

final passwordRecoveryControllerProvider =
    NotifierProvider<PasswordRecoveryController, PasswordRecoveryState>(
      PasswordRecoveryController.new,
    );

class PasswordRecoveryController extends Notifier<PasswordRecoveryState> {
  @override
  PasswordRecoveryState build() {
    return const PasswordRecoveryState();
  }

  void prepare({String initialEmail = ''}) {
    state = PasswordRecoveryState(email: initialEmail.trim());
  }

  void preparePasswordUpdate() {
    state = PasswordRecoveryState(email: state.email);
  }

  void emailChanged(String value) {
    state = state.copyWith(
      email: value,
      status: PasswordRecoveryStatus.initial,
      clearErrorMessage: true,
    );
  }

  void newPasswordChanged(String value) {
    state = state.copyWith(
      newPassword: value,
      status: PasswordRecoveryStatus.initial,
      clearErrorMessage: true,
    );
  }

  void confirmPasswordChanged(String value) {
    state = state.copyWith(
      confirmPassword: value,
      status: PasswordRecoveryStatus.initial,
      clearErrorMessage: true,
    );
  }

  void toggleNewPasswordVisibility() {
    state = state.copyWith(isNewPasswordVisible: !state.isNewPasswordVisible);
  }

  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(
      isConfirmPasswordVisible: !state.isConfirmPasswordVisible,
    );
  }

  Future<void> sendResetEmail() async {
    if (state.isBusy) {
      return;
    }

    final normalizedEmail = state.email.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      state = state.copyWith(
        status: PasswordRecoveryStatus.failure,
        errorMessage: 'Masukkan alamat e-mel anda.',
      );

      return;
    }

    state = state.copyWith(
      email: normalizedEmail,
      status: PasswordRecoveryStatus.sendingEmail,
      clearErrorMessage: true,
    );

    try {
      await ref
          .read(authSessionRepositoryProvider)
          .sendPasswordResetEmail(email: normalizedEmail);

      state = state.copyWith(
        status: PasswordRecoveryStatus.emailSent,
        clearErrorMessage: true,
      );
    } on AuthenticationFailure catch (error) {
      state = state.copyWith(
        status: PasswordRecoveryStatus.failure,
        errorMessage: error.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: PasswordRecoveryStatus.failure,
        errorMessage:
            'Permintaan reset kata laluan '
            'tidak dapat dihantar.',
      );
    }
  }

  Future<void> updatePassword() async {
    if (state.isBusy) {
      return;
    }

    if (state.newPassword.length < 8) {
      state = state.copyWith(
        status: PasswordRecoveryStatus.failure,
        errorMessage:
            'Kata laluan baharu mestilah '
            'sekurang-kurangnya 8 aksara.',
      );

      return;
    }

    if (state.newPassword != state.confirmPassword) {
      state = state.copyWith(
        status: PasswordRecoveryStatus.failure,
        errorMessage:
            'Pengesahan kata laluan tidak '
            'sepadan.',
      );

      return;
    }

    state = state.copyWith(
      status: PasswordRecoveryStatus.updatingPassword,
      clearErrorMessage: true,
    );

    try {
      await ref
          .read(authSessionRepositoryProvider)
          .updatePassword(newPassword: state.newPassword);

      state = state.copyWith(
        newPassword: '',
        confirmPassword: '',
        status: PasswordRecoveryStatus.passwordUpdated,
        clearErrorMessage: true,
      );
    } on AuthenticationFailure catch (error) {
      state = state.copyWith(
        status: PasswordRecoveryStatus.failure,
        errorMessage: error.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: PasswordRecoveryStatus.failure,
        errorMessage:
            'Kata laluan tidak dapat '
            'dikemas kini.',
      );
    }
  }

  void reset() {
    state = const PasswordRecoveryState();
  }
}
