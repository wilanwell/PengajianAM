import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../authentication/presentation/controllers/login_controller.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../leaderboard/presentation/controllers/leaderboard_controller.dart';
import '../../../quiz/presentation/controllers/quiz_session_controller.dart';
import '../../../quiz/presentation/controllers/quiz_setup_controller.dart';
import '../../../topics/presentation/controllers/topics_controller.dart';
import '../../domain/entities/student_profile.dart';
import '../controllers/profile_controller.dart';
import '../controllers/profile_state.dart';
import '../widgets/achievement_tile.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/profile_progress_card.dart';
import '../widgets/weekly_activity_card.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() {
    return _ProfilePageState();
  }
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();

    Future<void>.microtask(() {
      ref.read(profileControllerProvider.notifier).loadProfile();
    });
  }

  Future<void> _editDisplayName(StudentProfile profile) async {
    var editedName = profile.displayName;

    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Nama Paparan'),
          content: TextFormField(
            initialValue: profile.displayName,
            autofocus: true,
            maxLength: 30,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Nama paparan',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            onChanged: (newValue) {
              editedName = newValue;
            },
            onFieldSubmitted: (submittedValue) {
              Navigator.of(dialogContext).pop(submittedValue);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(editedName);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (!mounted || value == null) {
      return;
    }

    final errorMessage = ref
        .read(profileControllerProvider.notifier)
        .updateDisplayName(value);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Nama paparan telah dikemas kini.'),
        ),
      );
  }

  void _showAboutApplication() {
    showAboutDialog(
      context: context,
      applicationName: 'Pengajian AM STPM Objektif',
      applicationVersion: 'Versi pembangunan 1.0',
      applicationIcon: const CircleAvatar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        child: Icon(Icons.school_rounded),
      ),
      children: const [
        Text(
          'Aplikasi latihan objektif untuk membantu pelajar '
          'mengulang kaji Pengajian AM STPM.',
        ),
      ],
    );
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log Keluar?'),
          content: const Text(
            'Anda perlu log masuk semula untuk menggunakan '
            'aplikasi.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Log Keluar'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) {
      return;
    }

    ref.read(loginControllerProvider.notifier).reset();
    ref.read(homeControllerProvider.notifier).reset();
    ref.read(topicsControllerProvider.notifier).reset();
    ref.read(quizSetupControllerProvider.notifier).reset();
    ref.read(quizSessionControllerProvider.notifier).reset();
    ref.read(leaderboardControllerProvider.notifier).reset();
    ref.read(profileControllerProvider.notifier).reset();

    context.goNamed(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);

    final controller = ref.read(profileControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: switch (state.status) {
          ProfileStatus.initial ||
          ProfileStatus.loading => const _ProfileLoadingView(),

          ProfileStatus.failure => _ProfileErrorView(
            message: state.errorMessage ?? 'Profil tidak dapat dimuatkan.',
            onRetry: () {
              controller.loadProfile(forceRefresh: true);
            },
          ),

          ProfileStatus.success =>
            state.profile == null
                ? _ProfileErrorView(
                    message: 'Maklumat profil tidak tersedia.',
                    onRetry: () {
                      controller.loadProfile(forceRefresh: true);
                    },
                  )
                : _ProfileContent(
                    profile: state.profile!,
                    onRefresh: controller.refreshProfile,
                    onEditName: () {
                      _editDisplayName(state.profile!);
                    },
                    onShowAbout: _showAboutApplication,
                    onLogout: _logout,
                  ),
        },
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.onRefresh,
    required this.onEditName,
    required this.onShowAbout,
    required this.onLogout,
  });

  final StudentProfile profile;
  final Future<void> Function() onRefresh;
  final VoidCallback onEditName;
  final VoidCallback onShowAbout;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenPadding,
        children: [
          ProfileHeaderCard(profile: profile, onEditName: onEditName),
          const SizedBox(height: AppSpacing.lg),
          ProfileProgressCard(profile: profile),
          const SizedBox(height: AppSpacing.lg),
          WeeklyActivityCard(values: profile.weeklyAnsweredQuestions),
          const SizedBox(height: AppSpacing.lg),
          Text('Pencapaian', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Lengkapkan aktiviti pembelajaran untuk membuka '
            'lebih banyak pencapaian.',
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
            icon: Icons.info_outline_rounded,
            title: 'Tentang Aplikasi',
            subtitle: 'Maklumat versi dan tujuan aplikasi',
            onTap: onShowAbout,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProfileMenuTile(
            icon: Icons.logout_rounded,
            title: 'Log Keluar',
            subtitle: 'Keluar daripada akaun semasa',
            foregroundColor: AppColors.error,
            onTap: onLogout,
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
    this.foregroundColor = AppColors.primary,
  });

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

class _ProfileLoadingView extends StatelessWidget {
  const _ProfileLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ProfileErrorView extends StatelessWidget {
  const _ProfileErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Cuba Semula'),
            ),
          ],
        ),
      ),
    );
  }
}
