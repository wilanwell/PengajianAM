import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/quiz_draft.dart';
import '../../domain/entities/quiz_mode.dart';
import '../../domain/exceptions/quiz_draft_failure.dart';
import '../controllers/quiz_session_controller.dart';
import '../controllers/quiz_session_state.dart';
import '../widgets/quiz_answer_option.dart';
import '../widgets/quiz_progress_header.dart';
import '../widgets/quiz_question_navigator.dart';

enum _QuizExitAction { continueQuiz, saveAndExit, discardAndExit }

class QuizQuestionPage extends ConsumerStatefulWidget {
  const QuizQuestionPage({
    required this.topicId,
    required this.mode,
    required this.questionCount,
    this.resumeDraft = false,
    super.key,
  });

  final String topicId;
  final QuizMode mode;
  final int questionCount;
  final bool resumeDraft;

  @override
  ConsumerState<QuizQuestionPage> createState() {
    return _QuizQuestionPageState();
  }
}

class _QuizQuestionPageState extends ConsumerState<QuizQuestionPage> {
  bool _allowPop = false;
  bool _isExitDialogOpen = false;

  @override
  void initState() {
    super.initState();

    Future<void>.microtask(_initializeQuizSession);
  }

  Future<void> _initializeQuizSession() async {
    final controller = ref.read(quizSessionControllerProvider.notifier);

    if (!widget.resumeDraft) {
      await controller.startQuiz(
        topicId: widget.topicId,
        mode: widget.mode,
        questionCount: widget.questionCount,
      );

      return;
    }

    QuizDraft? draft;

    try {
      draft = await controller.loadAvailableDraft();
    } on QuizDraftFailure catch (error) {
      if (!mounted) {
        return;
      }

      _leaveAfterRestoreFailure(error.message);

      return;
    } catch (_) {
      if (!mounted) {
        return;
      }

      _leaveAfterRestoreFailure(
        'Sesi tersimpan tidak dapat disahkan. '
        'Semak sambungan Internet dan cuba semula.',
      );

      return;
    }

    if (!mounted) {
      return;
    }

    if (draft == null) {
      _leaveAfterRestoreFailure('Sesi kuiz tersimpan tidak lagi tersedia.');

      return;
    }

    bool restored;

    try {
      restored = await controller.restoreDraft(draft);
    } on QuizDraftFailure catch (error) {
      if (!mounted) {
        return;
      }

      _leaveAfterRestoreFailure(error.message);

      return;
    } catch (_) {
      if (!mounted) {
        return;
      }

      _leaveAfterRestoreFailure(
        'Sesi kuiz tidak dapat disambung. '
        'Semak sambungan Internet dan cuba semula.',
      );

      return;
    }

    if (!mounted) {
      return;
    }

    if (!restored) {
      _leaveAfterRestoreFailure(
        'Sesi kuiz tidak dapat disambung. '
        'Sila kembali dan cuba semula.',
      );
    }
  }

