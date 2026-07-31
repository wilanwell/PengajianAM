import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_disclaimer_card.dart';
import '../../../topics/domain/entities/study_topic.dart';
import '../../domain/entities/quiz_mode.dart';
import 'quiz_instruction_item.dart';

class QuizInstructionContent extends StatelessWidget {
  const QuizInstructionContent({
    required this.topic,
    required this.mode,
    required this.questionCount,
    required this.isProcessing,
    required this.onStart,
    super.key,
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
          key: const Key('quiz-instruction-content'),
          padding: AppSpacing.screenPadding,
          children: [
            Container(
              key: const Key('quiz-instruction-hero-card'),
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
                          key: const Key('quiz-instruction-topic-code'),
                          style: textTheme.labelMedium?.copyWith(
                            color: AppColors.actionBlue,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          topic.title,
                          key: const Key('quiz-instruction-topic-title'),
                          style: textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          mode.label,
                          key: const Key('quiz-instruction-mode-label'),
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
              key: const Key('quiz-instruction-details-card'),
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
            const AppDisclaimerCard(key: Key('quiz-instruction-disclaimer')),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              key: const Key('quiz-instruction-start-button'),
              onPressed: isProcessing ? null : onStart,
              icon: isProcessing
                  ? const SizedBox(
                      key: Key('quiz-instruction-start-progress'),
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
