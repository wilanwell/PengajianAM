import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../analytics/presentation/controllers/topic_analytics_controller.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../leaderboard/presentation/controllers/leaderboard_controller.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../progress/presentation/controllers/user_progress_controller.dart';
import '../../../quiz/presentation/controllers/quiz_history_controller.dart';
import '../../../quiz/presentation/controllers/quiz_session_controller.dart';
import '../../../quiz/presentation/controllers/quiz_setup_controller.dart';
import '../../../settings/presentation/controllers/app_settings_controller.dart';
import '../../../topics/presentation/controllers/topics_controller.dart';
import '../controllers/account_deletion_controller.dart';
import '../controllers/account_deletion_state.dart';
import '../controllers/auth_session_controller.dart';
import '../controllers/login_controller.dart';
import '../controllers/password_recovery_controller.dart';

class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() {
    return _DeleteAccountPageState();
  }
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  static const String _requiredPhrase = 'PADAM';

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _passwordController;

  late final TextEditingController _confirmationController;

  bool _isPasswordVisible = false;
  bool _isFinalizingDeletion = false;
  bool _deletionCompleted = false;

  @override
  void initState() {
    super.initState();

    _passwordController = TextEditingController();

    _confirmationController = TextEditingController();

    Future<void>.microtask(() {
      ref.read(accountDeletionControllerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();

    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Masukkan kata laluan semasa.';
    }

    return null;
  }

  String? _validateConfirmation(String? value) {
    final normalizedValue = value?.trim().toUpperCase() ?? '';

    if (normalizedValue.isEmpty) {
      return 'Taip PADAM untuk meneruskan.';
    }

    if (normalizedValue != _requiredPhrase) {
      return 'Frasa pengesahan mestilah PADAM.';
    }

    return null;
  }

  Future<void> _requestDeletion() async {
    FocusScope.of(context).unfocus();

    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            size: 48,
            color: AppColors.error,
          ),
          title: const Text('Padam Akaun Secara Kekal?'),
          content: const Text(
            'Tindakan ini akan memadam akaun '
            'dan data berkaitan secara kekal, '
            'termasuk:\n\n'
            '\u2022 Profil dan nama paparan\n'
            '\u2022 XP dan progress pembelajaran\n'
            '\u2022 Sejarah serta analitik kuiz\n'
            '\u2022 Ranking dan pencapaian\n'
            '\u2022 Sesi serta draft kuiz\n\n'
            'Tindakan ini tidak boleh dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Batal'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text('Ya, Padam Akaun'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    final controller = ref.read(accountDeletionControllerProvider.notifier);

    final deleted = await controller.deleteAccount(
      currentPassword: _passwordController.text,
    );

    if (!mounted || !deleted) {
      return;
    }

    await _finalizeSuccessfulDeletion();
  }

  Future<void> _finalizeSuccessfulDeletion() async {
    if (_isFinalizingDeletion) {
      return;
    }

    setState(() {
      _isFinalizingDeletion = true;
    });

    /*
     * Akaun sudah dipadam pada server.
     *
     * Kegagalan membersihkan satu data tempatan
     * tidak boleh menukar keputusan penghapusan
     * akaun kepada gagal.
     */
    try {
      await ref.read(quizSessionControllerProvider.notifier).discardDraft();
    } catch (_) {
      // Teruskan pembersihan yang lain.
    }

    try {
      await ref.read(appSettingsControllerProvider.notifier).resetToDefaults();
    } catch (_) {
      // Tetapan tempatan boleh dibina semula.
    }

    ref.read(quizHistoryControllerProvider.notifier).reset();

    ref.read(topicAnalyticsControllerProvider.notifier).reset();

    ref.read(quizSetupControllerProvider.notifier).reset();

    ref.read(homeControllerProvider.notifier).reset();

    ref.read(profileControllerProvider.notifier).reset();

    ref.read(leaderboardControllerProvider.notifier).reset();

    ref.read(topicsControllerProvider.notifier).reset();

    ref.read(userProgressControllerProvider.notifier).resetState();

    ref.read(loginControllerProvider.notifier).reset();

    ref.read(passwordRecoveryControllerProvider.notifier).reset();

    /*
     * Buang sesi hanya selepas draft dan state
     * yang memerlukan user ID selesai dibersihkan.
     */
    await ref
        .read(accountDeletionControllerProvider.notifier)
        .clearLocalSessionAfterDeletion();

    ref.read(authSessionControllerProvider.notifier).resetState();

    if (!mounted) {
      return;
    }

    setState(() {
      _isFinalizingDeletion = false;
      _deletionCompleted = true;
    });
  }

  void _returnToLogin() {
    ref.read(accountDeletionControllerProvider.notifier).reset();

    context.goNamed(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final deletionState = ref.watch(accountDeletionControllerProvider);

    final isBusy = deletionState.isDeleting || _isFinalizingDeletion;

    return PopScope<void>(
      canPop: !isBusy,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isBusy) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text(
                  'Penghapusan akaun sedang '
                  'diproses. Sila tunggu.',
                ),
              ),
            );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !_deletionCompleted,
          title: const Text('Padam Akaun'),
        ),
        body: SafeArea(
          child: _deletionCompleted
              ? _AccountDeletedContent(onReturnToLogin: _returnToLogin)
              : _DeleteAccountForm(
                  formKey: _formKey,
                  passwordController: _passwordController,
                  confirmationController: _confirmationController,
                  isPasswordVisible: _isPasswordVisible,
                  isBusy: isBusy,
                  errorMessage:
                      deletionState.status == AccountDeletionStatus.failure
                      ? deletionState.errorMessage
                      : null,
                  validatePassword: _validatePassword,
                  validateConfirmation: _validateConfirmation,
                  onTogglePasswordVisibility: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  onDelete: _requestDeletion,
                ),
        ),
      ),
    );
  }
}

