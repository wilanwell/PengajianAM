import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/quiz_mode.dart';

class QuizModeCard extends StatelessWidget {
  const QuizModeCard({
    required this.mode,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final QuizMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  IconData get _icon {
    return switch (mode) {
      QuizMode.practice => Icons.school_rounded,
      QuizMode.exam => Icons.timer_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final borderColor = isSelected ? AppColors.actionBlue : AppColors.border;

    final backgroundColor = isSelected ? AppColors.softBlue : AppColors.surface;

    return Semantics(
      button: true,
      selected: isSelected,
      label: mode.label,
      child: Material(
        color: backgroundColor,
        borderRadius: AppRadius.large,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.large,
          child: Ink(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              borderRadius: AppRadius.large,
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.actionBlue
                            : AppColors.softBlue,
                        borderRadius: AppRadius.medium,
                      ),
                      child: Icon(
                        _icon,
                        color: isSelected
                            ? AppColors.textOnPrimary
                            : AppColors.primary,
                      ),
                    ),
                    const Spacer(),
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
                const SizedBox(height: AppSpacing.md),
                Text(mode.label, style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  mode.description,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
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
