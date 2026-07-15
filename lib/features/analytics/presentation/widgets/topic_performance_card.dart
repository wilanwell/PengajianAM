import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/topic_performance.dart';

class TopicPerformanceCard extends StatelessWidget {
  const TopicPerformanceCard({required this.performance, super.key});

  final TopicPerformance performance;

  Color get _statusColor {
    return switch (performance.masteryLevel) {
      TopicMasteryLevel.strong => AppColors.success,
      TopicMasteryLevel.developing => AppColors.actionBlue,
      TopicMasteryLevel.needsImprovement => AppColors.warning,
    };
  }

  Color get _statusBackgroundColor {
    return switch (performance.masteryLevel) {
      TopicMasteryLevel.strong => AppColors.successBackground,
      TopicMasteryLevel.developing => AppColors.softBlue,
      TopicMasteryLevel.needsImprovement => AppColors.warningBackground,
    };
  }

  IconData get _statusIcon {
    return switch (performance.masteryLevel) {
      TopicMasteryLevel.strong => Icons.workspace_premium_rounded,
      TopicMasteryLevel.developing => Icons.trending_up_rounded,
      TopicMasteryLevel.needsImprovement => Icons.priority_high_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final title = performance.topicCode.isEmpty
        ? performance.topicTitle
        : '${performance.topicCode} · '
              '${performance.topicTitle}';

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _statusBackgroundColor,
                  borderRadius: AppRadius.medium,
                ),
                child: Icon(_statusIcon, color: _statusColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(title, style: textTheme.titleMedium)),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _statusBackgroundColor,
                  borderRadius: AppRadius.fullyRounded,
                ),
                child: Text(
                  '${performance.averageScorePercentage}%',
                  style: textTheme.labelMedium?.copyWith(color: _statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  performance.masteryLevel.label,
                  style: textTheme.labelMedium?.copyWith(color: _statusColor),
                ),
              ),
              Text(
                '${performance.totalCorrectAnswers}/'
                '${performance.totalQuestions} betul',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppRadius.fullyRounded,
            child: LinearProgressIndicator(
              value: performance.averageScore / 100,
              minHeight: 9,
              color: _statusColor,
              backgroundColor: AppColors.border,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _PerformanceMetric(
                  icon: Icons.replay_rounded,
                  value: '${performance.attemptCount}',
                  label: 'Percubaan',
                ),
              ),
              Expanded(
                child: _PerformanceMetric(
                  icon: Icons.emoji_events_outlined,
                  value: '${performance.bestScore.round()}%',
                  label: 'Skor Terbaik',
                ),
              ),
              Expanded(
                child: _PerformanceMetric(
                  icon: Icons.star_outline_rounded,
                  value: '${performance.totalEarnedXp}',
                  label: 'XP',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerformanceMetric extends StatelessWidget {
  const _PerformanceMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: AppSpacing.xxs),
        Text(value, textAlign: TextAlign.center, style: textTheme.titleSmall),
        Text(
          label,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
        ),
      ],
    );
  }
}