class _DeleteAccountForm extends StatelessWidget {
  const _DeleteAccountForm({
    required this.formKey,
    required this.passwordController,
    required this.confirmationController,
    required this.isPasswordVisible,
    required this.isBusy,
    required this.errorMessage,
    required this.validatePassword,
    required this.validateConfirmation,
    required this.onTogglePasswordVisibility,
    required this.onDelete,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController confirmationController;

  final bool isPasswordVisible;
  final bool isBusy;
  final String? errorMessage;

  final FormFieldValidator<String> validatePassword;

  final FormFieldValidator<String> validateConfirmation;

  final VoidCallback onTogglePasswordVisibility;

  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: AppSpacing.largeCardPadding,
                  decoration: const BoxDecoration(
                    color: AppColors.errorBackground,
                    borderRadius: AppRadius.extraLarge,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(24),
                          borderRadius: AppRadius.large,
                        ),
                        child: const Icon(
                          Icons.delete_forever_rounded,
                          size: 40,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Tindakan Kekal',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Akaun dan semua data '
                        'pembelajaran akan dipadam '
                        'secara kekal. Data tersebut '
                        'tidak boleh dipulihkan.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryText,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
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
                      Text('Sahkan Identiti', style: textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Masukkan kata laluan semasa '
                        'dan taip PADAM untuk '
                        'meneruskan.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        label: 'Kata laluan semasa',
                        hint: 'Masukkan kata laluan',
                        controller: passwordController,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.password],
                        obscureText: !isPasswordVisible,
                        enabled: !isBusy,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: isPasswordVisible
                              ? 'Sembunyikan kata laluan'
                              : 'Paparkan kata laluan',
                          onPressed: isBusy ? null : onTogglePasswordVisibility,
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                        validator: validatePassword,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: confirmationController,
                        enabled: !isBusy,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.done,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: const InputDecoration(
                          labelText: 'Frasa pengesahan',
                          hintText: 'Taip PADAM',
                          prefixIcon: Icon(Icons.warning_amber_rounded),
                        ),
                        validator: validateConfirmation,
                        onFieldSubmitted: (_) {
                          if (!isBusy) {
                            onDelete();
                          }
                        },
                      ),
                      if (errorMessage != null) ...[
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
                                  errorMessage!,
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
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        onPressed: isBusy ? null : onDelete,
                        icon: isBusy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textOnPrimary,
                                ),
                              )
                            : const Icon(Icons.delete_forever_rounded),
                        label: Text(
                          isBusy ? 'Memadam Akaun...' : 'Padam Akaun',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountDeletedContent extends StatelessWidget {
  const _AccountDeletedContent({required this.onReturnToLogin});

  final VoidCallback onReturnToLogin;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
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
                'Akaun Telah Dipadam',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Akaun dan data pembelajaran '
                'anda telah berjaya dipadamkan.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: onReturnToLogin,
                icon: const Icon(Icons.login_rounded),
                label: const Text('Kembali ke Log Masuk'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
