import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/profile_achievement.dart';

class AchievementTile extends StatelessWidget {
  const AchievementTile({required this.achievement, super.key});

  final ProfileAchievement achievement;

  IconData get _icon {
    return switch (achievement.type) {
      AchievementType.firstQuiz => Icons.quiz_rounded,
      AchievementType.highScore => Icons.workspace_premium_rounded,
      AchievementType.sevenDayStreak => Icons.local_fire_department_rounded,
      AchievementType.topicMaster => Icons.menu_book_rounded,
    };
  }

  Color get _color {
    if (!achievement.isUnlocked) {
      return AppColors.disabledText;
    }

    return switch (achievement.type) {
      AchievementType.firstQuiz => AppColors.actionBlue,
      AchievementType.highScore => AppColors.accentGold,
      AchievementType.sevenDayStreak => AppColors.warning,
      AchievementType.topicMaster => AppColors.success,
    };
  }

  Color get _backgroundColor {
    if (!achievement.isUnlocked) {
      return AppColors.surfaceMuted;
    }

    return switch (achievement.type) {
      AchievementType.firstQuiz => AppColors.softBlue,
      AchievementType.highScore => AppColors.warningBackground,
      AchievementType.sevenDayStreak => AppColors.warningBackground,
      AchievementType.topicMaster => AppColors.successBackground,
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: achievement.isUnlocked
              ? _color.withAlpha(100)
              : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: AppRadius.medium,
            ),
            child: Icon(_icon, color: _color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      achievement.isUnlocked
                          ? Icons.check_circle_rounded
                          : Icons.lock_outline_rounded,
                      size: 20,
                      color: _color,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  achievement.description,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                if (!achievement.isUnlocked) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: AppRadius.fullyRounded,
                          child: LinearProgressIndicator(
                            value: achievement.progressValue,
                            minHeight: 7,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${achievement.progress}/'
                        '${achievement.target}',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
