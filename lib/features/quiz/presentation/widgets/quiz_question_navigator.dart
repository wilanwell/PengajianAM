import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../controllers/quiz_session_state.dart';

class QuizQuestionNavigator extends StatelessWidget {
  const QuizQuestionNavigator({
    required this.state,
    required this.onQuestionSelected,
    required this.onClose,
    super.key,
  });

  final QuizSessionState state;
  final ValueChanged<int> onQuestionSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return SafeArea(
      child: SizedBox(
        height: screenHeight * 0.68,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadius.fullyRounded,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Navigasi Soalan', style: textTheme.titleLarge),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Tekan nombor untuk membuka soalan.',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                alignment: WrapAlignment.center,
                children: [
                  _NavigatorSummaryChip(
                    icon: Icons.check_circle_outline_rounded,
                    label: '${state.answeredQuestionCount} dijawab',
                    foregroundColor: AppColors.success,
                    backgroundColor: AppColors.successBackground,
                  ),
                  _NavigatorSummaryChip(
                    icon: Icons.help_outline_rounded,
                    label: '${state.unansweredQuestionCount} belum dijawab',
                    foregroundColor: AppColors.secondaryText,
                    backgroundColor: AppColors.surfaceMuted,
                  ),
                  _NavigatorSummaryChip(
                    icon: Icons.bookmark_outline_rounded,
                    label: '${state.flaggedQuestionCount} ditanda',
                    foregroundColor: AppColors.warning,
                    backgroundColor: AppColors.warningBackground,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columnCount = constraints.maxWidth < 360 ? 5 : 6;

                    return GridView.builder(
                      itemCount: state.questions.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columnCount,
                        mainAxisSpacing: AppSpacing.sm,
                        crossAxisSpacing: AppSpacing.sm,
                      ),
                      itemBuilder: (context, index) {
                        return _QuestionNumberButton(
                          key: ValueKey('quiz-question-nav-${index + 1}'),
                          questionNumber: index + 1,
                          isCurrent: state.currentQuestionIndex == index,
                          isAnswered: state.isQuestionAnswered(index),
                          isFlagged: state.isQuestionFlagged(index),
                          onTap: () {
                            onQuestionSelected(index);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const _NavigatorLegend(),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionNumberButton extends StatelessWidget {
  const _QuestionNumberButton({
    required this.questionNumber,
    required this.isCurrent,
    required this.isAnswered,
    required this.isFlagged,
    required this.onTap,
    super.key,
  });

  final int questionNumber;
  final bool isCurrent;
  final bool isAnswered;
  final bool isFlagged;
  final VoidCallback onTap;

  Color get _backgroundColor {
    if (isCurrent) {
      return AppColors.softBlue;
    }

    if (isFlagged) {
      return AppColors.warningBackground;
    }

    if (isAnswered) {
      return AppColors.successBackground;
    }

    return AppColors.surfaceMuted;
  }

  Color get _foregroundColor {
    if (isCurrent) {
      return AppColors.actionBlue;
    }

    if (isFlagged) {
      return AppColors.warning;
    }

    if (isAnswered) {
      return AppColors.success;
    }

    return AppColors.secondaryText;
  }

  Color get _borderColor {
    if (isCurrent) {
      return AppColors.actionBlue;
    }

    if (isFlagged) {
      return AppColors.warning;
    }

    if (isAnswered) {
      return AppColors.success;
    }

    return AppColors.border;
  }

  String get _semanticStatus {
    final statuses = <String>[];

    if (isCurrent) {
      statuses.add('soalan semasa');
    }

    if (isAnswered) {
      statuses.add('telah dijawab');
    } else {
      statuses.add('belum dijawab');
    }

    if (isFlagged) {
      statuses.add('ditanda');
    }

    return statuses.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: isCurrent,
      label: 'Soalan $questionNumber, $_semanticStatus',
      child: Material(
        color: _backgroundColor,
        borderRadius: AppRadius.medium,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.medium,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: AppRadius.medium,
              border: Border.all(color: _borderColor, width: isCurrent ? 2 : 1),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '$questionNumber',
                    style: textTheme.titleMedium?.copyWith(
                      color: _foregroundColor,
                    ),
                  ),
                ),
                if (isFlagged)
                  const Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(
                      Icons.bookmark_rounded,
                      size: 14,
                      color: AppColors.warning,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigatorSummaryChip extends StatelessWidget {
  const _NavigatorSummaryChip({
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
    final textTheme = Theme.of(context).textTheme;

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
          Icon(icon, size: 17, color: foregroundColor),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(color: foregroundColor),
          ),
        ],
      ),
    );
  }
}

class _NavigatorLegend extends StatelessWidget {
  const _NavigatorLegend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.center,
      children: [
        _LegendItem(color: AppColors.actionBlue, label: 'Semasa'),
        _LegendItem(color: AppColors.success, label: 'Dijawab'),
        _LegendItem(color: AppColors.warning, label: 'Ditanda'),
        _LegendItem(color: AppColors.border, label: 'Belum dijawab'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
        ),
      ],
    );
  }
}
