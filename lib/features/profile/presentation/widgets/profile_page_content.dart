import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../mistake_book/presentation/controllers/mistake_book_state.dart';
import '../../domain/entities/student_profile.dart';
import 'achievement_tile.dart';
import 'profile_header_card.dart';
import 'profile_mistake_book_card.dart';
import 'profile_progress_card.dart';
import 'weekly_activity_card.dart';

class ProfilePageContent extends StatelessWidget {
  const ProfilePageContent({
    required this.profile,
    required this.mistakeBookState,
    required this.isLoggingOut,
    required this.onRefresh,
    required this.onEditName,
    required this.onOpenMistakeBook,
    required this.onRetryMistakeBook,
    required this.onOpenAnalytics,
    required this.onOpenQuizHistory,
    required this.onOpenSettings,
    required this.onShowAbout,
    required this.onLogout,
    super.key,
  });

  final StudentProfile profile;

  final MistakeBookState mistakeBookState;

  final bool isLoggingOut;

  final Future<void> Function() onRefresh;

  final VoidCallback onEditName;

  final VoidCallback onOpenMistakeBook;

  final VoidCallback onRetryMistakeBook;

  final VoidCallback onOpenAnalytics;

  final VoidCallback onOpenQuizHistory;

  final VoidCallback onOpenSettings;

  final VoidCallback onShowAbout;

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final mistakeBookErrorMessage =
        mistakeBookState.status == MistakeBookStatus.failure
        ? mistakeBookState.errorMessage
        : null;

    final isMistakeBookLoading =
        mistakeBookState.status == MistakeBookStatus.initial ||
        mistakeBookState.status == MistakeBookStatus.loading;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const PageStorageKey<String>('profile-main-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenPadding,
        children: [
          ProfileHeaderCard(profile: profile, onEditName: onEditName),
          const SizedBox(height: AppSpacing.lg),
          ProfileProgressCard(profile: profile),
          const SizedBox(height: AppSpacing.lg),
          ProfileMistakeBookCard(
            snapshot: mistakeBookState.snapshot,
            isLoading: isMistakeBookLoading,
            errorMessage: mistakeBookErrorMessage,
            onOpen: onOpenMistakeBook,
            onRetry: onRetryMistakeBook,
          ),
          const SizedBox(height: AppSpacing.lg),
          WeeklyActivityCard(values: profile.weeklyAnsweredQuestions),
          const SizedBox(height: AppSpacing.lg),
          Text('Pencapaian', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Lengkapkan aktiviti pembelajaran '
            'untuk membuka lebih banyak '
            'pencapaian.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final achievement in profile.achievements) ...[
            AchievementTile(achievement: achievement),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
          Text('Akaun dan Aplikasi', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          _ProfileMenuTile(
            tileKey: const Key('profile-analytics-menu'),
            icon: Icons.insights_rounded,
            title: 'Analitik Prestasi',
            subtitle:
                'Lihat prestasi dan '
                'penguasaan setiap topik',
            onTap: onOpenAnalytics,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProfileMenuTile(
            tileKey: const Key('profile-quiz-history-menu'),
            icon: Icons.history_rounded,
            title: 'Sejarah Kuiz',
            subtitle:
                'Lihat keputusan dan '
                'percubaan terdahulu',
            onTap: onOpenQuizHistory,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProfileMenuTile(
            tileKey: const Key('profile-settings-menu'),
            icon: Icons.settings_rounded,
            title: 'Tetapan',
            subtitle:
                'Tetapan kuiz dan '
                'pengurusan data tempatan',
            onTap: onOpenSettings,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProfileMenuTile(
            tileKey: const Key('profile-about-menu'),
            icon: Icons.info_outline_rounded,
            title: 'Tentang Aplikasi',
            subtitle:
                'Maklumat versi, developer '
                'dan tujuan aplikasi',
            onTap: onShowAbout,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProfileMenuTile(
            tileKey: const Key('profile-logout-menu'),
            icon: isLoggingOut
                ? Icons.hourglass_top_rounded
                : Icons.logout_rounded,
            title: isLoggingOut ? 'Sedang Log Keluar...' : 'Log Keluar',
            subtitle: isLoggingOut
                ? 'Sila tunggu sebentar'
                : 'Keluar daripada '
                      'akaun semasa',
            foregroundColor: AppColors.error,
            onTap: isLoggingOut ? () {} : onLogout,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tileKey,
    this.foregroundColor = AppColors.primary,
  });

  final Key? tileKey;

  final IconData icon;

  final String title;

  final String subtitle;

  final VoidCallback onTap;

  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.large,
      child: InkWell(
        key: tileKey,
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
                  color: foregroundColor.withAlpha(22),
                  borderRadius: AppRadius.medium,
                ),
                child: Icon(icon, color: foregroundColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        color: foregroundColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
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
