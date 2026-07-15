import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';

class SemesterOverviewCard extends StatelessWidget {
  const SemesterOverviewCard({
    required this.semesterLabel,
    required this.currentTopic,
    required this.progress,
    required this.completedTopics,
    required this.totalTopics,
    required this.onTap,
    super.key,
  });

  final String semesterLabel;
  final String currentTopic;
  final double progress;
  final int completedTopics;
  final int totalTopics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progressPercentage = (progress * 100).round();

    return Material(
      color: AppColors.primary,
      borderRadius: AppRadius.extraLarge,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.extraLarge,
        child: Padding(
          padding: AppSpacing.largeCardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(35),
                      borderRadius: AppRadius.medium,
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          semesterLabel,
                          style: textTheme.headlineSmall?.copyWith(
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '$completedTopics daripada $totalTopics topik selesai',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.textOnPrimary,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Sambung Pembelajaran',
                style: textTheme.labelMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                currentTopic,
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: AppRadius.fullyRounded,
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  color: AppColors.accentGold,
                  backgroundColor: Colors.white24,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$progressPercentage%',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
