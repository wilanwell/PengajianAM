import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/validators/auth_validators.dart';
import '../controllers/login_controller.dart';
import '../controllers/login_state.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() {
    return _LoginPageState();
  }
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  bool _isCompletingLogin = false;

  void _submit() {
    FocusScope.of(context).unfocus();

    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    ref.read(loginControllerProvider.notifier).login();
  }

  Future<void> _completeLogin() async {
    if (_isCompletingLogin) {
      return;
    }

    _isCompletingLogin = true;

    try {
      if (!mounted) {
        return;
      }

      context.goNamed(RouteNames.home);
    } finally {
      _isCompletingLogin = false;
    }
  }

  void _showTemporaryMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);

    final loginController = ref.read(loginControllerProvider.notifier);

    final textTheme = Theme.of(context).textTheme;

    ref.listen<LoginState>(loginControllerProvider, (previous, next) {
      final becameSuccessful =
          previous?.status != LoginStatus.success &&
          next.status == LoginStatus.success;

      if (becameSuccessful) {
        unawaited(_completeLogin());
      }
    });

    return Scaffold(
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
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(
                            color: AppColors.softBlue,
                            borderRadius: AppRadius.extraLarge,
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            size: 52,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Pengajian AM STPM Objektif',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Belajar dengan fokus, skor dengan yakin.',
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
                            Text(
                              'Selamat Datang',
                              style: textTheme.headlineSmall,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Log masuk untuk meneruskan '
                              'pembelajaran anda.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AppTextField(
                              label: 'E-mel',
                              hint: 'Masukkan e-mel anda',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              enabled:
                                  !loginState.isLoading && !_isCompletingLogin,
                              prefixIcon: const Icon(Icons.email_outlined),
                              validator: AuthValidators.email,
                              onChanged: loginController.emailChanged,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              label: 'Kata laluan',
                              hint: 'Masukkan kata laluan anda',
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              enabled:
                                  !loginState.isLoading && !_isCompletingLogin,
                              obscureText: !loginState.isPasswordVisible,
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                tooltip: loginState.isPasswordVisible
                                    ? 'Sembunyikan kata laluan'
                                    : 'Paparkan kata laluan',
                                onPressed:
                                    loginState.isLoading || _isCompletingLogin
                                    ? null
                                    : loginController.togglePasswordVisibility,
                                icon: Icon(
                                  loginState.isPasswordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                              validator: AuthValidators.password,
                              onChanged: loginController.passwordChanged,
                              onFieldSubmitted: (_) {
                                if (!loginState.isLoading &&
                                    !_isCompletingLogin) {
                                  _submit();
                                }
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed:
                                    loginState.isLoading || _isCompletingLogin
                                    ? null
                                    : () {
                                        _showTemporaryMessage(
                                          'Fungsi lupa kata laluan '
                                          'akan dibina kemudian.',
                                        );
                                      },
                                child: const Text('Lupa kata laluan?'),
                              ),
                            ),
                            if (loginState.status == LoginStatus.failure &&
                                loginState.errorMessage != null) ...[
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
                                        loginState.errorMessage!,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            FilledButton(
                              onPressed:
                                  loginState.isLoading || _isCompletingLogin
                                  ? null
                                  : _submit,
                              child: loginState.isLoading || _isCompletingLogin
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
                                        Icon(Icons.login_rounded),
                                        SizedBox(width: AppSpacing.xs),
                                        Text('Log Masuk'),
                                      ],
                                    ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            OutlinedButton.icon(
                              onPressed:
                                  loginState.isLoading || _isCompletingLogin
                                  ? null
                                  : () {
                                      loginController.reset();

                                      context.pushNamed(RouteNames.register);
                                    },
                              icon: const Icon(Icons.person_add_alt_1_outlined),
                              label: const Text('Daftar Akaun'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Dengan meneruskan, anda bersetuju '
                        'dengan Terma Penggunaan dan '
                        'Dasar Privasi.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.secondaryText,
                        ),
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
