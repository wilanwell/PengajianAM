import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/leaderboard_entry.dart';

class LeaderboardPodium extends StatelessWidget {
  const LeaderboardPodium({required this.entries, super.key});

  final List<LeaderboardEntry> entries;

  LeaderboardEntry? _entryAtRank(int rank) {
    for (final entry in entries) {
      if (entry.rank == rank) {
        return entry;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _PodiumCard(
            entry: _entryAtRank(2),
            rank: 2,
            height: 152,
            color: AppColors.silver,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _PodiumCard(
            entry: _entryAtRank(1),
            rank: 1,
            height: 184,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _PodiumCard(
            entry: _entryAtRank(3),
            rank: 3,
            height: 136,
            color: AppColors.bronze,
          ),
        ),
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.entry,
    required this.rank,
    required this.height,
    required this.color,
  });

  final LeaderboardEntry? entry;
  final int rank;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final leaderboardEntry = entry;

    return Container(
      height: height,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: AppRadius.large,
        border: Border.all(color: color.withAlpha(110)),
      ),
      child: leaderboardEntry == null
          ? const SizedBox.shrink()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: rank == 1 ? 29 : 25,
                  backgroundColor: color,
                  foregroundColor: AppColors.primaryText,
                  child: Text(
                    leaderboardEntry.initials,
                    style: textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  leaderboardEntry.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: textTheme.labelMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${leaderboardEntry.xp} XP',
                  maxLines: 1,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$rank',
                    style: textTheme.titleMedium?.copyWith(
                      color: rank == 1
                          ? AppColors.primaryText
                          : AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
