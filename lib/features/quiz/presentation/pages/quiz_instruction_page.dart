import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_disclaimer_card.dart';
import '../../../topics/domain/entities/study_topic.dart';
import '../../../topics/presentation/controllers/topics_controller.dart';
import '../../domain/entities/quiz_draft.dart';
import '../../domain/entities/quiz_mode.dart';
import '../../domain/entities/quiz_session_source.dart';
import '../../domain/exceptions/quiz_draft_failure.dart';
import '../controllers/quiz_session_controller.dart';
import '../widgets/existing_quiz_draft_dialog.dart';
import '../widgets/quiz_instruction_item.dart';

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
            'Sesi tersimpan tidak dapat diperiksa. '
            'Semak sambungan Internet dan cuba semula.',
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

    final draftTopic = _findTopic(topics, draft.topicId);

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
    context.pushNamed(
      RouteNames.quizQuestion,
      queryParameters: {
        'topicId': topicId,
        'mode': mode.routeValue,
        'source': source.serverValue,
        'questionCount': questionCount.toString(),
        'resumeDraft': resumeDraft.toString(),
      },
    );
  }

  StudyTopic? _findTopic(List<StudyTopic> topics, String topicId) {
    for (final topic in topics) {
      if (topic.id == topicId) {
        return topic;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final topicsState = ref.watch(topicsControllerProvider);

    final topic = _findTopic(topicsState.topics, widget.topicId);

    if (topic == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Arahan Kuiz')),
        body: const Center(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Text(
              'Topik yang dipilih tidak ditemui.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return _QuizInstructionContent(
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

class _QuizInstructionContent extends StatelessWidget {
  const _QuizInstructionContent({
    required this.topic,
    required this.mode,
    required this.questionCount,
    required this.isProcessing,
    required this.onStart,
  });

  final StudyTopic topic;
  final QuizMode mode;
  final int questionCount;
  final bool isProcessing;
  final VoidCallback onStart;

  int? get _durationMinutes {
    if (mode == QuizMode.practice) {
      return null;
    }

    return (questionCount * 1.5).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final durationLabel = _durationMinutes == null
        ? 'Tiada had masa'
        : '$_durationMinutes minit';

    return Scaffold(
      appBar: AppBar(title: const Text('Arahan Kuiz')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            Container(
              padding: AppSpacing.largeCardPadding,
              decoration: const BoxDecoration(
                color: AppColors.softBlue,
                borderRadius: AppRadius.extraLarge,
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: AppRadius.large,
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topic.code,
                          style: textTheme.labelMedium?.copyWith(
                            color: AppColors.actionBlue,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(topic.title, style: textTheme.headlineSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          mode.label,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Sila Baca Arahan', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: AppSpacing.largeCardPadding,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.large,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  QuizInstructionItem(
                    icon: Icons.quiz_outlined,
                    title: '$questionCount soalan',
                    description:
                        'Jawab semua soalan '
                        'objektif yang disediakan.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  QuizInstructionItem(
                    icon: Icons.timer_outlined,
                    title: durationLabel,
                    description: mode == QuizMode.practice
                        ? 'Anda boleh menjawab '
                              'tanpa tekanan masa.'
                        : 'Kuiz akan dihantar '
                              'apabila masa tamat.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const QuizInstructionItem(
                    icon: Icons.save_outlined,
                    title: 'Kemajuan disimpan automatik',
                    description:
                        'Kuiz boleh disambung semula '
                        'selepas anda keluar daripada '
                        'aplikasi.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const QuizInstructionItem(
                    icon: Icons.star_outline_rounded,
                    title: '1 markah setiap jawapan betul',
                    description:
                        'Tiada markah akan ditolak '
                        'untuk jawapan salah.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const QuizInstructionItem(
                    icon: Icons.fact_check_outlined,
                    title: 'Semakan selepas penghantaran',
                    description:
                        'Jawapan dan penerangan '
                        'boleh disemak selepas kuiz '
                        'dihantar.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const AppDisclaimerCard(),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: isProcessing ? null : onStart,
              icon: isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(isProcessing ? 'Memeriksa Sesi...' : 'Mula Kuiz'),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
