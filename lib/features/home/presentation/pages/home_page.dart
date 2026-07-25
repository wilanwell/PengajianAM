import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/session/app_logout_controller.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../progress/domain/entities/user_progress.dart';
import '../../../progress/presentation/controllers/user_progress_controller.dart';
import '../../domain/entities/home_summary.dart';
import '../controllers/home_controller.dart';
import '../controllers/home_state.dart';
import '../widgets/home_header.dart';
import '../widgets/home_stat_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/semester_overview_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();

    Future<void>.microtask(() {
      ref
          .read(homeControllerProvider.notifier)
          .loadDashboard(forceRefresh: true);
    });
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
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

  void _retryLoadingDashboard() {
    ref.read(homeControllerProvider.notifier).loadDashboard(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UserProgress>(userProgressControllerProvider, (previous, next) {
      if (_isLoggingOut) {
        return;
      }

      final currentHomeState = ref.read(homeControllerProvider);

      if (currentHomeState.status == HomeStatus.loading) {
        return;
      }

      final controller = ref.read(homeControllerProvider.notifier);

      controller.reset();

      controller.loadDashboard();
    });

    final homeState = ref.watch(homeControllerProvider);

    /*
 * Perlindungan tambahan:
 *
 * HomePage mungkin masih berada dalam
 * navigation stack apabila provider Home
 * direset atau di-invalidate.
 *
 * Dalam keadaan itu, initState tidak akan
 * dijalankan semula. Oleh itu, muatkan
 * dashboard apabila state kembali kepada
 * initial.
 */
    if (homeState.status == HomeStatus.initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _isLoggingOut) {
          return;
        }

        final latestHomeState = ref.read(homeControllerProvider);

        if (latestHomeState.status != HomeStatus.initial) {
          return;
        }

        ref
            .read(homeControllerProvider.notifier)
            .loadDashboard(forceRefresh: true);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajian AM STPM Objektif'),
        actions: [
          IconButton(
            tooltip: 'Log keluar',
            onPressed: _isLoggingOut ? null : _logout,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnPrimary,
                    ),
                  )
                : const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: switch (homeState.status) {
          HomeStatus.initial || HomeStatus.loading => const _HomeLoadingView(),

          HomeStatus.failure => _HomeErrorView(
            message:
                homeState.errorMessage ??
                'Dashboard tidak dapat '
                    'dimuatkan.',
            onRetry: _retryLoadingDashboard,
          ),

          HomeStatus.success =>
            homeState.summary == null
                ? _HomeErrorView(
                    message:
                        'Maklumat dashboard '
                        'tidak tersedia.',
                    onRetry: _retryLoadingDashboard,
                  )
                : _HomeContent(
                    summary: homeState.summary!,
                    onRefresh: ref
                        .read(homeControllerProvider.notifier)
                        .refreshDashboard,
                  ),
        },
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.summary, required this.onRefresh});

  final HomeSummary summary;

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenPadding,
        children: [
          HomeHeader(
            displayName: summary.displayName,
            semesterLabel: summary.semesterLabel,
          ),
          const SizedBox(height: AppSpacing.lg),
          SemesterOverviewCard(
            semesterLabel: summary.semesterLabel,
            currentTopic: summary.currentTopic,
            progress: summary.currentTopicProgress,
            completedTopics: summary.completedTopics,
            totalTopics: summary.totalTopics,
            onTap: () {
              context.goNamed(RouteNames.topics);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Ringkasan Prestasi', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          _PerformanceSummaryGrid(summary: summary),
          const SizedBox(height: AppSpacing.lg),
          Text('Akses Pantas', style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          const _QuickActionsGrid(),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _PerformanceSummaryGrid extends StatelessWidget {
  const _PerformanceSummaryGrid({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;

        final columnCount = constraints.maxWidth < 360 ? 1 : 2;

        final cardWidth = columnCount == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap) / 2;

        final weeklyRank = summary.weeklyRank;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: cardWidth,
              child: HomeStatCard(
                icon: Icons.quiz_outlined,
                label: 'Kuiz Disiapkan',
                value: '${summary.completedQuizzes}',
                iconColor: AppColors.actionBlue,
                iconBackgroundColor: AppColors.softBlue,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: HomeStatCard(
                icon: Icons.track_changes_rounded,
                label: 'Purata Markah',
                value: '${summary.averageScore.round()}%',
                iconColor: AppColors.success,
                iconBackgroundColor: AppColors.successBackground,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: HomeStatCard(
                icon: Icons.star_outline_rounded,
                label: 'Jumlah XP',
                value: '${summary.totalXp}',
                iconColor: AppColors.accentGold,
                iconBackgroundColor: AppColors.warningBackground,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: HomeStatCard(
                icon: Icons.emoji_events_outlined,
                label: 'Ranking Mingguan',
                value: weeklyRank == null ? 'Sertai' : '#$weeklyRank',
                iconColor: AppColors.bronze,
                iconBackgroundColor: AppColors.warningBackground,
                semanticLabel: weeklyRank == null
                    ? 'Sertai leaderboard '
                          'untuk mendapatkan '
                          'ranking mingguan'
                    : 'Buka leaderboard. '
                          'Ranking mingguan '
                          'anda ialah nombor '
                          '$weeklyRank',
                onTap: () {
                  context.goNamed(RouteNames.leaderboard);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;

        final columnCount = constraints.maxWidth < 360 ? 1 : 2;

        final cardWidth = columnCount == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap) / 2;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: cardWidth,
              child: QuickActionCard(
                icon: Icons.menu_book_rounded,
                title: 'Topik',
                description:
                    'Pilih topik '
                    'pembelajaran',
                onTap: () {
                  context.goNamed(RouteNames.topics);
                },
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: QuickActionCard(
                icon: Icons.quiz_rounded,
                title: 'Mula Kuiz',
                description: 'Uji penguasaan anda',
                onTap: () {
                  context.goNamed(RouteNames.quiz);
                },
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: QuickActionCard(
                icon: Icons.emoji_events_rounded,
                title: 'Ranking',
                description:
                    'Lihat kedudukan '
                    'mingguan',
                onTap: () {
                  context.goNamed(RouteNames.leaderboard);
                },
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: QuickActionCard(
                icon: Icons.person_rounded,
                title: 'Profil',
                description:
                    'Semak kemajuan '
                    'dan akaun',
                onTap: () {
                  context.goNamed(RouteNames.profile);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HomeLoadingView extends StatelessWidget {
  const _HomeLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _HomeErrorView extends StatelessWidget {
  const _HomeErrorView({required this.message, required this.onRetry});

  final String message;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
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
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium,
            ),
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
