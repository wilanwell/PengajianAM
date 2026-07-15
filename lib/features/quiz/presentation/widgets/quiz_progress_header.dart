import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';

class QuizProgressHeader extends StatelessWidget {
  const QuizProgressHeader({
    required this.currentQuestionNumber,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.progress,
    super.key,
  });

  final int currentQuestionNumber;
  final int totalQuestions;
  final int answeredQuestions;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Soalan $currentQuestionNumber '
                  'daripada $totalQuestions',
                  style: textTheme.titleMedium,
                ),
              ),
              Text(
                '$answeredQuestions dijawab',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.actionBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.fullyRounded,
            child: LinearProgressIndicator(value: progress, minHeight: 8),
          ),
        ],
      ),
    );
  }
}
