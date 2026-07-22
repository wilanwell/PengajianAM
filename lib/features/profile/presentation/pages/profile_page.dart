import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/session/app_logout_controller.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/constants/app_disclaimer.dart';
import '../../../../core/constants/support_information.dart';
import '../../../progress/domain/entities/user_progress.dart';
import '../../../progress/presentation/controllers/user_progress_controller.dart';
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
  bool _isLoggingOut = false;

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

    final errorMessage = await ref
        .read(profileControllerProvider.notifier)
        .updateDisplayName(value);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            errorMessage ??
                'Nama paparan telah '
                    'dikemas kini.',
          ),
        ),
      );
  }

  void _showAboutApplication() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          title: Column(
            children: [
              Semantics(
                image: true,
                label:
                    'Logo Pengajian AM '
                    'STPM Objektif',
                child: Image.asset(
                  'assets/branding/'
                  'app_logo_full.png',
                  height: 110,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 82,
                      height: 82,
                      decoration: const BoxDecoration(
                        color: AppColors.softBlue,
                        borderRadius: AppRadius.extraLarge,
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 46,
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                SupportInformation.appName,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    SupportInformation.versionLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Aplikasi latihan objektif '
                  'untuk membantu pelajar '
                  'mengulang kaji Pengajian AM '
                  'STPM.',
                ),
                const SizedBox(height: AppSpacing.md),
                const _AboutInformationRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Developer/Penerbit',
                  value: SupportInformation.developerName,
                ),
                const SizedBox(height: AppSpacing.sm),
                const _AboutInformationRow(
                  icon: Icons.email_outlined,
                  label: 'E-mel Sokongan',
                  value: SupportInformation.supportEmail,
                  selectableValue: true,
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: AppSpacing.cardPadding,
                  decoration: const BoxDecoration(
                    color: AppColors.warningBackground,
                    borderRadius: AppRadius.medium,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              AppDisclaimer.title,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        AppDisclaimer.shortMessage,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondaryText,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                context.pushNamed(RouteNames.termsOfUse);
              },
              child: const Text('Terma Penggunaan'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                context.pushNamed(RouteNames.privacyPolicy);
              },
              child: const Text('Dasar Privasi'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log Keluar?'),
          content: const Text(
            'Anda perlu log masuk semula '
            'untuk menggunakan aplikasi.',
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

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await ref.read(appLogoutControllerProvider.notifier).logout();

      if (!mounted) {
        return;
      }

      context.goNamed(RouteNames.login);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoggingOut = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Log keluar tidak dapat '
              'diselesaikan.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UserProgress>(userProgressControllerProvider, (previous, next) {
      if (_isLoggingOut) {
        return;
      }

      final currentProfileState = ref.read(profileControllerProvider);

      if (currentProfileState.status == ProfileStatus.loading) {
        return;
      }

      final controller = ref.read(profileControllerProvider.notifier);

      controller.reset();
      controller.loadProfile();
    });

    final state = ref.watch(profileControllerProvider);

    final controller = ref.read(profileControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: switch (state.status) {
          ProfileStatus.initial ||
          ProfileStatus.loading => const _ProfileLoadingView(),

          ProfileStatus.failure => _ProfileErrorView(
            message:
                state.errorMessage ??
                'Profil tidak dapat '
                    'dimuatkan.',
            onRetry: () {
              controller.loadProfile(forceRefresh: true);
            },
          ),

          ProfileStatus.success =>
            state.profile == null
                ? _ProfileErrorView(
                    message:
                        'Maklumat profil tidak '
                        'tersedia.',
                    onRetry: () {
                      controller.loadProfile(forceRefresh: true);
                    },
                  )
                : _ProfileContent(
                    profile: state.profile!,
                    isLoggingOut: _isLoggingOut,
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
    required this.isLoggingOut,
    required this.onRefresh,
    required this.onEditName,
    required this.onShowAbout,
    required this.onLogout,
  });

  final StudentProfile profile;
  final bool isLoggingOut;

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
            icon: Icons.insights_rounded,
            title: 'Analitik Prestasi',
            subtitle:
                'Lihat prestasi dan '
                'penguasaan setiap topik',
            onTap: () {
              context.pushNamed(RouteNames.topicAnalytics);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProfileMenuTile(
            icon: Icons.history_rounded,
            title: 'Sejarah Kuiz',
            subtitle:
                'Lihat keputusan dan '
                'percubaan terdahulu',
            onTap: () {
              context.pushNamed(RouteNames.quizHistory);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProfileMenuTile(
            icon: Icons.settings_rounded,
            title: 'Tetapan',
            subtitle:
                'Tetapan kuiz dan '
                'pengurusan data tempatan',
            onTap: () {
              context.pushNamed(RouteNames.settings);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProfileMenuTile(
            icon: Icons.info_outline_rounded,
            title: 'Tentang Aplikasi',
            subtitle:
                'Maklumat versi, developer '
                'dan tujuan aplikasi',
            onTap: onShowAbout,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProfileMenuTile(
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

class _AboutInformationRow extends StatelessWidget {
  const _AboutInformationRow({
    required this.icon,
    required this.label,
    required this.value,
    this.selectableValue = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool selectableValue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.softBlue,
            borderRadius: AppRadius.medium,
          ),
          child: Icon(icon, size: 21, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              if (selectableValue)
                SelectableText(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
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
