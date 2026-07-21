import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../controllers/password_recovery_controller.dart';
import '../controllers/password_recovery_state.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() {
    return _ResetPasswordPageState();
  }
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _newPasswordController;

  late final TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();

    _newPasswordController = TextEditingController();

    _confirmPasswordController = TextEditingController();

    Future<void>.microtask(() {
      ref
          .read(passwordRecoveryControllerProvider.notifier)
          .preparePasswordUpdate();
    });
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  String? _validateNewPassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Masukkan kata laluan baharu.';
    }

    if (password.length < 8) {
      return 'Kata laluan mestilah '
          'sekurang-kurangnya 8 aksara.';
    }

    return null;
  }

  String? _validateConfirmation(String? value) {
    final confirmation = value ?? '';

    if (confirmation.isEmpty) {
      return 'Sahkan kata laluan baharu.';
    }

    if (confirmation != _newPasswordController.text) {
      return 'Pengesahan kata laluan '
          'tidak sepadan.';
    }

    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    await ref
        .read(passwordRecoveryControllerProvider.notifier)
        .updatePassword();
  }

  void _continueToApplication() {
    ref.read(passwordRecoveryControllerProvider.notifier).reset();

    context.goNamed(RouteNames.home);
  }

  void _requestNewLink(String email) {
    ref.read(passwordRecoveryControllerProvider.notifier).reset();

    context.goNamed(
      RouteNames.forgotPassword,
      queryParameters: {if (email.trim().isNotEmpty) 'email': email.trim()},
    );
  }

  @override
  Widget build(BuildContext context) {
    final recoveryState = ref.watch(passwordRecoveryControllerProvider);

    final controller = ref.read(passwordRecoveryControllerProvider.notifier);

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Kata Laluan Baharu'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: recoveryState.isPasswordUpdated
                  ? _PasswordUpdatedContent(onContinue: _continueToApplication)
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            child: Container(
                              width: 92,
                              height: 92,
                              decoration: const BoxDecoration(
                                color: AppColors.softBlue,
                                borderRadius: AppRadius.extraLarge,
                              ),
                              child: const Icon(
                                Icons.password_rounded,
                                size: 50,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Tetapkan Kata Laluan',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Masukkan kata laluan '
                            'baharu untuk akaun anda.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.secondaryText,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Container(
                            padding: AppSpacing.largeCardPadding,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: AppRadius.extraLarge,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppTextField(
                                  label: 'Kata laluan baharu',
                                  hint: 'Sekurang-kurangnya 8 aksara',
                                  controller: _newPasswordController,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  obscureText:
                                      !recoveryState.isNewPasswordVisible,
                                  enabled: !recoveryState.isBusy,
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    tooltip: recoveryState.isNewPasswordVisible
                                        ? 'Sembunyikan kata laluan'
                                        : 'Paparkan kata laluan',
                                    onPressed: recoveryState.isBusy
                                        ? null
                                        : controller
                                              .toggleNewPasswordVisibility,
                                    icon: Icon(
                                      recoveryState.isNewPasswordVisible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                  validator: _validateNewPassword,
                                  onChanged: controller.newPasswordChanged,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppTextField(
                                  label: 'Sahkan kata laluan',
                                  hint: 'Masukkan semula kata laluan',
                                  controller: _confirmPasswordController,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  obscureText:
                                      !recoveryState.isConfirmPasswordVisible,
                                  enabled: !recoveryState.isBusy,
                                  prefixIcon: const Icon(
                                    Icons.verified_user_outlined,
                                  ),
                                  suffixIcon: IconButton(
                                    tooltip:
                                        recoveryState.isConfirmPasswordVisible
                                        ? 'Sembunyikan kata laluan'
                                        : 'Paparkan kata laluan',
                                    onPressed: recoveryState.isBusy
                                        ? null
                                        : controller
                                              .toggleConfirmPasswordVisibility,
                                    icon: Icon(
                                      recoveryState.isConfirmPasswordVisible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                  validator: _validateConfirmation,
                                  onChanged: controller.confirmPasswordChanged,
                                  onFieldSubmitted: (_) {
                                    if (!recoveryState.isBusy) {
                                      _submit();
                                    }
                                  },
                                ),
                                if (recoveryState.status ==
                                        PasswordRecoveryStatus.failure &&
                                    recoveryState.errorMessage != null) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  Container(
                                    padding: AppSpacing.cardPadding,
                                    decoration: const BoxDecoration(
                                      color: AppColors.errorBackground,
                                      borderRadius: AppRadius.medium,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          color: AppColors.error,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Text(
                                            recoveryState.errorMessage!,
                                            style: textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: AppColors.error,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.lg),
                                FilledButton.icon(
                                  onPressed: recoveryState.isBusy
                                      ? null
                                      : _submit,
                                  icon: recoveryState.isUpdatingPassword
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.textOnPrimary,
                                          ),
                                        )
                                      : const Icon(Icons.save_rounded),
                                  label: Text(
                                    recoveryState.isUpdatingPassword
                                        ? 'Menyimpan...'
                                        : 'Simpan Kata Laluan',
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                TextButton(
                                  onPressed: recoveryState.isBusy
                                      ? null
                                      : () {
                                          _requestNewLink(recoveryState.email);
                                        },
                                  child: const Text(
                                    'Minta Pautan Reset Baharu',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordUpdatedContent extends StatelessWidget {
  const _PasswordUpdatedContent({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          child: Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: AppColors.successBackground,
              borderRadius: AppRadius.extraLarge,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 54,
              color: AppColors.success,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Kata Laluan Dikemas Kini',
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Kata laluan baharu anda telah '
          'berjaya disimpan.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.secondaryText,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: onContinue,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('Teruskan ke Aplikasi'),
        ),
      ],
    );
  }
}
