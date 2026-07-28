import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/mistake_book_question_item.dart';

class MistakeBookQuestionCard extends StatelessWidget {
  const MistakeBookQuestionCard({
    required this.questionNumber,
    required this.item,
    super.key,
  });

  final int questionNumber;

  final MistakeBookQuestionItem item;

  Color get _statusColor {
    if (item.isMastered) {
      return AppColors.success;
    }

    if (item.isArchived) {
      return AppColors.secondaryText;
    }

    return AppColors.warning;
  }

  Color get _statusBackgroundColor {
    if (item.isMastered) {
      return AppColors.successBackground;
    }

    if (item.isArchived) {
      return AppColors.surfaceMuted;
    }

    return AppColors.warningBackground;
  }

  IconData get _statusIcon {
    if (item.isMastered) {
      return Icons.verified_rounded;
    }

    if (item.isArchived) {
      return Icons.inventory_2_outlined;
    }

    return Icons.replay_rounded;
  }

  String get _statusLabel {
    if (item.isMastered) {
      return 'Dikuasai';
    }

    if (item.isArchived) {
      return 'Diarkibkan';
    }

    return 'Perlu Dijawab Semula';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: Key('mistake-book-question-${item.questionId}'),
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
                child: Text(item.questionText, style: textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: _QuestionStatusBadge(
              icon: _statusIcon,
              label: _statusLabel,
              foregroundColor: _statusColor,
              backgroundColor: _statusBackgroundColor,
            ),
          ),
          if (item.isArchived) ...[
            const SizedBox(height: AppSpacing.sm),
            const _ArchivedQuestionNotice(),
          ],
          const SizedBox(height: AppSpacing.lg),
          _AnswerInformation(
            title: 'Jawapan Anda (ketika salah)',
            optionLabel: _optionLabel(item.selectedOptionIndex),
            answerText: item.selectedAnswerText,
            foregroundColor: AppColors.error,
            backgroundColor: AppColors.errorBackground,
          ),
          const SizedBox(height: AppSpacing.sm),
          _AnswerInformation(
            title: 'Jawapan Betul',
            optionLabel: _optionLabel(item.correctOptionIndex),
            answerText: item.correctAnswerText,
            foregroundColor: AppColors.success,
            backgroundColor: AppColors.successBackground,
          ),
          const SizedBox(height: AppSpacing.md),
          _QuestionExplanation(explanation: item.explanation),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _QuestionMetadata(
                icon: Icons.close_rounded,
                text:
                    'Salah '
                    '${item.incorrectCount} kali',
                color: AppColors.error,
              ),
              _QuestionMetadata(
                icon: Icons.fact_check_outlined,
                text:
                    'Muncul dalam latihan '
                    '${item.reviewCount} kali',
                color: AppColors.info,
              ),
              _QuestionMetadata(
                icon: Icons.schedule_rounded,
                text:
                    'Kesilapan terakhir '
                    '${_formatDate(item.lastIncorrectAt)}',
                color: AppColors.secondaryText,
              ),
              if (item.masteredAt != null)
                _QuestionMetadata(
                  icon: Icons.verified_rounded,
                  text:
                      'Dikuasai '
                      '${_formatDate(item.masteredAt!)}',
                  color: AppColors.success,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestionStatusBadge extends StatelessWidget {
  const _QuestionStatusBadge({
    required this.icon,
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final IconData icon;

  final String label;

  final Color foregroundColor;

  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.fullyRounded,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: foregroundColor),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: foregroundColor),
          ),
        ],
      ),
    );
  }
}

class _ArchivedQuestionNotice extends StatelessWidget {
  const _ArchivedQuestionNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.medium,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 20,
            color: AppColors.secondaryText,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Soalan ini disimpan sebagai rekod '
              'pembelajaran tetapi tidak lagi aktif '
              'dan tidak boleh dimasukkan ke dalam '
              'latihan semula.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
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

class _QuestionExplanation extends StatelessWidget {
  const _QuestionExplanation({required this.explanation});

  final String explanation;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
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
            explanation,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.primaryText),
          ),
        ],
      ),
    );
  }
}

class _QuestionMetadata extends StatelessWidget {
  const _QuestionMetadata({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;

  final String text;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

String _optionLabel(int index) {
  if (index >= 0 && index < 26) {
    return String.fromCharCode(65 + index);
  }

  return '${index + 1}';
}

String _formatDate(DateTime value) {
  final localValue = value.toLocal();

  final day = localValue.day.toString().padLeft(2, '0');

  final month = localValue.month.toString().padLeft(2, '0');

  return '$day/$month/${localValue.year}';
}
