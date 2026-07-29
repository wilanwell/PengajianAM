import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../leaderboard/presentation/controllers/leaderboard_preference_state.dart';

class LeaderboardPrivacySection extends StatelessWidget {
  const LeaderboardPrivacySection({
    required this.state,
    required this.onChanged,
    required this.onRetry,
    super.key,
  });

  final LeaderboardPreferenceState state;

  final Future<void> Function(bool optIn) onChanged;

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      key: const Key('settings-leaderboard-privacy-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Privasi Leaderboard', style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Pilih sama ada XP tempoh semasa '
          'boleh digunakan untuk menentukan '
          'ranking anda.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText),
        ),
        const SizedBox(height: AppSpacing.sm),
        _LeaderboardParticipationCard(
          state: state,
          onChanged: onChanged,
          onRetry: onRetry,
        ),
      ],
    );
  }
}

class _LeaderboardParticipationCard extends StatelessWidget {
  const _LeaderboardParticipationCard({
    required this.state,
    required this.onChanged,
    required this.onRetry,
  });

  final LeaderboardPreferenceState state;

  final Future<void> Function(bool optIn) onChanged;

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final isLoading =
        state.status == LeaderboardPreferenceStatus.initial ||
        state.status == LeaderboardPreferenceStatus.loading;

    final hasFailure = state.status == LeaderboardPreferenceStatus.failure;

    final isOptedIn = state.isOptedIn;

    final consentVersion =
        state.preference?.consentVersion ??
        state.preference?.requiredConsentVersion;

    return Container(
      key: const Key('settings-leaderboard-participation-card'),
      padding: AppSpacing.largeCardPadding,
      decoration: BoxDecoration(
        color: isOptedIn ? AppColors.softBlue : AppColors.surface,
        borderRadius: AppRadius.extraLarge,
        border: Border.all(
          color: isOptedIn ? AppColors.actionBlue : AppColors.border,
          width: isOptedIn ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isOptedIn
                      ? AppColors.actionBlue
                      : AppColors.surfaceMuted,
                  borderRadius: AppRadius.medium,
                ),
                child: Icon(
                  Icons.emoji_events_outlined,
                  color: isOptedIn
                      ? AppColors.textOnPrimary
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sertai Leaderboard', style: textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      isOptedIn ? 'Penyertaan aktif' : 'Penyertaan tidak aktif',
                      key: const Key('settings-leaderboard-status'),
                      style: textTheme.bodySmall?.copyWith(
                        color: isOptedIn
                            ? AppColors.actionBlue
                            : AppColors.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (isLoading || state.isUpdating)
                const SizedBox(
                  key: Key('settings-leaderboard-progress'),
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              else
                Switch.adaptive(
                  key: const Key('settings-leaderboard-switch'),
                  value: isOptedIn,
                  onChanged: state.canUpdate
                      ? (value) {
                          unawaited(onChanged(value));
                        }
                      : null,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isOptedIn
                ? 'XP mingguan dan bulanan '
                      'anda digunakan untuk '
                      'menentukan ranking. '
                      'Pengguna lain hanya '
                      'melihat nama samaran.'
                : 'Anda tidak muncul dalam '
                      'ranking. XP, progress '
                      'dan sejarah pembelajaran '
                      'anda masih disimpan.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
              height: 1.4,
            ),
          ),
          if (isOptedIn && consentVersion != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Persetujuan versi '
                    '$consentVersion',
                    key: const Key('settings-leaderboard-consent-version'),
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (hasFailure) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              key: const Key('settings-leaderboard-error'),
              width: double.infinity,
              padding: AppSpacing.cardPadding,
              decoration: const BoxDecoration(
                color: AppColors.errorBackground,
                borderRadius: AppRadius.medium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.errorMessage ??
                        'Tetapan leaderboard '
                            'tidak dapat dimuatkan.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    key: const Key('settings-leaderboard-retry'),
                    onPressed: () {
                      unawaited(onRetry());
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Cuba Semula'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
