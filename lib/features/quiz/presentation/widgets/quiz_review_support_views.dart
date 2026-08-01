import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/quiz_result.dart';

class QuizReviewSummaryCard extends StatelessWidget {
  const QuizReviewSummaryCard({required this.result, super.key});

  final QuizResult result;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: const Key('quiz-review-summary-card'),
      padding: AppSpacing.largeCardPadding,
      decoration: const BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: AppRadius.extraLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Semakan',
            style: textTheme.headlineSmall?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Semak kesilapan dan fahami penerangan '
            'bagi setiap soalan.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _QuizReviewSummaryItem(
                  itemKey: const Key('quiz-review-summary-correct'),
                  label: 'Betul',
                  value: '${result.correctAnswers}',
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _QuizReviewSummaryItem(
                  itemKey: const Key('quiz-review-summary-incorrect'),
                  label: 'Salah',
                  value: '${result.incorrectAnswers}',
                  color: AppColors.error,
                ),
              ),
              Expanded(
                child: _QuizReviewSummaryItem(
                  itemKey: const Key('quiz-review-summary-unanswered'),
                  label: 'Tidak Dijawab',
                  value: '${result.unansweredQuestions}',
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class QuizReviewEmptyView extends StatelessWidget {
  const QuizReviewEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: const Key('quiz-review-empty-view'),
      padding: AppSpacing.largeCardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 52,
            color: AppColors.secondaryText,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tiada jawapan dalam kategori ini',
            key: const Key('quiz-review-empty-heading'),
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pilih penapis lain untuk melihat soalan.',
            key: const Key('quiz-review-empty-description'),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizReviewSummaryItem extends StatelessWidget {
  const _QuizReviewSummaryItem({
    required this.itemKey,
    required this.label,
    required this.value,
    required this.color,
  });

  final Key itemKey;

  final String label;

  final String value;

  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      key: itemKey,
      children: [
        Text(value, style: textTheme.headlineSmall?.copyWith(color: color)),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
        ),
      ],
    );
  }
}
