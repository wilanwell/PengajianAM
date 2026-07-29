import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../quiz/domain/entities/quiz_mode.dart';
import '../../domain/entities/app_settings.dart';

class QuizPreferencesSection extends StatelessWidget {
  const QuizPreferencesSection({
    required this.settings,
    required this.onModeSelected,
    required this.onQuestionCountSelected,
    super.key,
  });

  final AppSettings settings;

  final Future<void> Function(QuizMode mode) onModeSelected;

  final Future<void> Function(int questionCount) onQuestionCountSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      key: const Key('settings-quiz-preferences-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mode Kuiz Lalai', style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Mode ini akan dipilih secara '
          'automatik apabila anda membuka '
          'halaman Kuiz.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText),
        ),
        const SizedBox(height: AppSpacing.sm),
        _QuizModeOptionTile(
          key: const Key('settings-mode-practice'),
          icon: Icons.school_rounded,
          title: QuizMode.practice.label,
          description: QuizMode.practice.description,
          isSelected: settings.defaultQuizMode == QuizMode.practice,
          onTap: () {
            unawaited(onModeSelected(QuizMode.practice));
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _QuizModeOptionTile(
          key: const Key('settings-mode-exam'),
          icon: Icons.timer_rounded,
          title: QuizMode.exam.label,
          description: QuizMode.exam.description,
          isSelected: settings.defaultQuizMode == QuizMode.exam,
          onTap: () {
            unawaited(onModeSelected(QuizMode.exam));
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Jumlah Soalan Lalai', style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Jumlah soalan ini akan dipilih '
          'secara automatik untuk kuiz '
          'baharu.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final count in AppSettings.allowedQuestionCounts)
              ChoiceChip(
                key: Key('settings-question-count-$count'),
                label: Text('$count soalan'),
                selected: settings.defaultQuestionCount == count,
                onSelected: (_) {
                  unawaited(onQuestionCountSelected(count));
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _QuizModeOptionTile extends StatelessWidget {
  const _QuizModeOptionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final IconData icon;

  final String title;

  final String description;

  final bool isSelected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: isSelected ? AppColors.softBlue : AppColors.surface,
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large,
        child: Ink(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            borderRadius: AppRadius.large,
            border: Border.all(
              color: isSelected ? AppColors.actionBlue : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.actionBlue
                      : AppColors.surfaceMuted,
                  borderRadius: AppRadius.medium,
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? AppColors.textOnPrimary
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected
                    ? AppColors.actionBlue
                    : AppColors.disabledText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
