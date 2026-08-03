import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';

class QuizQuestionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const QuizQuestionAppBar({
    required this.title,
    required this.showQuestionNavigator,
    required this.unansweredQuestionCount,
    required this.onOpenQuestionNavigator,
    this.remainingTimeLabel,
    super.key,
  });

  final String title;
  final bool showQuestionNavigator;
  final int unansweredQuestionCount;
  final String? remainingTimeLabel;
  final VoidCallback onOpenQuestionNavigator;

  @override
  Size get preferredSize {
    return const Size.fromHeight(kToolbarHeight);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      key: const Key('quiz-question-app-bar'),
      title: Text(title, key: const Key('quiz-question-app-bar-title')),
      actions: [
        if (showQuestionNavigator)
          IconButton(
            key: const Key('quiz-question-navigator-button'),
            tooltip: 'Navigasi soalan',
            onPressed: onOpenQuestionNavigator,
            icon: Badge(
              key: const Key('quiz-question-unanswered-badge'),
              isLabelVisible: unansweredQuestionCount > 0,
              label: Text('$unansweredQuestionCount'),
              child: const Icon(Icons.grid_view_rounded),
            ),
          ),
        if (remainingTimeLabel != null)
          Padding(
            key: const Key('quiz-question-timer'),
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.warningBackground,
                  borderRadius: AppRadius.fullyRounded,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 18,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      remainingTimeLabel!,
                      key: const Key('quiz-question-timer-label'),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
