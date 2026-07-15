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
            minimumHeight: 184,
            avatarRadius: 25,
            color: AppColors.silver,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _PodiumCard(
            entry: _entryAtRank(1),
            rank: 1,
            minimumHeight: 216,
            avatarRadius: 29,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _PodiumCard(
            entry: _entryAtRank(3),
            rank: 3,
            minimumHeight: 174,
            avatarRadius: 25,
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
    required this.minimumHeight,
    required this.avatarRadius,
    required this.color,
  });

  final LeaderboardEntry? entry;
  final int rank;
  final double minimumHeight;
  final double avatarRadius;
  final Color color;

  Color get _avatarTextColor {
    return rank == 1 ? AppColors.primaryText : AppColors.textOnPrimary;
  }

  Color get _rankTextColor {
    return rank == 1 ? AppColors.primaryText : AppColors.textOnPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final leaderboardEntry = entry;

    return Container(
      constraints: BoxConstraints(minHeight: minimumHeight),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: AppRadius.large,
        border: Border.all(color: color.withAlpha(110)),
      ),
      child: leaderboardEntry == null
          ? const SizedBox.shrink()
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: color,
                  foregroundColor: _avatarTextColor,
                  child: Text(
                    leaderboardEntry.initials,
                    style: textTheme.labelLarge?.copyWith(
                      color: _avatarTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    leaderboardEntry.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: textTheme.labelMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    '${leaderboardEntry.xp} XP',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
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
                      color: _rankTextColor,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
