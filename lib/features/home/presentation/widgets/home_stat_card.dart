import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';

class HomeStatCard extends StatelessWidget {
  const HomeStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.iconBackgroundColor,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final IconData icon;

  final String label;

  final String value;

  final Color iconColor;

  final Color iconBackgroundColor;

  /// Apabila null, card hanya menjadi
  /// paparan statistik biasa.
  final VoidCallback? onTap;

  /// Penerangan tambahan untuk screen reader
  /// apabila card mempunyai tindakan.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        clipBehavior: Clip.antiAlias,
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: AppRadius.medium,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: AppSpacing.xxs),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.secondaryText,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
