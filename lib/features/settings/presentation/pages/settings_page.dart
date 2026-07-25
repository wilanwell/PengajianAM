import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../analytics/presentation/controllers/topic_analytics_controller.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../leaderboard/domain/entities/leaderboard_period.dart';
import '../../../leaderboard/presentation/controllers/leaderboard_controller.dart';
import '../../../leaderboard/presentation/controllers/leaderboard_preference_controller.dart';
import '../../../leaderboard/presentation/controllers/leaderboard_preference_state.dart';
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

    Future<void>.microtask(() async {
      await Future.wait<void>([
        ref.read(appSettingsControllerProvider.notifier).loadSettings(),
        ref
            .read(leaderboardPreferenceControllerProvider.notifier)
            .loadPreference(),
      ]);
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
          content: Text(
            errorMessage ??
                'Mode kuiz lalai telah '
                    'dikemas kini.',
          ),
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
            errorMessage ??
                'Jumlah soalan lalai telah '
                    'dikemas kini.',
          ),
        ),
      );
  }

  Future<void> _updateLeaderboardParticipation(bool optIn) async {
    final preferenceState = ref.read(leaderboardPreferenceControllerProvider);

    if (preferenceState.isBusy) {
      return;
    }

    final shouldUpdate = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        if (optIn) {
          return AlertDialog(
            icon: const Icon(
              Icons.emoji_events_outlined,
              color: AppColors.actionBlue,
              size: 44,
            ),
            title: const Text('Sertai Leaderboard?'),
            content: const Text(
              'Apabila anda menyertai '
              'leaderboard:\n\n'
              '\u2022 XP mingguan dan bulanan '
              'anda akan digunakan untuk '
              'menentukan ranking.\n'
              '\u2022 Pengguna lain hanya akan '
              'melihat nama samaran seperti '
              'Pelajar-A1B2.\n'
              '\u2022 Nama paparan sebenar anda '
              'hanya ditunjukkan kepada anda '
              'sendiri.\n'
              '\u2022 Anda boleh berhenti '
              'menyertai pada bila-bila masa.\n\n'
              'Dengan memilih “Saya Setuju & '
              'Sertai”, anda memberikan '
              'persetujuan untuk XP tempoh '
              'semasa digunakan dalam '
              'leaderboard.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text('Batal'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Saya Setuju & Sertai'),
              ),
            ],
          );
        }

        return AlertDialog(
          icon: const Icon(
            Icons.privacy_tip_outlined,
            color: AppColors.primary,
            size: 44,
          ),
          title: const Text('Berhenti Menyertai?'),
          content: const Text(
            'Anda akan dikeluarkan daripada '
            'leaderboard.\n\n'
            'XP, progress, sejarah kuiz dan '
            'analitik pembelajaran anda tidak '
            'akan dipadamkan.\n\n'
            'Anda masih boleh melihat '
            'leaderboard tanpa mempunyai '
            'ranking sendiri.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Berhenti Menyertai'),
            ),
          ],
        );
      },
    );

    if (shouldUpdate != true || !mounted) {
      return;
    }

    /*
     * Simpan tempoh leaderboard yang sedang
     * dipilih sebelum controller direset.
     */
    final selectedLeaderboardPeriod = ref
        .read(leaderboardControllerProvider)
        .period;

    final errorMessage = await ref
        .read(leaderboardPreferenceControllerProvider.notifier)
        .updateParticipation(optIn);

    if (!mounted) {
      return;
    }

    if (errorMessage == null) {
      /*
       * Bersihkan ranking lama daripada
       * shared state.
       */
      ref.read(leaderboardControllerProvider.notifier).reset();

      ref.read(homeControllerProvider.notifier).reset();

      /*
       * Home menggunakan leaderboard weekly.
       * loadDashboard akan mengambil status
       * penyertaan yang paling terkini.
       */
      await ref
          .read(homeControllerProvider.notifier)
          .loadDashboard(forceRefresh: true);

      /*
       * Sekiranya pengguna sebelum ini memilih
       * leaderboard monthly, pulihkan tempoh
       * tersebut selepas Home selesai memuatkan
       * leaderboard weekly.
       */
      if (selectedLeaderboardPeriod != LeaderboardPeriod.weekly) {
        await ref
            .read(leaderboardControllerProvider.notifier)
            .loadLeaderboard(
              period: selectedLeaderboardPeriod,
              forceRefresh: true,
            );
      }
    }

    if (!mounted) {
      return;
    }

    final successMessage = optIn
        ? 'Anda kini menyertai leaderboard.'
        : 'Anda tidak lagi menyertai leaderboard.';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(errorMessage ?? successMessage)));
  }

  Future<void> _resetAllData() async {
    if (_isResettingData) {
      return;
    }

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
            'Tindakan ini akan memadam dan '
            'mengembalikan data berikut kepada '
            'nilai asal:\n\n'
            '\u2022 Nama paparan\n'
            '\u2022 XP dan statistik kuiz\n'
            '\u2022 Aktiviti mingguan\n'
            '\u2022 Sejarah kuiz\n'
            '\u2022 Analitik prestasi\n'
            '\u2022 Sesi kuiz belum selesai\n'
            '\u2022 Jawapan draft pada peranti\n'
            '\u2022 Tetapan kuiz lalai\n\n'
            'Akaun log masuk anda tidak akan '
            'dipadamkan.\n\n'
            'Tindakan ini tidak boleh '
            'dibatalkan.',
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
      /*
       * RPC reset_my_learning_data() akan:
       * - reset XP dan progress;
       * - memadam quiz_attempts;
       * - memadam private.quiz_sessions;
       * - mengembalikan nama paparan asal.
       */
      await ref
          .read(userProgressControllerProvider.notifier)
          .clearLocalProgress();

      /*
       * Padam draft SharedPreferences dan
       * hentikan timer serta state kuiz.
       */
      await ref.read(quizSessionControllerProvider.notifier).discardDraft();

      /*
       * Bersihkan state controller supaya data
       * lama tidak dipaparkan.
       */
      ref.read(quizHistoryControllerProvider.notifier).reset();

      ref.read(topicAnalyticsControllerProvider.notifier).reset();

      ref.read(quizSetupControllerProvider.notifier).reset();

      ref.read(homeControllerProvider.notifier).reset();

      ref.read(profileControllerProvider.notifier).reset();

      ref.read(leaderboardControllerProvider.notifier).reset();

      final settingsError = await ref
          .read(appSettingsControllerProvider.notifier)
          .resetToDefaults();

      errorMessage = settingsError;

      /*
       * Muatkan data terkini selepas reset.
       *
       * Preference leaderboard tidak direset
       * kerana ia merupakan pilihan privasi,
       * bukan progress pembelajaran.
       */
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
      errorMessage =
          'Sebahagian data tidak dapat '
          'direset. Semak sambungan Internet '
          'dan cuba semula.';
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
          content: Text(
            errorMessage ??
                'Semua data pembelajaran '
                    'telah direset.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appSettingsControllerProvider);

    final leaderboardPreferenceState = ref.watch(
      leaderboardPreferenceControllerProvider,
    );

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
              unawaited(controller.loadSettings(forceRefresh: true));
            },
          ),

          AppSettingsStatus.success => _SettingsContent(
            settings: state.settings,
            leaderboardPreferenceState: leaderboardPreferenceState,
            isResettingData: _isResettingData,
            onRefresh: () async {
              await Future.wait<void>([
                controller.loadSettings(forceRefresh: true),
                ref
                    .read(leaderboardPreferenceControllerProvider.notifier)
                    .loadPreference(forceRefresh: true),
              ]);
            },
            onModeSelected: _updateDefaultMode,
            onQuestionCountSelected: _updateDefaultQuestionCount,
            onLeaderboardParticipationChanged: _updateLeaderboardParticipation,
            onRetryLeaderboardPreference: () {
              return ref
                  .read(leaderboardPreferenceControllerProvider.notifier)
                  .loadPreference(forceRefresh: true);
            },
            onResetData: _resetAllData,
          ),
        },
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent({
    required this.settings,
    required this.leaderboardPreferenceState,
    required this.isResettingData,
    required this.onRefresh,
    required this.onModeSelected,
    required this.onQuestionCountSelected,
    required this.onLeaderboardParticipationChanged,
    required this.onRetryLeaderboardPreference,
    required this.onResetData,
  });

  final AppSettings settings;

  final LeaderboardPreferenceState leaderboardPreferenceState;

  final bool isResettingData;

  final Future<void> Function() onRefresh;

  final Future<void> Function(QuizMode) onModeSelected;

  final Future<void> Function(int) onQuestionCountSelected;

  final Future<void> Function(bool) onLeaderboardParticipationChanged;

  final Future<void> Function() onRetryLeaderboardPreference;

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
                        'Sesuaikan tetapan kuiz '
                        'mengikut cara pembelajaran '
                        'anda.',
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
            'Mode ini akan dipilih secara '
            'automatik apabila anda membuka '
            'halaman Kuiz.',
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
              unawaited(onModeSelected(QuizMode.practice));
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _SettingsOptionTile(
            icon: Icons.timer_rounded,
            title: QuizMode.exam.label,
            description: QuizMode.exam.description,
            isSelected: settings.defaultQuizMode == QuizMode.exam,
            onTap: () {
              unawaited(onModeSelected(QuizMode.exam));
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Jumlah Soalan Lalai', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Jumlah soalan ini akan dipilih '
            'secara automatik untuk kuiz '
            'baharu.',
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
                    unawaited(onQuestionCountSelected(count));
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Privasi Leaderboard', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pilih sama ada XP tempoh semasa '
            'boleh digunakan untuk menentukan '
            'ranking anda.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _LeaderboardParticipationCard(
            state: leaderboardPreferenceState,
            onChanged: onLeaderboardParticipationChanged,
            onRetry: onRetryLeaderboardPreference,
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Undang-undang dan Privasi', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Baca maklumat tentang penggunaan '
            'aplikasi dan pengurusan data anda.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SettingsNavigationTile(
            icon: Icons.gavel_outlined,
            title: 'Terma Penggunaan',
            description:
                'Syarat dan peraturan penggunaan '
                'aplikasi',
            onTap: () {
              context.pushNamed(RouteNames.termsOfUse);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _SettingsNavigationTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Dasar Privasi',
            description:
                'Cara data pengguna dikumpul '
                'dan dilindungi',
            onTap: () {
              context.pushNamed(RouteNames.privacyPolicy);
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Pengurusan Data', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          _ResetDataCard(isResetting: isResettingData, onReset: onResetData),
          const SizedBox(height: AppSpacing.lg),

          Text('Pengurusan Akaun', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Urus tindakan kekal yang '
            'berkaitan dengan akaun anda.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _DeleteAccountNavigationTile(
            onTap: () {
              context.pushNamed(RouteNames.deleteAccount);
            },
          ),
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

class _LeaderboardParticipationCard extends StatelessWidget {
  const _LeaderboardParticipationCard({
    required this.state,
    required this.onChanged,
    required this.onRetry,
  });

  final LeaderboardPreferenceState state;

  final Future<void> Function(bool) onChanged;

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final isLoading =
        state.status == LeaderboardPreferenceStatus.initial ||
        state.status == LeaderboardPreferenceStatus.loading;

    final hasFailure = state.status == LeaderboardPreferenceStatus.failure;

    final isOptedIn = state.isOptedIn;

    final consentVersion =
        state.preference?.consentVersion ??
        state.preference?.requiredConsentVersion;

    return Container(
      padding: AppSpacing.largeCardPadding,
      decoration: BoxDecoration(
        color: isOptedIn ? AppColors.softBlue : AppColors.surface,
        borderRadius: AppRadius.extraLarge,
        border: Border.all(
          color: isOptedIn ? AppColors.actionBlue : AppColors.border,
          width: isOptedIn ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isOptedIn
                      ? AppColors.actionBlue
                      : AppColors.surfaceMuted,
                  borderRadius: AppRadius.medium,
                ),
                child: Icon(
                  Icons.emoji_events_outlined,
                  color: isOptedIn
                      ? AppColors.textOnPrimary
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sertai Leaderboard', style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      isOptedIn ? 'Penyertaan aktif' : 'Penyertaan tidak aktif',
                      style: textTheme.bodySmall?.copyWith(
                        color: isOptedIn
                            ? AppColors.actionBlue
                            : AppColors.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (isLoading || state.isUpdating)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else
                Switch.adaptive(
                  value: isOptedIn,
                  onChanged: state.canUpdate
                      ? (value) {
                          unawaited(onChanged(value));
                        }
                      : null,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isOptedIn
                ? 'XP mingguan dan bulanan '
                      'anda digunakan untuk '
                      'menentukan ranking. '
                      'Pengguna lain hanya '
                      'melihat nama samaran.'
                : 'Anda tidak muncul dalam '
                      'ranking. XP, progress '
                      'dan sejarah pembelajaran '
                      'anda masih disimpan.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
              height: 1.4,
            ),
          ),
          if (isOptedIn && consentVersion != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Persetujuan versi '
                    '$consentVersion',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (hasFailure) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: AppSpacing.cardPadding,
              decoration: const BoxDecoration(
                color: AppColors.errorBackground,
                borderRadius: AppRadius.medium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.errorMessage ??
                        'Tetapan leaderboard '
                            'tidak dapat dimuatkan.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () {
                      unawaited(onRetry());
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Cuba Semula'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsNavigationTile extends StatelessWidget {
  const _SettingsNavigationTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large,
        child: Ink(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            borderRadius: AppRadius.large,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: AppRadius.medium,
                ),
                child: Icon(icon, color: AppColors.primary),
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
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.secondaryText,
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
                  'Reset Data Pembelajaran',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Reset progress, XP, sejarah, '
            'analitik, sesi kuiz belum selesai '
            'dan tetapan lalai.',
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
                    unawaited(onReset());
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

class _DeleteAccountNavigationTile extends StatelessWidget {
  const _DeleteAccountNavigationTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.errorBackground,
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large,
        child: Ink(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            borderRadius: AppRadius.large,
            border: Border.all(color: AppColors.error.withAlpha(90)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(22),
                  borderRadius: AppRadius.medium,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Padam Akaun',
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Padam akaun dan semua data '
                      'secara kekal',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.chevron_right_rounded, color: AppColors.error),
            ],
          ),
        ),
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
