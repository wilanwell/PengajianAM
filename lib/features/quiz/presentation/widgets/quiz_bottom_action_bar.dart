import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../controllers/quiz_session_state.dart';

class QuizBottomActionBar extends StatelessWidget {
  const QuizBottomActionBar({
    required this.state,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleFlag,
    required this.onSubmit,
    super.key,
  });

  final QuizSessionState state;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToggleFlag;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('quiz-bottom-action-bar'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScaler = MediaQuery.textScalerOf(context);

            final usesLargeText = textScaler.scale(16) > 18;

            final isCompact = constraints.maxWidth < 340 || usesLargeText;

            if (isCompact) {
              return _buildCompactActions();
            }

            return _buildRegularActions();
          },
        ),
      ),
    );
  }

  Widget _buildCompactActions() {
    final nextTooltip = state.isLastQuestion
        ? 'Hantar jawapan'
        : 'Soalan seterusnya';

    return Row(
      key: const Key('quiz-bottom-actions-compact'),
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: 'Soalan sebelumnya',
            child: Tooltip(
              message: 'Soalan sebelumnya',
              child: OutlinedButton(
                key: const Key('quiz-previous-button'),
                onPressed: state.canGoPrevious ? onPrevious : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 24),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 56,
          height: 56,
          child: Semantics(
            button: true,
            label: state.isCurrentQuestionFlagged
                ? 'Buang tanda soalan'
                : 'Tandakan soalan',
            child: IconButton.filledTonal(
              key: const Key('quiz-flag-button'),
              tooltip: state.isCurrentQuestionFlagged
                  ? 'Buang tanda soalan'
                  : 'Tandakan soalan',
              onPressed: onToggleFlag,
              iconSize: 24,
              icon: Icon(
                state.isCurrentQuestionFlagged
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Semantics(
            button: true,
            label: nextTooltip,
            child: Tooltip(
              message: nextTooltip,
              child: FilledButton(
                key: const Key('quiz-next-button'),
                onPressed: state.isLastQuestion ? onSubmit : onNext,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  padding: EdgeInsets.zero,
                ),
                child: Icon(
                  state.isLastQuestion
                      ? Icons.send_rounded
                      : Icons.arrow_forward_rounded,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegularActions() {
    return Row(
      key: const Key('quiz-bottom-actions-regular'),
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('quiz-previous-button'),
            onPressed: state.canGoPrevious ? onPrevious : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            label: const Text(
              'Sebelum',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 56,
          height: 56,
          child: Semantics(
            button: true,
            label: state.isCurrentQuestionFlagged
                ? 'Buang tanda soalan'
                : 'Tandakan soalan',
            child: IconButton.filledTonal(
              key: const Key('quiz-flag-button'),
              tooltip: state.isCurrentQuestionFlagged
                  ? 'Buang tanda soalan'
                  : 'Tandakan soalan',
              onPressed: onToggleFlag,
              iconSize: 24,
              icon: Icon(
                state.isCurrentQuestionFlagged
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: FilledButton.icon(
            key: const Key('quiz-next-button'),
            onPressed: state.isLastQuestion ? onSubmit : onNext,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
            icon: Icon(
              state.isLastQuestion
                  ? Icons.send_rounded
                  : Icons.arrow_forward_rounded,
              size: 20,
            ),
            label: Text(
              state.isLastQuestion ? 'Hantar' : 'Seterusnya',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
            ),
          ),
        ),
      ],
    );
  }
}