  void _leaveAfterRestoreFailure(String message) {
    setState(() {
      _allowPop = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));

      context.pop();
    });
  }

  Future<void> _openQuestionNavigator(QuizSessionState state) async {
    if (state.status != QuizSessionStatus.ready || state.questions.isEmpty) {
      return;
    }

    final selectedIndex = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return QuizQuestionNavigator(
          state: state,
          onClose: () {
            Navigator.of(sheetContext).pop();
          },
          onQuestionSelected: (index) {
            Navigator.of(sheetContext).pop(index);
          },
        );
      },
    );

    if (!mounted || selectedIndex == null) {
      return;
    }

    ref
        .read(quizSessionControllerProvider.notifier)
        .goToQuestion(selectedIndex);
  }

  Future<void> _requestExit(QuizSessionState state) async {
    if (_isExitDialogOpen) {
      return;
    }

    _isExitDialogOpen = true;

    final action = await showDialog<_QuizExitAction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 42,
          ),
          title: const Text('Keluar Kuiz?'),
          content: Text(
            'Kemajuan kuiz disimpan secara '
            'automatik.\n\n'
            '${state.answeredQuestionCount} daripada '
            '${state.questions.length} soalan '
            'telah dijawab.\n'
            '${state.unansweredQuestionCount} '
            'soalan belum dijawab.\n'
            '${state.flaggedQuestionCount} '
            'soalan ditanda.\n\n'
            'Pilih Simpan & Keluar untuk '
            'menyambung kuiz ini kemudian.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(_QuizExitAction.continueQuiz);
              },
              child: const Text('Teruskan Kuiz'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(_QuizExitAction.discardAndExit);
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Buang Sesi'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(_QuizExitAction.saveAndExit);
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Simpan & Keluar'),
            ),
          ],
        );
      },
    );

    _isExitDialogOpen = false;

    if (!mounted || action == null || action == _QuizExitAction.continueQuiz) {
      return;
    }

    final controller = ref.read(quizSessionControllerProvider.notifier);

    switch (action) {
      case _QuizExitAction.continueQuiz:
        return;

      case _QuizExitAction.saveAndExit:
        await controller.preserveDraftAndReset();
        break;

      case _QuizExitAction.discardAndExit:
        await controller.discardDraft();
        break;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _allowPop = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
    });
  }

  void _showSubmittingMessage() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Jawapan sedang dihantar. '
            'Sila tunggu sebentar.',
          ),
        ),
      );
  }

  Future<void> _requestSubmission(QuizSessionState state) async {
    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hantar Jawapan?'),
          content: Text(
            '${state.answeredQuestionCount} daripada '
            '${state.questions.length} soalan '
            'telah dijawab.\n\n'
            '${state.unansweredQuestionCount} soalan '
            'masih belum dijawab.\n\n'
            '${state.flaggedQuestionCount} soalan '
            'telah ditanda.',
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

  void _openQuizResult(QuizSessionState state) {
    final result = state.result;

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _allowPop = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.pushReplacementNamed(RouteNames.quizResult, extra: result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizSessionControllerProvider);

    final controller = ref.read(quizSessionControllerProvider.notifier);

    ref.listen<QuizSessionState>(quizSessionControllerProvider, (
      previous,
      next,
    ) {
      final nextError = next.errorMessage;

      if (next.status == QuizSessionStatus.ready &&
          nextError != null &&
          nextError != previous?.errorMessage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(nextError)));
        });
      }

      if (previous?.status != QuizSessionStatus.completed &&
          next.status == QuizSessionStatus.completed &&
          next.result != null) {
        _openQuizResult(next);
      }
    });

    final shouldBlockExit =
        state.status == QuizSessionStatus.ready ||
        state.status == QuizSessionStatus.submitting;

    final pageMode = state.status == QuizSessionStatus.ready
        ? state.mode
        : widget.mode;

    return PopScope<void>(
      canPop: _allowPop || !shouldBlockExit,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          if (state.status == QuizSessionStatus.initial ||
              state.status == QuizSessionStatus.loading ||
              state.status == QuizSessionStatus.failure) {
            controller.reset();
          }

          return;
        }

        if (state.status == QuizSessionStatus.submitting) {
          _showSubmittingMessage();
          return;
        }

        if (state.status == QuizSessionStatus.ready) {
          await _requestExit(state);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(pageMode.label),
          actions: [
            if (state.status == QuizSessionStatus.ready)
              IconButton(
                tooltip: 'Navigasi soalan',
                onPressed: () {
                  _openQuestionNavigator(state);
                },
                icon: Badge(
                  isLabelVisible: state.unansweredQuestionCount > 0,
                  label: Text('${state.unansweredQuestionCount}'),
                  child: const Icon(Icons.grid_view_rounded),
                ),
              ),
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
              onOpenNavigator: () {
                _openQuestionNavigator(state);
              },
              onSubmit: () {
                _requestSubmission(state);
              },
            ),

            QuizSessionStatus.submitting || QuizSessionStatus.completed =>
              const Center(child: CircularProgressIndicator()),
          },
        ),
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
    required this.onOpenNavigator,
    required this.onSubmit,
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
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
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
        _QuizBottomActionBar(
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

class _QuizBottomActionBar extends StatelessWidget {
  const _QuizBottomActionBar({
    required this.state,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleFlag,
    required this.onSubmit,
  });

  final QuizSessionState state;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToggleFlag;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            /*
             * LayoutBuilder menerima lebar ruang
             * selepas padding kiri dan kanan
             * ditolak.
             *
             * Pada skrin sempit atau saiz teks
             * yang besar, bottom bar menggunakan
             * ikon sahaja.
             */
            final textScaler = MediaQuery.textScalerOf(context);

            final usesLargeText = textScaler.scale(16) > 18;

            final isCompact = constraints.maxWidth < 340 || usesLargeText;

            if (isCompact) {
              return _buildCompactActions();
            }

            return _buildRegularActions();
          },
        ),
      ),
    );
  }

  Widget _buildCompactActions() {
    final nextTooltip = state.isLastQuestion
        ? 'Hantar jawapan'
        : 'Soalan seterusnya';

    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: 'Soalan sebelumnya',
            child: Tooltip(
              message: 'Soalan sebelumnya',
              child: OutlinedButton(
                onPressed: state.canGoPrevious ? onPrevious : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 24),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 56,
          height: 56,
          child: Semantics(
            button: true,
            label: state.isCurrentQuestionFlagged
                ? 'Buang tanda soalan'
                : 'Tandakan soalan',
            child: IconButton.filledTonal(
              tooltip: state.isCurrentQuestionFlagged
                  ? 'Buang tanda soalan'
                  : 'Tandakan soalan',
              onPressed: onToggleFlag,
              iconSize: 24,
              icon: Icon(
                state.isCurrentQuestionFlagged
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Semantics(
            button: true,
            label: nextTooltip,
            child: Tooltip(
              message: nextTooltip,
              child: FilledButton(
                onPressed: state.isLastQuestion ? onSubmit : onNext,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  padding: EdgeInsets.zero,
                ),
                child: Icon(
                  state.isLastQuestion
                      ? Icons.send_rounded
                      : Icons.arrow_forward_rounded,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegularActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: state.canGoPrevious ? onPrevious : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            label: const Text(
              'Sebelum',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 56,
          height: 56,
          child: Semantics(
            button: true,
            label: state.isCurrentQuestionFlagged
                ? 'Buang tanda soalan'
                : 'Tandakan soalan',
            child: IconButton.filledTonal(
              tooltip: state.isCurrentQuestionFlagged
                  ? 'Buang tanda soalan'
                  : 'Tandakan soalan',
              onPressed: onToggleFlag,
              iconSize: 24,
              icon: Icon(
                state.isCurrentQuestionFlagged
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: FilledButton.icon(
            onPressed: state.isLastQuestion ? onSubmit : onNext,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
            icon: Icon(
              state.isLastQuestion
                  ? Icons.send_rounded
                  : Icons.arrow_forward_rounded,
              size: 20,
            ),
            label: Text(
              state.isLastQuestion ? 'Hantar' : 'Seterusnya',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
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
