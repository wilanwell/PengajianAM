import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/validators/auth_validators.dart';
import '../controllers/password_recovery_controller.dart';
import '../controllers/password_recovery_state.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({this.initialEmail = '', super.key});

  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordPage> createState() {
    return _ForgotPasswordPageState();
  }
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();

    final initialEmail = widget.initialEmail.trim();

    _emailController = TextEditingController(text: initialEmail);

    Future<void>.microtask(() {
      ref
          .read(passwordRecoveryControllerProvider.notifier)
          .prepare(initialEmail: initialEmail);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    await ref
        .read(passwordRecoveryControllerProvider.notifier)
        .sendResetEmail();
  }

  void _returnToLogin() {
    ref.read(passwordRecoveryControllerProvider.notifier).reset();

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final recoveryState = ref.watch(passwordRecoveryControllerProvider);

    final controller = ref.read(passwordRecoveryControllerProvider.notifier);

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Kata Laluan')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: recoveryState.isEmailSent
                  ? _EmailSentContent(
                      email: recoveryState.email,
                      onReturnToLogin: _returnToLogin,
                    )
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
                                Icons.lock_reset_rounded,
                                size: 50,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Reset Kata Laluan',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Masukkan e-mel yang '
                            'digunakan untuk akaun '
                            'anda. Kami akan '
                            'menghantar pautan '
                            'pemulihan kata laluan.',
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
                                  label: 'E-mel',
                                  hint: 'Masukkan e-mel anda',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.email],
                                  enabled: !recoveryState.isBusy,
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  validator: AuthValidators.email,
                                  onChanged: controller.emailChanged,
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
                                  icon: recoveryState.isSendingEmail
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.textOnPrimary,
                                          ),
                                        )
                                      : const Icon(Icons.send_outlined),
                                  label: Text(
                                    recoveryState.isSendingEmail
                                        ? 'Menghantar...'
                                        : 'Hantar Pautan Reset',
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                TextButton.icon(
                                  onPressed: recoveryState.isBusy
                                      ? null
                                      : _returnToLogin,
                                  icon: const Icon(Icons.arrow_back_rounded),
                                  label: const Text('Kembali ke Log Masuk'),
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

class _EmailSentContent extends StatelessWidget {
  const _EmailSentContent({required this.email, required this.onReturnToLogin});

  final String email;
  final VoidCallback onReturnToLogin;

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
              Icons.mark_email_read_outlined,
              size: 52,
              color: AppColors.success,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Semak E-mel Anda',
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Jika akaun berdaftar menggunakan '
          'e-mel berikut, pautan reset kata '
          'laluan akan dihantar:',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.secondaryText,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: AppSpacing.cardPadding,
          decoration: const BoxDecoration(
            color: AppColors.softBlue,
            borderRadius: AppRadius.medium,
          ),
          child: Text(
            email,
            textAlign: TextAlign.center,
            style: textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Semak juga folder Spam atau Junk. '
          'Pautan tersebut akan membuka '
          'aplikasi ini untuk menetapkan '
          'kata laluan baharu.',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.secondaryText,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: onReturnToLogin,
          icon: const Icon(Icons.login_rounded),
          label: const Text('Kembali ke Log Masuk'),
        ),
      ],
    );
  }
}
