import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/quiz_question.dart';

class QuizReviewCard extends StatelessWidget {
  const QuizReviewCard({
    required this.questionNumber,
    required this.question,
    required this.selectedOptionIndex,
    super.key,
  });

  final int questionNumber;
  final QuizQuestion question;
  final int? selectedOptionIndex;

  bool get _isAnswered {
    return selectedOptionIndex != null;
  }

  bool get _isCorrect {
    return question.isCorrect(selectedOptionIndex);
  }

  String _optionLabel(int index) {
    return String.fromCharCode(65 + index);
  }

  String _optionText(int? index) {
    if (index == null || index < 0 || index >= question.options.length) {
      return 'Tidak dijawab';
    }

    return question.options[index];
  }

  Color get _statusColor {
    if (!_isAnswered) {
      return AppColors.warning;
    }

    return _isCorrect ? AppColors.success : AppColors.error;
  }

  Color get _statusBackgroundColor {
    if (!_isAnswered) {
      return AppColors.warningBackground;
    }

    return _isCorrect ? AppColors.successBackground : AppColors.errorBackground;
  }

  IconData get _statusIcon {
    if (!_isAnswered) {
      return Icons.help_outline_rounded;
    }

    return _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded;
  }

  String get _statusLabel {
    if (!_isAnswered) {
      return 'Tidak dijawab';
    }

    return _isCorrect ? 'Betul' : 'Salah';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: AppRadius.medium,
                ),
                child: Text(
                  '$questionNumber',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  question.questionText,
                  style: textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _statusBackgroundColor,
                  borderRadius: AppRadius.fullyRounded,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon, size: 18, color: _statusColor),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      _statusLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: _statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _AnswerInformation(
            title: 'Jawapan Anda',
            optionLabel: selectedOptionIndex == null
                ? '—'
                : _optionLabel(selectedOptionIndex!),
            answerText: _optionText(selectedOptionIndex),
            foregroundColor: _isAnswered
                ? AppColors.primaryText
                : AppColors.warning,
            backgroundColor: _isAnswered
                ? AppColors.surfaceMuted
                : AppColors.warningBackground,
          ),
          const SizedBox(height: AppSpacing.sm),
          _AnswerInformation(
            title: 'Jawapan Betul',
            optionLabel: _optionLabel(question.correctOptionIndex),
            answerText: _optionText(question.correctOptionIndex),
            foregroundColor: AppColors.success,
            backgroundColor: AppColors.successBackground,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: AppSpacing.cardPadding,
            decoration: const BoxDecoration(
              color: AppColors.infoBackground,
              borderRadius: AppRadius.medium,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 20,
                      color: AppColors.actionBlue,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Penerangan',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.actionBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  question.explanation,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerInformation extends StatelessWidget {
  const _AnswerInformation({
    required this.title,
    required this.optionLabel,
    required this.answerText,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final String title;
  final String optionLabel;
  final String answerText;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.medium,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.fullyRounded,
              border: Border.all(color: foregroundColor),
            ),
            child: Text(
              optionLabel,
              style: textTheme.labelMedium?.copyWith(color: foregroundColor),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  answerText,
                  style: textTheme.bodyMedium?.copyWith(color: foregroundColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
