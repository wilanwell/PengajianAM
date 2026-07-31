import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../topics/domain/entities/study_topic.dart';
import '../../../topics/presentation/controllers/topics_controller.dart';
import '../../domain/entities/quiz_draft.dart';
import '../../domain/entities/quiz_mode.dart';
import '../../domain/entities/quiz_session_source.dart';
import '../../domain/exceptions/quiz_draft_failure.dart';
import '../controllers/quiz_session_controller.dart';
import '../coordinators/quiz_instruction_coordinator.dart';
import '../widgets/existing_quiz_draft_dialog.dart';
import '../widgets/quiz_instruction_content.dart';
import '../widgets/quiz_instruction_topic_not_found_view.dart';

class QuizInstructionPage extends ConsumerStatefulWidget {
  const QuizInstructionPage({
    required this.topicId,
    required this.mode,
    required this.questionCount,
    super.key,
  });

  final String topicId;

  final QuizMode mode;

  final int questionCount;

  @override
  ConsumerState<QuizInstructionPage> createState() {
    return _QuizInstructionPageState();
  }
}

class _QuizInstructionPageState extends ConsumerState<QuizInstructionPage> {
  bool _isProcessing = false;

  Future<void> _handleStartQuiz(StudyTopic selectedTopic) async {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final controller = ref.read(quizSessionControllerProvider.notifier);

    QuizDraft? draft;

    try {
      draft = await controller.loadAvailableDraft();
    } on QuizDraftFailure catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isProcessing = false;
      });

      await showQuizDraftVerificationFailure(
        context: context,
        message: error.message,
        retryActionLabel: 'tekan Mula Kuiz sekali lagi',
      );

      return;
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isProcessing = false;
      });

      await showQuizDraftVerificationFailure(
        context: context,
        message:
            'Sesi tersimpan tidak dapat '
            'diperiksa. Semak sambungan '
            'Internet dan cuba semula.',
        retryActionLabel: 'tekan Mula Kuiz sekali lagi',
      );

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessing = false;
    });

    if (draft == null) {
      _openQuizQuestion(
        topicId: selectedTopic.id,
        mode: widget.mode,
        questionCount: widget.questionCount,
        resumeDraft: false,
      );

      return;
    }

    final topics = ref.read(topicsControllerProvider).topics;

    final coordinator = ref.read(quizInstructionCoordinatorProvider);

    final draftTopic = coordinator.findTopic(
      topics: topics,
      topicId: draft.topicId,
    );

    final action = await showExistingQuizDraftDialog(
      context: context,
      draft: draft,
      draftTopicTitle: draftTopic?.title ?? 'Topik Kuiz Tersimpan',
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case ExistingQuizDraftAction.cancel:
        return;

      case ExistingQuizDraftAction.resume:
        _openQuizQuestion(
          topicId: draft.topicId,
          mode: draft.mode,
          source: draft.source,
          questionCount: draft.questionCount,
          resumeDraft: true,
        );

        return;

      case ExistingQuizDraftAction.startNew:
        setState(() {
          _isProcessing = true;
        });

        await controller.discardDraft();

        if (!mounted) {
          return;
        }

        setState(() {
          _isProcessing = false;
        });

        _openQuizQuestion(
          topicId: selectedTopic.id,
          mode: widget.mode,
          questionCount: widget.questionCount,
          resumeDraft: false,
        );

        return;
    }
  }

  void _openQuizQuestion({
    required String topicId,
    required QuizMode mode,
    QuizSessionSource source = QuizSessionSource.standard,
    required int questionCount,
    required bool resumeDraft,
  }) {
    final queryParameters = ref
        .read(quizInstructionCoordinatorProvider)
        .buildQuizQuestionQueryParameters(
          topicId: topicId,
          mode: mode,
          source: source,
          questionCount: questionCount,
          resumeDraft: resumeDraft,
        );

    context.pushNamed(
      RouteNames.quizQuestion,
      queryParameters: queryParameters,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topicsState = ref.watch(topicsControllerProvider);

    final topic = ref
        .read(quizInstructionCoordinatorProvider)
        .findTopic(topics: topicsState.topics, topicId: widget.topicId);

    if (topic == null) {
      return const QuizInstructionTopicNotFoundView();
    }

    return QuizInstructionContent(
      topic: topic,
      mode: widget.mode,
      questionCount: widget.questionCount,
      isProcessing: _isProcessing,
      onStart: () {
        _handleStartQuiz(topic);
      },
    );
  }
}
