import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../topics/domain/entities/study_topic.dart';
import '../../domain/entities/quiz_mode.dart';
import '../controllers/quiz_setup_state.dart';
import 'quiz_mode_card.dart';

class QuizHubContent extends StatelessWidget {
  const QuizHubContent({
    required this.topics,
    required this.setupState,
    required this.questionCounts,
    required this.onTopicChanged,
    required this.onModeChanged,
    required this.onQuestionCountChanged,
    required this.onContinue,
    super.key,
  });

  final List<StudyTopic> topics;

  final QuizSetupState setupState;

  final List<int> questionCounts;

  final ValueChanged<String?> onTopicChanged;

  final ValueChanged<QuizMode> onModeChanged;

  final ValueChanged<int> onQuestionCountChanged;

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final topicIds = topics.map((topic) => topic.id).toSet();

    final selectedTopicId = topicIds.contains(setupState.selectedTopicId)
        ? setupState.selectedTopicId
        : null;

    final selectedTopic = selectedTopicId == null
        ? null
        : topics.firstWhere((topic) {
            return topic.id == selectedTopicId;
          });

    return ListView(
      key: const PageStorageKey<String>('quiz-hub-content'),
      padding: AppSpacing.screenPadding,
      children: [
        Container(
          key: const Key('quiz-hub-hero-card'),
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
                  Icons.quiz_rounded,
                  color: AppColors.textOnPrimary,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sediakan Kuiz',
                      style: textTheme.headlineSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Pilih topik dan '
                      'tetapan kuiz anda.',
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
        Text('Pilih Topik', style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          key: const Key('quiz-hub-topic-dropdown'),
          initialValue: selectedTopicId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Topik Semester 1',
            prefixIcon: Icon(Icons.menu_book_outlined),
          ),
          hint: const Text('Pilih satu topik'),
          items: [
            for (final topic in topics)
              DropdownMenuItem<String>(
                value: topic.id,
                child: Text(
                  '${topic.code} · '
                  '${topic.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onTopicChanged,
        ),
        if (selectedTopic != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            selectedTopic.description,
            key: const Key('quiz-hub-selected-topic-description'),
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text('Pilih Mode', style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = AppSpacing.sm;

            final cardWidth = constraints.maxWidth < 420
                ? constraints.maxWidth
                : (constraints.maxWidth - gap) / 2;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: QuizModeCard(
                    key: const Key('quiz-hub-mode-practice'),
                    mode: QuizMode.practice,
                    isSelected: setupState.mode == QuizMode.practice,
                    onTap: () {
                      onModeChanged(QuizMode.practice);
                    },
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: QuizModeCard(
                    key: const Key('quiz-hub-mode-exam'),
                    mode: QuizMode.exam,
                    isSelected: setupState.mode == QuizMode.exam,
                    onTap: () {
                      onModeChanged(QuizMode.exam);
                    },
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Jumlah Soalan', style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final count in questionCounts)
              ChoiceChip(
                key: Key('quiz-hub-count-$count'),
                label: Text('$count soalan'),
                selected: setupState.questionCount == count,
                onSelected: (_) {
                  onQuestionCountChanged(count);
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _QuizSetupSummaryCard(
          setupState: setupState,
          selectedTopic: selectedTopic,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          key: const Key('quiz-hub-continue-button'),
          onPressed: selectedTopicId != null ? onContinue : null,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('Lihat Arahan Kuiz'),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _QuizSetupSummaryCard extends StatelessWidget {
  const _QuizSetupSummaryCard({
    required this.setupState,
    required this.selectedTopic,
  });

  final QuizSetupState setupState;

  final StudyTopic? selectedTopic;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final durationLabel = setupState.durationMinutes == null
        ? 'Tiada had masa'
        : '${setupState.durationMinutes} minit';

    return Container(
      key: const Key('quiz-hub-summary-card'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ringkasan Tetapan', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _SummaryRow(
            key: const Key('quiz-hub-summary-topic'),
            icon: Icons.menu_book_outlined,
            label: 'Topik',
            value: selectedTopic?.title ?? 'Belum dipilih',
          ),
          const Divider(height: AppSpacing.lg),
          _SummaryRow(
            key: const Key('quiz-hub-summary-mode'),
            icon: Icons.school_outlined,
            label: 'Mode',
            value: setupState.mode.label,
          ),
          const Divider(height: AppSpacing.lg),
          _SummaryRow(
            key: const Key('quiz-hub-summary-question-count'),
            icon: Icons.quiz_outlined,
            label: 'Soalan',
            value:
                '${setupState.questionCount} '
                'soalan',
          ),
          const Divider(height: AppSpacing.lg),
          _SummaryRow(
            key: const Key('quiz-hub-summary-duration'),
            icon: Icons.timer_outlined,
            label: 'Masa',
            value: durationLabel,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;

  final String label;

  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}
