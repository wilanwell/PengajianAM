import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/quiz_mode.dart';
import '../controllers/quiz_session_controller.dart';
import '../controllers/quiz_session_state.dart';
import '../widgets/quiz_answer_option.dart';
import '../widgets/quiz_progress_header.dart';

class QuizQuestionPage extends ConsumerStatefulWidget {
  const QuizQuestionPage({
    required this.topicId,
    required this.mode,
    required this.questionCount,
    super.key,
  });

  final String topicId;
  final QuizMode mode;
  final int questionCount;

  @override
  ConsumerState<QuizQuestionPage> createState() {
    return _QuizQuestionPageState();
  }
}

class _QuizQuestionPageState extends ConsumerState<QuizQuestionPage> {
  @override
  void initState() {
    super.initState();

    Future<void>.microtask(() {
      ref
          .read(quizSessionControllerProvider.notifier)
          .startQuiz(
            topicId: widget.topicId,
            mode: widget.mode,
            questionCount: widget.questionCount,
          );
    });
  }

  Future<void> _requestSubmission(QuizSessionState state) async {
    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hantar Jawapan?'),
          content: Text(
            '${state.answeredQuestionCount} daripada '
            '${state.questions.length} soalan telah dijawab.\n\n'
            '${state.unansweredQuestionCount} soalan '
            'masih belum dijawab.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Semak Semula'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Hantar'),
            ),
          ],
        );
      },
    );

    if (shouldSubmit != true || !mounted) {
      return;
    }

    await ref.read(quizSessionControllerProvider.notifier).submitQuiz();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizSessionControllerProvider);

    final controller = ref.read(quizSessionControllerProvider.notifier);

    ref.listen<QuizSessionState>(quizSessionControllerProvider, (
      previous,
      next,
    ) {
      if (previous?.status != QuizSessionStatus.completed &&
          next.status == QuizSessionStatus.completed &&
          next.result != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }

          context.pushReplacementNamed(
            RouteNames.quizResult,
            extra: next.result,
          );
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode.label),
        actions: [
          if (state.formattedRemainingTime != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: Container(
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
                        Icons.timer_outlined,
                        size: 18,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        state.formattedRemainingTime!,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.warning),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: switch (state.status) {
          QuizSessionStatus.initial || QuizSessionStatus.loading =>
            const Center(child: CircularProgressIndicator()),

          QuizSessionStatus.failure => _QuizSessionErrorView(
            message: state.errorMessage ?? 'Kuiz tidak dapat dimulakan.',
            onRetry: () {
              controller.startQuiz(
                topicId: widget.topicId,
                mode: widget.mode,
                questionCount: widget.questionCount,
              );
            },
          ),

          QuizSessionStatus.ready => _QuizQuestionContent(
            state: state,
            onAnswerSelected: controller.selectAnswer,
            onPrevious: controller.previousQuestion,
            onNext: controller.nextQuestion,
            onToggleFlag: controller.toggleFlagCurrentQuestion,
            onSubmit: () {
              _requestSubmission(state);
            },
          ),

          QuizSessionStatus.submitting || QuizSessionStatus.completed =>
            const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _QuizQuestionContent extends StatelessWidget {
  const _QuizQuestionContent({
    required this.state,
    required this.onAnswerSelected,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleFlag,
    required this.onSubmit,
  });

  final QuizSessionState state;
  final ValueChanged<int> onAnswerSelected;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToggleFlag;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final question = state.currentQuestion;
    final textTheme = Theme.of(context).textTheme;

    if (question == null) {
      return const Center(child: Text('Soalan tidak tersedia.'));
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: AppSpacing.screenPadding,
            children: [
              QuizProgressHeader(
                currentQuestionNumber: state.currentQuestionIndex + 1,
                totalQuestions: state.questions.length,
                answeredQuestions: state.answeredQuestionCount,
                progress: state.progress,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: AppSpacing.largeCardPadding,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.extraLarge,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Soalan ${state.currentQuestionIndex + 1}',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.actionBlue,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(question.questionText, style: textTheme.headlineSmall),
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
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.canGoPrevious ? onPrevious : null,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Sebelum'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton.filledTonal(
                  tooltip: state.isCurrentQuestionFlagged
                      ? 'Buang tanda'
                      : 'Tandakan soalan',
                  onPressed: onToggleFlag,
                  icon: Icon(
                    state.isCurrentQuestionFlagged
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: state.isLastQuestion ? onSubmit : onNext,
                    icon: Icon(
                      state.isLastQuestion
                          ? Icons.send_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                    label: Text(state.isLastQuestion ? 'Hantar' : 'Seterusnya'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuizSessionErrorView extends StatelessWidget {
  const _QuizSessionErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Cuba Semula'),
            ),
          ],
        ),
      ),
    );
  }
}
