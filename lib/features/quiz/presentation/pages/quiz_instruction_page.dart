import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../topics/domain/entities/study_topic.dart';
import '../../../topics/presentation/controllers/topics_controller.dart';
import '../../domain/entities/quiz_mode.dart';
import '../widgets/quiz_instruction_item.dart';

class QuizInstructionPage extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsState = ref.watch(topicsControllerProvider);

    final topic = _findTopic(topicsState.topics, topicId);

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
      mode: mode,
      questionCount: questionCount,
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
}

class _QuizInstructionContent extends StatelessWidget {
  const _QuizInstructionContent({
    required this.topic,
    required this.mode,
    required this.questionCount,
  });

  final StudyTopic topic;
  final QuizMode mode;
  final int questionCount;

  int? get _durationMinutes {
    if (mode == QuizMode.practice) {
      return null;
    }

    return (questionCount * 1.5).ceil();
  }

  void _startQuiz(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Quiz Question Screen akan dibina pada langkah seterusnya.',
          ),
        ),
      );
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
                    description: 'Jawab semua soalan objektif yang disediakan.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  QuizInstructionItem(
                    icon: Icons.timer_outlined,
                    title: durationLabel,
                    description: mode == QuizMode.practice
                        ? 'Anda boleh menjawab tanpa tekanan masa.'
                        : 'Kuiz akan dihantar apabila masa tamat.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const QuizInstructionItem(
                    icon: Icons.star_outline_rounded,
                    title: '1 markah setiap jawapan betul',
                    description:
                        'Tiada markah akan ditolak untuk jawapan salah.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const QuizInstructionItem(
                    icon: Icons.fact_check_outlined,
                    title: 'Semakan selepas penghantaran',
                    description:
                        'Jawapan dan penerangan boleh disemak selepas kuiz dihantar.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () {
                _startQuiz(context);
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Mula Kuiz'),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
