import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/leaderboard_period.dart';
import '../controllers/leaderboard_controller.dart';
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
  @override
  void initState() {
    super.initState();

    Future<void>.microtask(() {
      ref.read(leaderboardControllerProvider.notifier).loadLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaderboardControllerProvider);

    final controller = ref.read(leaderboardControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: SafeArea(
        child: switch (state.status) {
          LeaderboardStatus.initial || LeaderboardStatus.loading =>
            const Center(child: CircularProgressIndicator()),

          LeaderboardStatus.failure => _LeaderboardErrorView(
            message: state.errorMessage ?? 'Leaderboard tidak dapat dimuatkan.',
            onRetry: () {
              controller.loadLeaderboard(forceRefresh: true);
            },
          ),

          LeaderboardStatus.success => _LeaderboardContent(
            state: state,
            onPeriodSelected: controller.changePeriod,
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
    required this.onPeriodSelected,
    required this.onRefresh,
  });

  final LeaderboardState state;
  final ValueChanged<LeaderboardPeriod> onPeriodSelected;
  final Future<void> Function() onRefresh;

  String get _lastUpdatedLabel {
    final value = state.lastUpdated;

    if (value == null) {
      return 'Belum dikemas kini';
    }

    final hours = value.hour.toString().padLeft(2, '0');
    final minutes = value.minute.toString().padLeft(2, '0');

    return 'Dikemas kini pada $hours:$minutes';
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
          const SizedBox(height: AppSpacing.lg),
          if (currentUser != null) _CurrentUserSummaryCard(entry: currentUser),
          const SizedBox(height: AppSpacing.lg),
          Text('3 Teratas', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          LeaderboardPodium(entries: state.topThree),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text('Kedudukan Penuh', style: textTheme.titleLarge),
              ),
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
          const SizedBox(height: AppSpacing.lg),
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
                    ? 'Naik ${entry.movement} kedudukan'
                    : entry.movement < 0
                    ? 'Turun ${entry.movement.abs()} kedudukan'
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
