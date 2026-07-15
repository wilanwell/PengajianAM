import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';

class QuizAnswerOption extends StatelessWidget {
  const QuizAnswerOption({
    required this.index,
    required this.text,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final int index;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  String get _optionLabel {
    return String.fromCharCode(65 + index);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Pilihan $_optionLabel, $text',
      child: Material(
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
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.actionBlue
                        : AppColors.surfaceMuted,
                    borderRadius: AppRadius.fullyRounded,
                  ),
                  child: Text(
                    _optionLabel,
                    style: textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? AppColors.textOnPrimary
                          : AppColors.primaryText,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(text, style: textTheme.bodyLarge)),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.actionBlue,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
