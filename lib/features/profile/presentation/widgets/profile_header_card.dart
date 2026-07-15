import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/student_profile.dart';

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    required this.profile,
    required this.onEditName,
    super.key,
  });

  final StudentProfile profile;
  final VoidCallback onEditName;

  String get _joinedLabel {
    const monthNames = [
      'Januari',
      'Februari',
      'Mac',
      'April',
      'Mei',
      'Jun',
      'Julai',
      'Ogos',
      'September',
      'Oktober',
      'November',
      'Disember',
    ];

    final month = monthNames[profile.joinedAt.month - 1];

    return 'Sertai sejak $month ${profile.joinedAt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: AppSpacing.largeCardPadding,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.extraLarge,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.accentGold,
            foregroundColor: AppColors.primaryText,
            child: Text(
              profile.initials,
              style: textTheme.headlineMedium?.copyWith(
                color: AppColors.primaryText,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            profile.displayName,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            profile.email,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${profile.semesterLabel} · $_joinedLabel',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: onEditName,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textOnPrimary,
              backgroundColor: Colors.white.withAlpha(28),
            ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Nama Paparan'),
          ),
        ],
      ),
    );
  }
}
