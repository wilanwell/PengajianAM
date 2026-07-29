import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';

class AccountManagementSection extends StatelessWidget {
  const AccountManagementSection({required this.onDeleteAccountTap, super.key});

  final VoidCallback onDeleteAccountTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      key: const Key('settings-account-management-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pengurusan Akaun', style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Urus tindakan kekal yang '
          'berkaitan dengan akaun anda.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText),
        ),
        const SizedBox(height: AppSpacing.sm),
        Material(
          key: const Key('settings-delete-account-tile'),
          color: AppColors.errorBackground,
          borderRadius: AppRadius.large,
          child: InkWell(
            onTap: onDeleteAccountTap,
            borderRadius: AppRadius.large,
            child: Ink(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                borderRadius: AppRadius.large,
                border: Border.all(color: AppColors.error.withAlpha(90)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(22),
                      borderRadius: AppRadius.medium,
                    ),
                    child: const Icon(
                      Icons.delete_forever_rounded,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Padam Akaun',
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Padam akaun dan semua data '
                          'secara kekal',
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
                    color: AppColors.error,
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
