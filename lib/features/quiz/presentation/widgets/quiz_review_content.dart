import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/quiz_result.dart';
import '../coordinators/quiz_review_coordinator.dart';
import 'quiz_review_card.dart';
import 'quiz_review_support_views.dart';

class QuizReviewContent extends StatelessWidget {
  const QuizReviewContent({
    required this.result,
    required this.selectedFilter,
    required this.visibleQuestionIndexes,
    required this.onFilterSelected,
    super.key,
  });

  final QuizResult result;

  final QuizReviewFilter selectedFilter;

  final List<int> visibleQuestionIndexes;

  final ValueChanged<QuizReviewFilter> onFilterSelected;

  IconData _filterIcon(QuizReviewFilter filter) {
    return switch (filter) {
      QuizReviewFilter.all => Icons.list_alt_rounded,
      QuizReviewFilter.correct => Icons.check_circle_outline_rounded,
      QuizReviewFilter.incorrect => Icons.cancel_outlined,
      QuizReviewFilter.unanswered => Icons.help_outline_rounded,
    };
  }

  String _filterLabel(QuizReviewFilter filter) {
    return switch (filter) {
      QuizReviewFilter.all => 'Semua',
      QuizReviewFilter.correct => 'Betul',
      QuizReviewFilter.incorrect => 'Salah',
      QuizReviewFilter.unanswered => 'Tidak Dijawab',
    };
  }

  Widget _buildQuestionCard(int index) {
    final question = result.questions[index];

    final selectedOptionIndex = result.selectedAnswers[question.id];

    return QuizReviewCard(
      questionNumber: index + 1,
      question: question,
      selectedOptionIndex: selectedOptionIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      key: const Key('quiz-review-view'),
      appBar: AppBar(title: const Text('Semakan Jawapan')),
      body: SafeArea(
        child: ListView(
          key: const PageStorageKey<String>('quiz-review-content'),
          padding: AppSpacing.screenPadding,
          children: [
            QuizReviewSummaryCard(result: result),
            const SizedBox(height: AppSpacing.lg),
            Text('Tapis Jawapan', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              key: const Key('quiz-review-filter-scroll'),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in QuizReviewFilter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: FilterChip(
                        key: Key(
                          'quiz-review-filter-'
                          '${filter.name}',
                        ),
                        avatar: Icon(_filterIcon(filter), size: 18),
                        label: Text(_filterLabel(filter)),
                        selected: selectedFilter == filter,
                        onSelected: (_) {
                          onFilterSelected(filter);
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text('Senarai Soalan', style: textTheme.titleLarge),
                ),
                Text(
                  '${visibleQuestionIndexes.length} '
                  'soalan',
                  key: const Key('quiz-review-visible-count'),
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (visibleQuestionIndexes.isEmpty)
              const QuizReviewEmptyView()
            else
              for (final index in visibleQuestionIndexes) ...[
                _buildQuestionCard(index),
                const SizedBox(height: AppSpacing.sm),
              ],
          ],
        ),
      ),
    );
  }
}
