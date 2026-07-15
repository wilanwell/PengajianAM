import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/study_topic.dart';

class TopicCard extends StatelessWidget {
  const TopicCard({required this.topic, required this.onTap, super.key});

  final StudyTopic topic;
  final VoidCallback onTap;

  IconData get _icon {
    return switch (topic.code) {
      'S1-01' => Icons.psychology_alt_rounded,
      'S1-02' => Icons.flag_rounded,
      'S1-03' => Icons.account_balance_rounded,
      'S1-04' => Icons.groups_rounded,
      'S1-05' => Icons.admin_panel_settings_rounded,
      'S1-06' => Icons.apartment_rounded,
      'S1-07' => Icons.shield_rounded,
      _ => Icons.menu_book_rounded,
    };
  }

  String get _progressLabel {
    if (topic.isCompleted) {
      return 'Selesai';
    }

    if (topic.isNotStarted) {
      return 'Belum mula';
    }

    return '${topic.progressPercentage}% selesai';
  }

  Color get _progressColor {
    if (topic.isCompleted) {
      return AppColors.success;
    }

    return AppColors.actionBlue;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: '${topic.title}, ${topic.questionCount} soalan, $_progressLabel',
      child: Material(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.softBlue,
                        borderRadius: AppRadius.medium,
                      ),
                      child: Icon(_icon, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic.code,
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.actionBlue,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(topic.title, style: textTheme.titleMedium),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.secondaryText,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  topic.description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(
                      Icons.quiz_outlined,
                      size: 18,
                      color: AppColors.secondaryText,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${topic.questionCount} soalan',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _progressLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: _progressColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: AppRadius.fullyRounded,
                  child: LinearProgressIndicator(
                    value: topic.progress,
                    minHeight: 7,
                    color: _progressColor,
                    backgroundColor: AppColors.border,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${topic.completedQuestionCount} daripada '
                  '${topic.questionCount} soalan diselesaikan',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
