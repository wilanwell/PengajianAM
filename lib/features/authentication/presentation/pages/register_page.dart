import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/validators/auth_validators.dart';
import '../controllers/register_controller.dart';
import '../controllers/register_state.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  void _submit() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    ref.read(registerControllerProvider.notifier).register();
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerControllerProvider);

    final registerController = ref.read(registerControllerProvider.notifier);

    final textTheme = Theme.of(context).textTheme;

    ref.listen<RegisterState>(registerControllerProvider, (previous, next) {
      if (previous?.status != RegisterStatus.success &&
          next.status == RegisterStatus.success) {
        context.goNamed(RouteNames.home);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akaun')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: const BoxDecoration(
                            color: AppColors.softBlue,
                            borderRadius: AppRadius.extraLarge,
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 46,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Cipta Akaun',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Daftar untuk menyimpan kemajuan, markah '
                        'dan kedudukan anda.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryText,
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
                              label: 'Nama',
                              hint: 'Masukkan nama anda',
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              enabled: !registerState.isLoading,
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                              ),
                              validator: AuthValidators.name,
                              onChanged: registerController.nameChanged,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              label: 'E-mel',
                              hint: 'Masukkan e-mel anda',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              enabled: !registerState.isLoading,
                              prefixIcon: const Icon(Icons.email_outlined),
                              validator: AuthValidators.email,
                              onChanged: registerController.emailChanged,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              label: 'Kata laluan',
                              hint: 'Minimum 6 aksara',
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.newPassword],
                              enabled: !registerState.isLoading,
                              obscureText: !registerState.isPasswordVisible,
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                tooltip: registerState.isPasswordVisible
                                    ? 'Sembunyikan kata laluan'
                                    : 'Paparkan kata laluan',
                                onPressed: registerState.isLoading
                                    ? null
                                    : registerController
                                          .togglePasswordVisibility,
                                icon: Icon(
                                  registerState.isPasswordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                              validator: AuthValidators.password,
                              onChanged: registerController.passwordChanged,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              label: 'Sahkan kata laluan',
                              hint: 'Masukkan semula kata laluan',
                              textInputAction: TextInputAction.done,
                              enabled: !registerState.isLoading,
                              obscureText:
                                  !registerState.isConfirmPasswordVisible,
                              prefixIcon: const Icon(Icons.lock_reset_rounded),
                              suffixIcon: IconButton(
                                tooltip: registerState.isConfirmPasswordVisible
                                    ? 'Sembunyikan kata laluan'
                                    : 'Paparkan kata laluan',
                                onPressed: registerState.isLoading
                                    ? null
                                    : registerController
                                          .toggleConfirmPasswordVisibility,
                                icon: Icon(
                                  registerState.isConfirmPasswordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                              validator: (value) {
                                return AuthValidators.confirmPassword(
                                  value,
                                  registerState.password,
                                );
                              },
                              onChanged:
                                  registerController.confirmPasswordChanged,
                              onFieldSubmitted: (_) {
                                if (!registerState.isLoading) {
                                  _submit();
                                }
                              },
                            ),
                            if (registerState.status ==
                                    RegisterStatus.failure &&
                                registerState.errorMessage != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              Container(
                                padding: AppSpacing.cardPadding,
                                decoration: const BoxDecoration(
                                  color: AppColors.errorBackground,
                                  borderRadius: AppRadius.medium,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: AppColors.error,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        registerState.errorMessage!,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            FilledButton(
                              onPressed: registerState.isLoading
                                  ? null
                                  : _submit,
                              child: registerState.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.textOnPrimary,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.person_add_alt_1_rounded),
                                        SizedBox(width: AppSpacing.xs),
                                        Text('Daftar Akaun'),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Wrap digunakan supaya kandungan tidak overflow
                      // pada skrin sempit atau apabila saiz teks dibesarkan.
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.xxs,
                        runSpacing: AppSpacing.xxs,
                        children: [
                          Text(
                            'Sudah mempunyai akaun?',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                          TextButton(
                            onPressed: registerState.isLoading
                                ? null
                                : () {
                                    registerController.reset();

                                    context.goNamed(RouteNames.login);
                                  },
                            child: const Text('Log Masuk'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
