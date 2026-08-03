import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../controllers/quiz_session_state.dart';
import 'quiz_answer_option.dart';
import 'quiz_bottom_action_bar.dart';
import 'quiz_progress_header.dart';

class QuizQuestionContent extends StatelessWidget {
  const QuizQuestionContent({
    required this.state,
    required this.onAnswerSelected,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleFlag,
    required this.onOpenNavigator,
    required this.onSubmit,
    super.key,
  });

  final QuizSessionState state;
  final ValueChanged<int> onAnswerSelected;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToggleFlag;
  final VoidCallback onOpenNavigator;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final question = state.currentQuestion;

    if (question == null) {
      return const Center(
        key: Key('quiz-question-unavailable-view'),
        child: Text('Soalan tidak tersedia.'),
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return Column(
      key: const Key('quiz-question-content'),
      children: [
        Expanded(
          child: ListView(
            key: const PageStorageKey<String>('quiz-question-scroll-content'),
            padding: AppSpacing.screenPadding,
            children: [
              QuizProgressHeader(
                currentQuestionNumber: state.currentQuestionIndex + 1,
                totalQuestions: state.questions.length,
                answeredQuestions: state.answeredQuestionCount,
                progress: state.progress,
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                key: const Key('quiz-open-navigator-button'),
                onPressed: onOpenNavigator,
                icon: const Icon(Icons.grid_view_rounded),
                label: Text(
                  'Semak Semua Soalan '
                  '(${state.unansweredQuestionCount} '
                  'belum dijawab)',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                key: const Key('quiz-current-question-card'),
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
                      children: [
                        Expanded(
                          child: Text(
                            'Soalan '
                            '${state.currentQuestionIndex + 1}',
                            style: textTheme.labelMedium?.copyWith(
                              color: AppColors.actionBlue,
                            ),
                          ),
                        ),
                        if (state.isCurrentQuestionFlagged)
                          Container(
                            key: const Key('quiz-current-question-flagged'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.warningBackground,
                              borderRadius: AppRadius.fullyRounded,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.bookmark_rounded,
                                  size: 16,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: AppSpacing.xxs),
                                Text(
                                  'Ditanda',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      question.questionText,
                      key: const Key('quiz-current-question-text'),
                      style: textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (var index = 0; index < question.options.length; index++) ...[
                QuizAnswerOption(
                  index: index,
                  text: question.options[index],
                  isSelected: state.selectedAnswerForCurrentQuestion == index,
                  onTap: () {
                    onAnswerSelected(index);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
        QuizBottomActionBar(
          state: state,
          onPrevious: onPrevious,
          onNext: onNext,
          onToggleFlag: onToggleFlag,
          onSubmit: onSubmit,
        ),
      ],
    );
  }
}
