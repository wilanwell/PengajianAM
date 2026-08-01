import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/quiz_result.dart';
import 'quiz_result_support_cards.dart';

class QuizResultStatisticsGrid extends StatelessWidget {
  const QuizResultStatisticsGrid({required this.result, super.key});

  final QuizResult result;

  String get _elapsedTimeLabel {
    final minutes = result.elapsedTime.inMinutes;

    final seconds = result.elapsedTime.inSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;

        final cardWidth = constraints.maxWidth < 420
            ? constraints.maxWidth
            : (constraints.maxWidth - gap) / 2;

        return Wrap(
          key: const Key('quiz-result-statistics'),
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: cardWidth,
              child: QuizResultStatCard(
                key: const Key('quiz-result-correct-stat'),
                icon: Icons.check_circle_rounded,
                label: 'Betul',
                value: '${result.correctAnswers}',
                color: AppColors.success,
                backgroundColor: AppColors.successBackground,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: QuizResultStatCard(
                key: const Key('quiz-result-incorrect-stat'),
                icon: Icons.cancel_rounded,
                label: 'Salah',
                value: '${result.incorrectAnswers}',
                color: AppColors.error,
                backgroundColor: AppColors.errorBackground,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: QuizResultStatCard(
                key: const Key('quiz-result-unanswered-stat'),
                icon: Icons.help_outline_rounded,
                label: 'Tidak Dijawab',
                value: '${result.unansweredQuestions}',
                color: AppColors.warning,
                backgroundColor: AppColors.warningBackground,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: QuizResultStatCard(
                key: const Key('quiz-result-time-stat'),
                icon: Icons.timer_outlined,
                label: 'Masa Digunakan',
                value: _elapsedTimeLabel,
                color: AppColors.actionBlue,
                backgroundColor: AppColors.softBlue,
              ),
            ),
          ],
        );
      },
    );
  }
}
