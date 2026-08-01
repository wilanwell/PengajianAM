import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';

class QuizResultMistakeReviewInfoCard extends StatelessWidget {
  const QuizResultMistakeReviewInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: AppSpacing.largeCardPadding,
      decoration: BoxDecoration(
        color: AppColors.infoBackground,
        borderRadius: AppRadius.extraLarge,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.actionBlue,
              borderRadius: AppRadius.large,
            ),
            child: const Icon(
              Icons.school_rounded,
              size: 30,
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fokus Penguasaan', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Latihan semula tidak '
                  'menambah XP atau ranking. '
                  'Jawapan betul ditandakan '
                  'sebagai Dikuasai, manakala '
                  'jawapan salah kekal Perlu '
                  'Dijawab Semula.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
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

class QuizResultEarnedXpCard extends StatelessWidget {
  const QuizResultEarnedXpCard({required this.earnedXp, super.key});

  final int earnedXp;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: AppSpacing.largeCardPadding,
      decoration: BoxDecoration(
        color: AppColors.warningBackground,
        borderRadius: AppRadius.extraLarge,
        border: Border.all(color: AppColors.accentGold.withAlpha(110)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.accentGold,
              borderRadius: AppRadius.large,
            ),
            child: const Icon(
              Icons.star_rounded,
              size: 32,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('XP Diperoleh', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Ganjaran daripada '
                  'percubaan kuiz ini.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '+$earnedXp XP',
            key: const Key('quiz-result-earned-xp'),
            style: textTheme.headlineSmall?.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class QuizResultStatCard extends StatelessWidget {
  const QuizResultStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.backgroundColor,
    super.key,
  });

  final IconData icon;

  final String label;

  final String value;

  final Color color;

  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: AppRadius.medium,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: textTheme.titleLarge),
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
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
