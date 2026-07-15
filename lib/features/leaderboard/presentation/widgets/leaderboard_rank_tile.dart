import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/leaderboard_entry.dart';

class LeaderboardRankTile extends StatelessWidget {
  const LeaderboardRankTile({required this.entry, super.key});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final backgroundColor = entry.isCurrentUser
        ? AppColors.softBlue
        : AppColors.surface;

    final borderColor = entry.isCurrentUser
        ? AppColors.actionBlue
        : AppColors.border;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: borderColor,
          width: entry.isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: entry.isCurrentUser
                    ? AppColors.actionBlue
                    : AppColors.primaryText,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          CircleAvatar(
            backgroundColor: entry.isCurrentUser
                ? AppColors.actionBlue
                : AppColors.surfaceMuted,
            foregroundColor: entry.isCurrentUser
                ? AppColors.textOnPrimary
                : AppColors.primary,
            child: Text(entry.initials, style: textTheme.labelMedium),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.isCurrentUser
                      ? '${entry.nickname} · Anda'
                      : entry.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${entry.xp} XP',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _MovementIndicator(entry: entry),
        ],
      ),
    );
  }
}

class _MovementIndicator extends StatelessWidget {
  const _MovementIndicator({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (entry.movement == 0) {
      return const Icon(Icons.remove_rounded, color: AppColors.disabledText);
    }

    final isMovingUp = entry.isMovingUp;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMovingUp
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded,
          size: 18,
          color: isMovingUp ? AppColors.success : AppColors.error,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          '${entry.movement.abs()}',
          style: textTheme.labelSmall?.copyWith(
            color: isMovingUp ? AppColors.success : AppColors.error,
          ),
        ),
      ],
    );
  }
}
