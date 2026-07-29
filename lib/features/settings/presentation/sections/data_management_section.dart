import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';

class DataManagementSection extends StatelessWidget {
  const DataManagementSection({
    required this.isResetting,
    required this.onReset,
    super.key,
  });

  final bool isResetting;

  final Future<void> Function() onReset;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      key: const Key('settings-data-management-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pengurusan Data', style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Container(
          key: const Key('settings-reset-data-card'),
          padding: AppSpacing.largeCardPadding,
          decoration: BoxDecoration(
            color: AppColors.errorBackground,
            borderRadius: AppRadius.extraLarge,
            border: Border.all(color: AppColors.error.withAlpha(90)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.delete_forever_rounded,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Reset Data Pembelajaran',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Reset progress, XP, sejarah, '
                'analitik, sesi kuiz belum selesai '
                'dan tetapan lalai.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                key: const Key('settings-reset-data-button'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: isResetting
                    ? null
                    : () {
                        unawaited(onReset());
                      },
                icon: isResetting
                    ? const SizedBox(
                        key: Key('settings-reset-data-progress'),
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restart_alt_rounded),
                label: Text(
                  isResetting ? 'Sedang Reset...' : 'Reset Semua Data',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
