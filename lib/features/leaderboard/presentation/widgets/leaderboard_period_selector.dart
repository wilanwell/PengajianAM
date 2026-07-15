import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/leaderboard_period.dart';

class LeaderboardPeriodSelector extends StatelessWidget {
  const LeaderboardPeriodSelector({
    required this.selectedPeriod,
    required this.onPeriodSelected,
    super.key,
  });

  final LeaderboardPeriod selectedPeriod;
  final ValueChanged<LeaderboardPeriod> onPeriodSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: AppRadius.large,
      ),
      child: Row(
        children: [
          for (final period in LeaderboardPeriod.values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxs),
                child: Material(
                  color: selectedPeriod == period
                      ? AppColors.surface
                      : Colors.transparent,
                  borderRadius: AppRadius.medium,
                  child: InkWell(
                    onTap: () {
                      onPeriodSelected(period);
                    },
                    borderRadius: AppRadius.medium,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Text(
                        period.label,
                        textAlign: TextAlign.center,
                        style: textTheme.labelMedium?.copyWith(
                          color: selectedPeriod == period
                              ? AppColors.primary
                              : AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
