import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../home/presentation/controllers/home_state.dart';
import '../../../progress/domain/entities/user_progress.dart';
import '../../../progress/presentation/controllers/user_progress_controller.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/leaderboard_period.dart';
import '../controllers/leaderboard_controller.dart';
import '../controllers/leaderboard_preference_controller.dart';
import '../controllers/leaderboard_state.dart';
import '../widgets/leaderboard_period_selector.dart';
import '../widgets/leaderboard_podium.dart';
import '../widgets/leaderboard_rank_tile.dart';

class LeaderboardPage extends ConsumerStatefulWidget {
  const LeaderboardPage({super.key});

  @override
  ConsumerState<LeaderboardPage> createState() {
    return _LeaderboardPageState();
  }
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage> {
  bool _isJoiningLeaderboard = false;

  @override
  void initState() {
    super.initState();

    Future<void>.microtask(() async {
      await Future.wait<void>([
        ref
            .read(leaderboardControllerProvider.notifier)
            .loadLeaderboard(forceRefresh: true),
        ref
            .read(leaderboardPreferenceControllerProvider.notifier)
            .loadPreference(),
      ]);
    });
  }

  Future<void> _joinLeaderboard() async {
    if (_isJoiningLeaderboard || !mounted) {
      return;
    }

    final shouldJoin = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
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
            'menyertai pada bila-bila masa '
            'melalui halaman Tetapan.\n\n'
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
      },
    );

    if (shouldJoin != true || !mounted) {
      return;
    }

    setState(() {
      _isJoiningLeaderboard = true;
    });

    String? errorMessage;

    String? refreshWarningMessage;

    try {
      /*
     * Simpan tempoh yang sedang dilihat.
     * Contohnya, tab monthly perlu kekal
     * monthly selepas proses selesai.
     */
      final selectedPeriod = ref.read(leaderboardControllerProvider).period;

      errorMessage = await ref
          .read(leaderboardPreferenceControllerProvider.notifier)
          .updateParticipation(true);

      if (errorMessage == null) {
        final leaderboardController = ref.read(
          leaderboardControllerProvider.notifier,
        );

        final homeController = ref.read(homeControllerProvider.notifier);

        /*
       * Bersihkan leaderboard opt-out dan
       * ringkasan Home yang lama.
       *
       * Jangan gunakan ref.invalidate(Home)
       * kerana HomePage mungkin masih mounted
       * dalam navigation stack.
       */
        leaderboardController.reset();

        homeController.reset();

        /*
       * Muatkan Home secara aktif.
       *
       * HomeController akan mengambil:
       * - progress pengguna;
       * - topik;
       * - leaderboard weekly terkini.
       */
        await homeController.loadDashboard(forceRefresh: true);

        final refreshedHomeState = ref.read(homeControllerProvider);

        if (refreshedHomeState.status != HomeStatus.success) {
          refreshWarningMessage =
              'Anda telah menyertai leaderboard, '
              'tetapi dashboard belum dapat '
              'dikemas kini. Tarik halaman Home '
              'ke bawah untuk refresh.';
        }

        /*
       * loadDashboard menggunakan leaderboard
       * weekly. Apabila pengguna sedang melihat
       * monthly, pulihkan tab monthly selepas
       * Home selesai dimuatkan.
       */
        if (selectedPeriod != LeaderboardPeriod.weekly) {
          await leaderboardController.loadLeaderboard(
            period: selectedPeriod,
            forceRefresh: true,
          );

          final restoredLeaderboardState = ref.read(
            leaderboardControllerProvider,
          );

          if (restoredLeaderboardState.status != LeaderboardStatus.success) {
            refreshWarningMessage ??=
                'Anda telah menyertai leaderboard, '
                'tetapi ranking belum dapat '
                'dikemas kini. Tarik halaman ini '
                'ke bawah untuk refresh.';
          }
        }
      }
    } catch (_) {
      errorMessage ??=
          'Penyertaan leaderboard tidak dapat '
          'diselesaikan. Semak sambungan '
          'Internet dan cuba semula.';
    } finally {
      if (mounted) {
        setState(() {
          _isJoiningLeaderboard = false;
        });
      } else {
        _isJoiningLeaderboard = false;
      }
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            errorMessage ??
                refreshWarningMessage ??
                'Anda kini menyertai '
                    'leaderboard.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    /*
     * Apabila progress berubah selepas kuiz,
     * leaderboard dimuatkan semula.
     *
     * Listener dihentikan sementara ketika
     * proses opt-in supaya tidak mewujudkan
     * request tambahan yang bertindih.
     */
    ref.listen<UserProgress>(userProgressControllerProvider, (previous, next) {
      if (_isJoiningLeaderboard) {
        return;
      }

      final currentLeaderboardState = ref.read(leaderboardControllerProvider);

      if (currentLeaderboardState.status == LeaderboardStatus.loading) {
        return;
      }

      final selectedPeriod = currentLeaderboardState.period;

      final controller = ref.read(leaderboardControllerProvider.notifier);

      controller.reset();

      unawaited(controller.loadLeaderboard(period: selectedPeriod));
    });

    final state = ref.watch(leaderboardControllerProvider);

    final preferenceState = ref.watch(leaderboardPreferenceControllerProvider);

    final controller = ref.read(leaderboardControllerProvider.notifier);

    final isJoining = _isJoiningLeaderboard || preferenceState.isBusy;

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: SafeArea(
        child: switch (state.status) {
          LeaderboardStatus.initial || LeaderboardStatus.loading =>
            const Center(child: CircularProgressIndicator()),

          LeaderboardStatus.failure => _LeaderboardErrorView(
            message:
                state.errorMessage ??
                'Leaderboard tidak dapat '
                    'dimuatkan.',
            onRetry: () {
              unawaited(controller.loadLeaderboard(forceRefresh: true));
            },
          ),

          LeaderboardStatus.success => _LeaderboardContent(
            state: state,
            isJoining: isJoining,
            onJoin: _joinLeaderboard,
            onPeriodSelected: (period) {
              unawaited(controller.changePeriod(period));
            },
            onRefresh: controller.refreshLeaderboard,
          ),
        },
      ),
    );
  }
}

