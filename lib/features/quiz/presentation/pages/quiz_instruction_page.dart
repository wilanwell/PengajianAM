import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../topics/domain/entities/study_topic.dart';
import '../../../topics/presentation/controllers/topics_controller.dart';
import '../../domain/entities/quiz_draft.dart';
import '../../domain/entities/quiz_mode.dart';
import '../controllers/quiz_session_controller.dart';
import '../widgets/quiz_instruction_item.dart';

enum _ExistingDraftAction { cancel, resume, startNew }

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

    final draft = await controller.loadAvailableDraft();

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

    final action = await _showExistingDraftDialog(
      draft: draft,
      draftTopicTitle: draftTopic?.title ?? 'Topik Kuiz Tersimpan',
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _ExistingDraftAction.cancel:
        return;

      case _ExistingDraftAction.resume:
        _openQuizQuestion(
          topicId: draft.topicId,
          mode: draft.mode,
          questionCount: draft.questionCount,
          resumeDraft: true,
        );

      case _ExistingDraftAction.startNew:
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
    }
  }

  Future<_ExistingDraftAction?> _showExistingDraftDialog({
    required QuizDraft draft,
    required String draftTopicTitle,
  }) {
    final answeredCount = draft.selectedAnswers.length;

    final currentNumber = draft.currentQuestionIndex + 1;

    return showDialog<_ExistingDraftAction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.history_rounded,
            size: 44,
            color: AppColors.primary,
          ),
          title: const Text('Kuiz Belum Selesai'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terdapat sesi kuiz yang telah '
                'disimpan pada peranti ini.',
              ),
              const SizedBox(height: AppSpacing.md),
              _DraftInformationRow(label: 'Topik', value: draftTopicTitle),
              const SizedBox(height: AppSpacing.xs),
              _DraftInformationRow(label: 'Mode', value: draft.mode.label),
              const SizedBox(height: AppSpacing.xs),
              _DraftInformationRow(
                label: 'Kemajuan',
                value:
                    '$answeredCount daripada '
                    '${draft.questionCount} dijawab',
              ),
              const SizedBox(height: AppSpacing.xs),
              _DraftInformationRow(
                label: 'Kedudukan',
                value: 'Soalan $currentNumber',
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Mula Baharu akan memadamkan '
                'jawapan daripada sesi tersimpan.',
                style: TextStyle(color: AppColors.secondaryText),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(_ExistingDraftAction.cancel);
              },
              child: const Text('Batal'),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(_ExistingDraftAction.startNew);
              },
              child: const Text('Mula Baharu'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(_ExistingDraftAction.resume);
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Sambung Kuiz'),
            ),
          ],
        );
      },
    );
  }

  void _openQuizQuestion({
    required String topicId,
    required QuizMode mode,
    required int questionCount,
    required bool resumeDraft,
  }) {
    context.pushNamed(
      RouteNames.quizQuestion,
      queryParameters: {
        'topicId': topicId,
        'mode': mode.routeValue,
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

class _DraftInformationRow extends StatelessWidget {
  const _DraftInformationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
