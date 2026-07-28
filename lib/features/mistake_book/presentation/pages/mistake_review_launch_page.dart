import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../quiz/domain/entities/quiz_draft.dart';
import '../../../quiz/domain/entities/quiz_mode.dart';
import '../../../quiz/domain/entities/quiz_session_source.dart';
import '../../../quiz/domain/exceptions/quiz_draft_failure.dart';
import '../../../quiz/presentation/controllers/quiz_session_controller.dart';
import '../../../quiz/presentation/widgets/existing_quiz_draft_dialog.dart';
import '../../../topics/domain/entities/study_topic.dart';
import '../../../topics/presentation/controllers/topics_controller.dart';
import '../../domain/services/mistake_book_review_policy.dart';

class MistakeReviewLaunchPage extends ConsumerStatefulWidget {
  const MistakeReviewLaunchPage({
    required this.topicId,
    required this.requestedQuestionCount,
    super.key,
  });

  final String topicId;
  final int requestedQuestionCount;

  @override
  ConsumerState<MistakeReviewLaunchPage> createState() {
    return _MistakeReviewLaunchPageState();
  }
}

class _MistakeReviewLaunchPageState
    extends ConsumerState<MistakeReviewLaunchPage> {
  bool _isProcessing = false;
  bool _hasStartedPreparation = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    Future<void>.microtask(_prepareReview);
  }

  @override
  void didUpdateWidget(covariant MistakeReviewLaunchPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.topicId == widget.topicId &&
        oldWidget.requestedQuestionCount == widget.requestedQuestionCount) {
      return;
    }

    _hasStartedPreparation = false;
    _errorMessage = null;

    Future<void>.microtask(_prepareReview);
  }

  Future<void> _prepareReview() async {
    if (_hasStartedPreparation || _isProcessing) {
      return;
    }

    final normalizedTopicId = widget.topicId.trim();

    final questionCount = MistakeBookReviewPolicy.resolveQuestionCount(
      widget.requestedQuestionCount,
    );

    if (normalizedTopicId.isEmpty) {
      setState(() {
        _errorMessage = 'Topik latihan semula tidak tersedia.';
      });

      return;
    }

    if (questionCount < 1) {
      setState(() {
        _errorMessage =
            'Tiada soalan yang boleh dimasukkan '
            'ke dalam latihan semula.';
      });

      return;
    }

    _hasStartedPreparation = true;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
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
        retryActionLabel: 'tekan Latih Semula sekali lagi',
      );

      if (!mounted) {
        return;
      }

      _returnToMistakeBookTopic();

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
            'Sesi tersimpan tidak dapat diperiksa. '
            'Semak sambungan Internet dan cuba semula.',
        retryActionLabel: 'tekan Latih Semula sekali lagi',
      );

      if (!mounted) {
        return;
      }

      _returnToMistakeBookTopic();

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessing = false;
    });

    if (draft == null) {
      _openNewMistakeReview(
        topicId: normalizedTopicId,
        questionCount: questionCount,
      );

      return;
    }

    final draftTopicTitle = _resolveDraftTopicTitle(draft);

    final action = await showExistingQuizDraftDialog(
      context: context,
      draft: draft,
      draftTopicTitle: draftTopicTitle,
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case ExistingQuizDraftAction.cancel:
        _returnToMistakeBookTopic();
        return;

      case ExistingQuizDraftAction.resume:
        _openSavedDraft(draft);
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

        _openNewMistakeReview(
          topicId: normalizedTopicId,
          questionCount: questionCount,
        );

        return;
    }
  }

  String _resolveDraftTopicTitle(QuizDraft draft) {
    final topics = ref.read(topicsControllerProvider).topics;

    final matchingTopic = _findTopic(topics, draft.topicId);

    if (matchingTopic != null) {
      return matchingTopic.title;
    }

    if (draft.topicId.trim() == widget.topicId.trim()) {
      return 'Topik Buku Kesilapan Semasa';
    }

    return draft.source == QuizSessionSource.mistakeReview
        ? 'Topik Latihan Semula Tersimpan'
        : 'Topik Kuiz Tersimpan';
  }

  StudyTopic? _findTopic(List<StudyTopic> topics, String topicId) {
    for (final topic in topics) {
      if (topic.id == topicId) {
        return topic;
      }
    }

    return null;
  }

  void _openSavedDraft(QuizDraft draft) {
    context.pushReplacementNamed(
      RouteNames.quizQuestion,
      queryParameters: {
        'topicId': draft.topicId,
        'mode': draft.mode.routeValue,
        'source': draft.source.serverValue,
        'questionCount': draft.questionCount.toString(),
        'resumeDraft': 'true',
      },
    );
  }

  void _openNewMistakeReview({
    required String topicId,
    required int questionCount,
  }) {
    context.pushReplacementNamed(
      RouteNames.quizQuestion,
      queryParameters: {
        'topicId': topicId,
        'mode': QuizMode.practice.routeValue,
        'source': QuizSessionSource.mistakeReview.serverValue,
        'questionCount': questionCount.toString(),
        'resumeDraft': 'false',
      },
    );
  }

  void _returnToMistakeBookTopic() {
    if (context.canPop()) {
      context.pop();
      return;
    }

    final normalizedTopicId = widget.topicId.trim();

    if (normalizedTopicId.isNotEmpty) {
      context.goNamed(
        RouteNames.mistakeBookTopic,
        pathParameters: {'topicId': normalizedTopicId},
      );

      return;
    }

    context.goNamed(RouteNames.mistakeBook);
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = _errorMessage;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: _isProcessing ? null : _returnToMistakeBookTopic,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Sediakan Latihan Semula'),
      ),
      body: SafeArea(
        child: errorMessage == null
            ? const _PreparingReviewView()
            : _ReviewPreparationErrorView(
                message: errorMessage,
                onBack: _returnToMistakeBookTopic,
              ),
      ),
    );
  }
}

class _PreparingReviewView extends StatelessWidget {
  const _PreparingReviewView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Memeriksa sesi tersimpan...',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Latihan semula sedang disediakan '
              'dengan selamat.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewPreparationErrorView extends StatelessWidget {
  const _ReviewPreparationErrorView({
    required this.message,
    required this.onBack,
  });

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
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
            Text(
              'Latihan Tidak Dapat Disediakan',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Kembali ke Buku Kesilapan'),
            ),
          ],
        ),
      ),
    );
  }
}
