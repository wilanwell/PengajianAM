import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.displayName,
    required this.semesterLabel,
    super.key,
  });

  final String displayName;
  final String semesterLabel;

  String get _initial {
    final trimmedName = displayName.trim();

    if (trimmedName.isEmpty) {
      return 'P';
    }

    return trimmedName.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.softBlue,
          foregroundColor: AppColors.primary,
          child: Text(
            _initial,
            style: textTheme.titleLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hai, $displayName!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '$semesterLabel · Teruskan pembelajaran anda',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
