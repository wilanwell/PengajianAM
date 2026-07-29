import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';

class LegalPrivacySection extends StatelessWidget {
  const LegalPrivacySection({
    required this.onTermsOfUseTap,
    required this.onPrivacyPolicyTap,
    super.key,
  });

  final VoidCallback onTermsOfUseTap;

  final VoidCallback onPrivacyPolicyTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      key: const Key('settings-legal-privacy-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Undang-undang dan Privasi', style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Baca maklumat tentang penggunaan '
          'aplikasi dan pengurusan data anda.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText),
        ),
        const SizedBox(height: AppSpacing.sm),
        _LegalNavigationTile(
          key: const Key('settings-terms-of-use-tile'),
          icon: Icons.gavel_outlined,
          title: 'Terma Penggunaan',
          description:
              'Syarat dan peraturan penggunaan '
              'aplikasi',
          onTap: onTermsOfUseTap,
        ),
        const SizedBox(height: AppSpacing.sm),
        _LegalNavigationTile(
          key: const Key('settings-privacy-policy-tile'),
          icon: Icons.privacy_tip_outlined,
          title: 'Dasar Privasi',
          description:
              'Cara data pengguna dikumpul '
              'dan dilindungi',
          onTap: onPrivacyPolicyTap,
        ),
      ],
    );
  }
}

class _LegalNavigationTile extends StatelessWidget {
  const _LegalNavigationTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    super.key,
  });

  final IconData icon;

  final String title;

  final String description;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large,
        child: Ink(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            borderRadius: AppRadius.large,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: AppRadius.medium,
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
