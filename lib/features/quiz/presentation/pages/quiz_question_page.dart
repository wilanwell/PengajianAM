import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../domain/entities/quiz_draft.dart';
import '../../domain/entities/quiz_mode.dart';
import '../../domain/entities/quiz_session_source.dart';
import '../../domain/exceptions/quiz_draft_failure.dart';
import '../controllers/quiz_session_controller.dart';
import '../controllers/quiz_session_state.dart';
import '../widgets/quiz_question_app_bar.dart';
import '../widgets/quiz_question_content.dart';
import '../widgets/quiz_question_dialogs.dart';
import '../widgets/quiz_question_navigator.dart';
import '../widgets/quiz_session_error_view.dart';

class QuizQuestionPage extends ConsumerStatefulWidget {
  const QuizQuestionPage({
    required this.topicId,
    required this.mode,
    required this.questionCount,
    this.source = QuizSessionSource.standard,
    this.resumeDraft = false,
    super.key,
  });

  final String topicId;
  final QuizMode mode;
  final QuizSessionSource source;
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
      await _startRequestedSession();

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

  Future<void> _startRequestedSession() {
    final controller = ref.read(quizSessionControllerProvider.notifier);

    if (widget.source == QuizSessionSource.mistakeReview) {
      return controller.startMistakeReview(
        topicId: widget.topicId,
        questionCount: widget.questionCount,
      );
    }

    return controller.startQuiz(
      topicId: widget.topicId,
      mode: widget.mode,
      questionCount: widget.questionCount,
    );
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

    final action = await QuizQuestionDialogs.showExitDialog(
      context: context,
      state: state,
    );

    _isExitDialogOpen = false;

    if (!mounted || action == null || action == QuizExitAction.continueQuiz) {
      return;
    }

    final controller = ref.read(quizSessionControllerProvider.notifier);

    switch (action) {
      case QuizExitAction.continueQuiz:
        return;

      case QuizExitAction.saveAndExit:
        await controller.preserveDraftAndReset();
        break;

      case QuizExitAction.discardAndExit:
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

  Future<void> _requestSubmission(QuizSessionState state) async {
    final shouldSubmit = await QuizQuestionDialogs.showSubmitDialog(
      context: context,
      state: state,
    );

    if (!shouldSubmit || !mounted) {
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

    final pageSource = state.status == QuizSessionStatus.ready
        ? state.source
        : widget.source;

    final pageTitle = pageSource == QuizSessionSource.mistakeReview
        ? pageSource.label
        : pageMode.label;

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
          QuizQuestionDialogs.showSubmittingMessage(context);
          return;
        }

        if (state.status == QuizSessionStatus.ready) {
          await _requestExit(state);
        }
      },
      child: Scaffold(
        appBar: QuizQuestionAppBar(
          title: pageTitle,
          showQuestionNavigator: state.status == QuizSessionStatus.ready,
          unansweredQuestionCount: state.unansweredQuestionCount,
          remainingTimeLabel: state.formattedRemainingTime,
          onOpenQuestionNavigator: () {
            _openQuestionNavigator(state);
          },
        ),
        body: SafeArea(
          child: switch (state.status) {
            QuizSessionStatus.initial || QuizSessionStatus.loading =>
              const Center(child: CircularProgressIndicator()),

            QuizSessionStatus.failure => QuizSessionErrorView(
              message:
                  state.errorMessage ??
                  '${pageSource.label} tidak dapat dimulakan.',
              onRetry: () {
                _startRequestedSession();
              },
            ),

            QuizSessionStatus.ready => QuizQuestionContent(
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
