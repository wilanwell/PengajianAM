import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/quiz_result.dart';
import '../../domain/entities/quiz_session_source.dart';

class QuizResultSummaryCard extends StatelessWidget {
  const QuizResultSummaryCard({required this.result, super.key});

  final QuizResult result;

  bool get _isMistakeReview {
    return result.sessionSource == QuizSessionSource.mistakeReview;
  }

  String get _heading {
    if (_isMistakeReview) {
      return 'Latihan Selesai';
    }

    return result.passed ? 'Bagus!' : 'Teruskan Berusaha';
  }

  String get _description {
    if (_isMistakeReview) {
      return 'Status Buku Kesilapan '
          'anda telah dikemas kini.';
    }

    if (result.autoSubmitted) {
      return 'Masa tamat dan kuiz telah '
          'dihantar secara automatik.';
    }

    return 'Kuiz anda telah berjaya dihantar.';
  }

  Color get _backgroundColor {
    return result.passed
        ? AppColors.successBackground
        : AppColors.warningBackground;
  }

  Color get _accentColor {
    return result.passed ? AppColors.success : AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final percentage = result.percentage.round();

    return Container(
      key: const Key('quiz-result-summary-card'),
      padding: AppSpacing.largeCardPadding,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: AppRadius.extraLarge,
      ),
      child: Column(
        children: [
          Container(
            key: const Key('quiz-result-score-circle'),
            width: 144,
            height: 144,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: _accentColor, width: 10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${result.correctAnswers}/'
                  '${result.totalQuestions}',
                  key: const Key('quiz-result-score'),
                  style: textTheme.headlineLarge?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '$percentage%',
                  key: const Key('quiz-result-percentage'),
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _heading,
            key: const Key('quiz-result-heading'),
            style: textTheme.headlineSmall?.copyWith(color: _accentColor),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _description,
            key: const Key('quiz-result-description'),
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
