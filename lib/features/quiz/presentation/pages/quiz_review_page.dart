import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/quiz_question.dart';
import '../../domain/entities/quiz_result.dart';
import '../widgets/quiz_review_card.dart';

enum QuizReviewFilter { all, correct, incorrect, unanswered }

class QuizReviewPage extends StatefulWidget {
  const QuizReviewPage({required this.result, super.key});

  final QuizResult result;

  @override
  State<QuizReviewPage> createState() {
    return _QuizReviewPageState();
  }
}

class _QuizReviewPageState extends State<QuizReviewPage> {
  QuizReviewFilter _selectedFilter = QuizReviewFilter.all;

  List<int> get _visibleQuestionIndexes {
    final indexes = <int>[];

    for (var index = 0; index < widget.result.questions.length; index++) {
      final question = widget.result.questions[index];

      if (_matchesFilter(question)) {
        indexes.add(index);
      }
    }

    return indexes;
  }

  bool _matchesFilter(QuizQuestion question) {
    final selectedOptionIndex = widget.result.selectedAnswers[question.id];

    final isAnswered = selectedOptionIndex != null;
    final isCorrect = question.isCorrect(selectedOptionIndex);

    return switch (_selectedFilter) {
      QuizReviewFilter.all => true,
      QuizReviewFilter.correct => isCorrect,
      QuizReviewFilter.incorrect => isAnswered && !isCorrect,
      QuizReviewFilter.unanswered => !isAnswered,
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

  IconData _filterIcon(QuizReviewFilter filter) {
    return switch (filter) {
      QuizReviewFilter.all => Icons.list_alt_rounded,
      QuizReviewFilter.correct => Icons.check_circle_outline_rounded,
      QuizReviewFilter.incorrect => Icons.cancel_outlined,
      QuizReviewFilter.unanswered => Icons.help_outline_rounded,
    };
  }

  void _selectFilter(QuizReviewFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleIndexes = _visibleQuestionIndexes;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Semakan Jawapan')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            _ReviewSummaryCard(result: widget.result),
            const SizedBox(height: AppSpacing.lg),
            Text('Tapis Jawapan', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in QuizReviewFilter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: FilterChip(
                        avatar: Icon(_filterIcon(filter), size: 18),
                        label: Text(_filterLabel(filter)),
                        selected: _selectedFilter == filter,
                        onSelected: (_) {
                          _selectFilter(filter);
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
                  '${visibleIndexes.length} soalan',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (visibleIndexes.isEmpty)
              const _ReviewEmptyView()
            else
              for (final index in visibleIndexes) ...[
                QuizReviewCard(
                  questionNumber: index + 1,
                  question: widget.result.questions[index],
                  selectedOptionIndex: widget
                      .result
                      .selectedAnswers[widget.result.questions[index].id],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
          ],
        ),
      ),
    );
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  const _ReviewSummaryCard({required this.result});

  final QuizResult result;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
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
            'Semak kesilapan dan fahami penerangan bagi '
            'setiap soalan.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Betul',
                  value: '${result.correctAnswers}',
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Salah',
                  value: '${result.incorrectAnswers}',
                  color: AppColors.error,
                ),
              ),
              Expanded(
                child: _SummaryItem(
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

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
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

class _ReviewEmptyView extends StatelessWidget {
  const _ReviewEmptyView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
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
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pilih penapis lain untuk melihat soalan.',
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