class _LeaderboardContent extends StatelessWidget {
  const _LeaderboardContent({
    required this.state,
    required this.isJoining,
    required this.onJoin,
    required this.onPeriodSelected,
    required this.onRefresh,
  });

  final LeaderboardState state;

  final bool isJoining;

  final Future<void> Function() onJoin;

  final ValueChanged<LeaderboardPeriod> onPeriodSelected;

  final Future<void> Function() onRefresh;

  String get _lastUpdatedLabel {
    final value = state.lastUpdated;

    if (value == null) {
      return 'Belum dikemas kini';
    }

    final hours = value.hour.toString().padLeft(2, '0');

    final minutes = value.minute.toString().padLeft(2, '0');

    return 'Dikemas kini pada '
        '$hours:$minutes';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final currentUser = state.currentUserEntry;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenPadding,
        children: [
          LeaderboardPeriodSelector(
            selectedPeriod: state.period,
            onPeriodSelected: onPeriodSelected,
          ),
          const SizedBox(height: AppSpacing.sm),

          Text(
            state.period.description,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          Text(
            '${state.participantCount} '
            'peserta',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          if (!state.isParticipating)
            _LeaderboardOptOutCard(
              currentXp: state.currentUserXp,
              period: state.period,
              isJoining: isJoining,
              onJoin: onJoin,
            )
          else if (currentUser != null)
            _CurrentUserSummaryCard(entry: currentUser),

          const SizedBox(height: AppSpacing.lg),

          if (state.entries.isEmpty)
            const _EmptyLeaderboardCard()
          else ...[
            Text('3 Teratas', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),

            LeaderboardPodium(entries: state.topThree),

            if (state.remainingEntries.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Kedudukan Seterusnya',
                      style: textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _lastUpdatedLabel,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              for (final entry in state.remainingEntries) ...[
                LeaderboardRankTile(entry: entry),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ],

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _LeaderboardOptOutCard extends StatelessWidget {
  const _LeaderboardOptOutCard({
    required this.currentXp,
    required this.period,
    required this.isJoining,
    required this.onJoin,
  });

  final int currentXp;

  final LeaderboardPeriod period;

  final bool isJoining;

  final Future<void> Function() onJoin;

  String get _periodLabel {
    return switch (period) {
      LeaderboardPeriod.weekly => 'minggu ini',
      LeaderboardPeriod.monthly => 'bulan ini',
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: AppSpacing.largeCardPadding,
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: AppRadius.extraLarge,
        border: Border.all(color: AppColors.actionBlue.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.actionBlue,
                  borderRadius: AppRadius.medium,
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  color: AppColors.textOnPrimary,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anda mempunyai '
                      '$currentXp XP '
                      '$_periodLabel',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Sertai leaderboard '
                      'untuk melihat ranking '
                      'anda dan bersaing '
                      'menggunakan nama '
                      'samaran.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          Container(
            padding: AppSpacing.cardPadding,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.medium,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.privacy_tip_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Pengguna lain hanya '
                    'melihat nama samaran. '
                    'Nama paparan sebenar '
                    'anda tidak ditunjukkan '
                    'kepada mereka.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryText,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          FilledButton.icon(
            onPressed: isJoining
                ? null
                : () {
                    unawaited(onJoin());
                  },
            icon: isJoining
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnPrimary,
                    ),
                  )
                : const Icon(Icons.emoji_events_rounded),
            label: Text(
              isJoining ? 'Sedang Menyertai...' : 'Sertai Leaderboard',
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLeaderboardCard extends StatelessWidget {
  const _EmptyLeaderboardCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: AppSpacing.largeCardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.extraLarge,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            size: 52,
            color: AppColors.secondaryText,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Belum Ada Peserta',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Leaderboard akan dipaparkan '
            'selepas pengguna memilih '
            'untuk menyertainya.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentUserSummaryCard extends StatelessWidget {
  const _CurrentUserSummaryCard({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: AppSpacing.largeCardPadding,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.extraLarge,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.accentGold,
            foregroundColor: AppColors.primaryText,
            child: Text(entry.initials, style: textTheme.titleMedium),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kedudukan Anda',
                  style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '#${entry.rank}',
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.xp} XP',
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.accentGold,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                entry.movement > 0
                    ? 'Naik '
                          '${entry.movement} '
                          'kedudukan'
                    : entry.movement < 0
                    ? 'Turun '
                          '${entry.movement.abs()} '
                          'kedudukan'
                    : 'Tiada perubahan',
                style: textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaderboardErrorView extends StatelessWidget {
  const _LeaderboardErrorView({required this.message, required this.onRetry});

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
