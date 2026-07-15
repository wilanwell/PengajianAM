import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../analytics/presentation/controllers/topic_analytics_controller.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../leaderboard/presentation/controllers/leaderboard_controller.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../../progress/presentation/controllers/user_progress_controller.dart';
import '../../../quiz/domain/entities/quiz_mode.dart';
import '../../../quiz/presentation/controllers/quiz_history_controller.dart';
import '../../../quiz/presentation/controllers/quiz_session_controller.dart';
import '../../../quiz/presentation/controllers/quiz_setup_controller.dart';
import '../../domain/entities/app_settings.dart';
import '../controllers/app_settings_controller.dart';
import '../controllers/app_settings_state.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() {
    return _SettingsPageState();
  }
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isResettingData = false;

  @override
  void initState() {
    super.initState();

    Future<void>.microtask(() {
      ref.read(appSettingsControllerProvider.notifier).loadSettings();
    });
  }

  Future<void> _updateDefaultMode(QuizMode mode) async {
    final errorMessage = await ref
        .read(appSettingsControllerProvider.notifier)
        .updateDefaultQuizMode(mode);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Mode kuiz lalai telah dikemas kini.'),
        ),
      );
  }

  Future<void> _updateDefaultQuestionCount(int questionCount) async {
    final errorMessage = await ref
        .read(appSettingsControllerProvider.notifier)
        .updateDefaultQuestionCount(questionCount);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            errorMessage ?? 'Jumlah soalan lalai telah dikemas kini.',
          ),
        ),
      );
  }

  Future<void> _resetLocalData() async {
    final shouldReset = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            size: 44,
            color: AppColors.error,
          ),
          title: const Text('Reset Semua Data?'),
          content: const Text(
            'Tindakan ini akan memadam dan mengembalikan '
            'data berikut kepada nilai asal:\n\n'
            '• Nama paparan\n'
            '• XP dan statistik kuiz\n'
            '• Aktiviti mingguan\n'
            '• Sejarah kuiz\n'
            '• Analitik prestasi\n'
            '• Tetapan kuiz lalai\n\n'
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
              label: const Text('Reset Data'),
            ),
          ],
        );
      },
    );

    if (shouldReset != true || !mounted) {
      return;
    }

    setState(() {
      _isResettingData = true;
    });

    String? errorMessage;

    try {
      await ref
          .read(userProgressControllerProvider.notifier)
          .clearLocalProgress();

      await ref.read(quizHistoryControllerProvider.notifier).clearHistory();

      errorMessage = await ref
          .read(appSettingsControllerProvider.notifier)
          .resetToDefaults();

      ref.read(quizSetupControllerProvider.notifier).reset();

      ref.read(quizSessionControllerProvider.notifier).reset();

      ref.read(topicAnalyticsControllerProvider.notifier).reset();

      await Future.wait<void>([
        ref
            .read(homeControllerProvider.notifier)
            .loadDashboard(forceRefresh: true),
        ref
            .read(profileControllerProvider.notifier)
            .loadProfile(forceRefresh: true),
        ref
            .read(leaderboardControllerProvider.notifier)
            .loadLeaderboard(forceRefresh: true),
      ]);
    } catch (_) {
      errorMessage = 'Sebahagian data tempatan tidak dapat direset.';
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isResettingData = false;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Semua data tempatan telah direset.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appSettingsControllerProvider);

    final controller = ref.read(appSettingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Tetapan')),
      body: SafeArea(
        child: switch (state.status) {
          AppSettingsStatus.initial || AppSettingsStatus.loading =>
            const Center(child: CircularProgressIndicator()),

          AppSettingsStatus.failure => _SettingsErrorView(
            message: state.errorMessage ?? 'Tetapan tidak dapat dimuatkan.',
            onRetry: () {
              controller.loadSettings(forceRefresh: true);
            },
          ),

          AppSettingsStatus.success => _SettingsContent(
            settings: state.settings,
            isResettingData: _isResettingData,
            onRefresh: () {
              return controller.loadSettings(forceRefresh: true);
            },
            onModeSelected: _updateDefaultMode,
            onQuestionCountSelected: _updateDefaultQuestionCount,
            onResetData: _resetLocalData,
          ),
        },
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent({
    required this.settings,
    required this.isResettingData,
    required this.onRefresh,
    required this.onModeSelected,
    required this.onQuestionCountSelected,
    required this.onResetData,
  });

  final AppSettings settings;
  final bool isResettingData;
  final Future<void> Function() onRefresh;
  final Future<void> Function(QuizMode) onModeSelected;
  final Future<void> Function(int) onQuestionCountSelected;
  final Future<void> Function() onResetData;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenPadding,
        children: [
          Container(
            padding: AppSpacing.largeCardPadding,
            decoration: const BoxDecoration(
              color: AppColors.softBlue,
              borderRadius: AppRadius.extraLarge,
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppRadius.large,
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: AppColors.textOnPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tetapan Pembelajaran',
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Sesuaikan tetapan kuiz mengikut '
                        'cara pembelajaran anda.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Mode Kuiz Lalai', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Mode ini akan dipilih secara automatik apabila '
            'anda membuka halaman Kuiz.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SettingsOptionTile(
            icon: Icons.school_rounded,
            title: QuizMode.practice.label,
            description: QuizMode.practice.description,
            isSelected: settings.defaultQuizMode == QuizMode.practice,
            onTap: () {
              onModeSelected(QuizMode.practice);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _SettingsOptionTile(
            icon: Icons.timer_rounded,
            title: QuizMode.exam.label,
            description: QuizMode.exam.description,
            isSelected: settings.defaultQuizMode == QuizMode.exam,
            onTap: () {
              onModeSelected(QuizMode.exam);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Jumlah Soalan Lalai', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Jumlah soalan ini akan dipilih secara automatik '
            'untuk kuiz baharu.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final count in AppSettings.allowedQuestionCounts)
                ChoiceChip(
                  label: Text('$count soalan'),
                  selected: settings.defaultQuestionCount == count,
                  onSelected: (_) {
                    onQuestionCountSelected(count);
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Pengurusan Data', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          _ResetDataCard(isResetting: isResettingData, onReset: onResetData),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _SettingsOptionTile extends StatelessWidget {
  const _SettingsOptionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: isSelected ? AppColors.softBlue : AppColors.surface,
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large,
        child: Ink(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            borderRadius: AppRadius.large,
            border: Border.all(
              color: isSelected ? AppColors.actionBlue : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.actionBlue
                      : AppColors.surfaceMuted,
                  borderRadius: AppRadius.medium,
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? AppColors.textOnPrimary
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected
                    ? AppColors.actionBlue
                    : AppColors.disabledText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResetDataCard extends StatelessWidget {
  const _ResetDataCard({required this.isResetting, required this.onReset});

  final bool isResetting;
  final Future<void> Function() onReset;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: AppSpacing.largeCardPadding,
      decoration: BoxDecoration(
        color: AppColors.errorBackground,
        borderRadius: AppRadius.extraLarge,
        border: Border.all(color: AppColors.error.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.delete_forever_rounded, color: AppColors.error),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Reset Data Tempatan',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Padam semua progress, XP, sejarah kuiz, '
            'analitik dan tetapan yang disimpan dalam telefon.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: isResetting
                ? null
                : () {
                    onReset();
                  },
            icon: isResetting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.restart_alt_rounded),
            label: Text(isResetting ? 'Sedang Reset...' : 'Reset Semua Data'),
          ),
        ],
      ),
    );
  }
}

class _SettingsErrorView extends StatelessWidget {
  const _SettingsErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Cuba Semula'),
            ),
          ],
        ),
      ),
    );
  }
}
