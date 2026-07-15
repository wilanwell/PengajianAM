import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/student_profile.dart';

class ProfileProgressCard extends StatelessWidget {
  const ProfileProgressCard({required this.profile, super.key});

  final StudentProfile profile;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kemajuan Keseluruhan', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Topik diselesaikan',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              Text(
                '${profile.completedTopics}/'
                '${profile.totalTopics}',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.actionBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppRadius.fullyRounded,
            child: LinearProgressIndicator(
              value: profile.topicProgress,
              minHeight: 9,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${profile.topicProgressPercentage}% daripada '
            'silibus Semester 1 telah diselesaikan.',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = AppSpacing.sm;

              final columnCount = constraints.maxWidth < 360 ? 1 : 2;

              final cardWidth = columnCount == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - gap) / 2;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _ProgressMetric(
                      icon: Icons.star_rounded,
                      value: '${profile.totalXp}',
                      label: 'Jumlah XP',
                      color: AppColors.accentGold,
                      backgroundColor: AppColors.warningBackground,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _ProgressMetric(
                      icon: Icons.quiz_rounded,
                      value: '${profile.completedQuizzes}',
                      label: 'Kuiz Disiapkan',
                      color: AppColors.actionBlue,
                      backgroundColor: AppColors.softBlue,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _ProgressMetric(
                      icon: Icons.track_changes_rounded,
                      value: '${profile.averageScore.round()}%',
                      label: 'Purata Markah',
                      color: AppColors.success,
                      backgroundColor: AppColors.successBackground,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _ProgressMetric(
                      icon: Icons.local_fire_department_rounded,
                      value: '${profile.currentStreakDays} hari',
                      label: 'Streak Semasa',
                      color: AppColors.warning,
                      backgroundColor: AppColors.warningBackground,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.large,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: AppRadius.medium,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: textTheme.titleMedium),
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
