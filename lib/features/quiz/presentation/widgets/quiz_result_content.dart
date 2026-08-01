import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/quiz_result.dart';
import '../../domain/entities/quiz_session_source.dart';
import 'quiz_result_statistics_grid.dart';
import 'quiz_result_summary_card.dart';
import 'quiz_result_support_cards.dart';

class QuizResultContent extends StatelessWidget {
  const QuizResultContent({
    required this.result,
    required this.onReviewAnswers,
    required this.onRetryQuiz,
    required this.onReturnToMistakeBookTopic,
    required this.onReturnToTopics,
    super.key,
  });

  final QuizResult result;

  final VoidCallback onReviewAnswers;

  final VoidCallback onRetryQuiz;

  final VoidCallback onReturnToMistakeBookTopic;

  final VoidCallback onReturnToTopics;

  bool get _isMistakeReview {
    return result.sessionSource == QuizSessionSource.mistakeReview;
  }

  String get _pageTitle {
    return _isMistakeReview ? 'Keputusan Latihan Semula' : 'Keputusan Kuiz';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('quiz-result-view'),
      appBar: AppBar(title: Text(_pageTitle)),
      body: SafeArea(
        child: ListView(
          key: const PageStorageKey<String>('quiz-result-content'),
          padding: AppSpacing.screenPadding,
          children: [
            QuizResultSummaryCard(result: result),
            const SizedBox(height: AppSpacing.md),
            if (_isMistakeReview)
              const QuizResultMistakeReviewInfoCard(
                key: Key('quiz-result-mistake-review-card'),
              )
            else
              QuizResultEarnedXpCard(
                key: const Key('quiz-result-earned-xp-card'),
                earnedXp: result.earnedXp,
              ),
            const SizedBox(height: AppSpacing.lg),
            QuizResultStatisticsGrid(result: result),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              key: const Key('quiz-result-review-button'),
              onPressed: onReviewAnswers,
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Semak Jawapan'),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_isMistakeReview)
              OutlinedButton.icon(
                key: const Key('quiz-result-mistake-book-button'),
                onPressed: onReturnToMistakeBookTopic,
                icon: const Icon(Icons.auto_stories_rounded),
                label: const Text(
                  'Kembali ke Topik '
                  'Buku Kesilapan',
                ),
              )
            else
              OutlinedButton.icon(
                key: const Key('quiz-result-retry-button'),
                onPressed: onRetryQuiz,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Cuba Lagi'),
              ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              key: const Key('quiz-result-topics-button'),
              onPressed: onReturnToTopics,
              child: const Text('Kembali ke Topik'),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
