import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/quiz_attempt.dart';
import '../../domain/entities/quiz_mode.dart';

class QuizHistoryTile extends StatelessWidget {
  const QuizHistoryTile({
    required this.attempt,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final QuizAttempt attempt;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String get _dateLabel {
    const monthNames = [
      'Jan',
      'Feb',
      'Mac',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ogos',
      'Sep',
      'Okt',
      'Nov',
      'Dis',
    ];

    final value = attempt.completedAt.toLocal();
    final month = monthNames[value.month - 1];
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '${value.day} $month ${value.year}, '
        '$hour:$minute';
  }

  String get _durationLabel {
    final duration = attempt.result.elapsedTime;
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final result = attempt.result;
    final textTheme = Theme.of(context).textTheme;

    final statusColor = result.passed ? AppColors.success : AppColors.warning;

    final statusBackground = result.passed
        ? AppColors.successBackground
        : AppColors.warningBackground;

    final title = result.topicCode.isEmpty
        ? result.topicTitle
        : '${result.topicCode} · ${result.topicTitle}';

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: statusBackground,
                      borderRadius: AppRadius.medium,
                    ),
                    child: Text(
                      '${result.percentage.round()}%',
                      style: textTheme.labelLarge?.copyWith(color: statusColor),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          _dateLabel,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Padam rekod',
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _HistoryInformation(
                    icon: Icons.check_circle_outline,
                    label:
                        '${result.correctAnswers}/'
                        '${result.totalQuestions} betul',
                  ),
                  _HistoryInformation(
                    icon: Icons.timer_outlined,
                    label: _durationLabel,
                  ),
                  _HistoryInformation(
                    icon: Icons.star_outline_rounded,
                    label: '+${attempt.earnedXp} XP',
                  ),
                  _HistoryInformation(
                    icon: result.mode.name == 'exam'
                        ? Icons.timer_rounded
                        : Icons.school_rounded,
                    label: result.mode.label,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tekan untuk membuka keputusan',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.secondaryText,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryInformation extends StatelessWidget {
  const _HistoryInformation({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.fullyRounded,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xxs),
          Text(label, style: textTheme.labelSmall),
        ],
      ),
    );
  }
}
