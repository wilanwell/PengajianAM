import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../progress/domain/entities/user_progress.dart';
import '../../../progress/presentation/controllers/user_progress_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/home_state.dart';
import '../coordinators/home_load_coordinator.dart';
import '../coordinators/home_session_coordinator.dart';
import '../widgets/home_error_view.dart';
import '../widgets/home_loading_view.dart';
import '../widgets/home_page_content.dart';

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
      return ref.read(homeLoadCoordinatorProvider).loadInitial();
    });
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    final errorMessage = await ref
        .read(homeSessionCoordinatorProvider)
        .logout();

    if (!mounted) {
      return;
    }

    if (errorMessage == null) {
      context.goNamed(RouteNames.login);

      return;
    }

    setState(() {
      _isLoggingOut = false;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(errorMessage)));
  }

  void _retryLoadingDashboard() {
    unawaited(ref.read(homeLoadCoordinatorProvider).retryDashboard());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UserProgress>(userProgressControllerProvider, (previous, next) {
      unawaited(
        ref
            .read(homeLoadCoordinatorProvider)
            .synchronizeAfterProgressChange(isLoggingOut: _isLoggingOut),
      );
    });

    final homeState = ref.watch(homeControllerProvider);

    /*
     * HomePage mungkin masih berada dalam
     * navigation stack apabila provider Home
     * direset atau di-invalidate.
     *
     * Dalam keadaan itu, initState tidak akan
     * dijalankan semula.
     */
    if (homeState.status == HomeStatus.initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        unawaited(
          ref
              .read(homeLoadCoordinatorProvider)
              .ensureLoadedAfterInvalidation(isLoggingOut: _isLoggingOut),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajian AM STPM Objektif'),
        actions: [
          IconButton(
            key: const Key('home-logout-button'),
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
          HomeStatus.initial || HomeStatus.loading => const HomeLoadingView(),

          HomeStatus.failure => HomeErrorView(
            message:
                homeState.errorMessage ??
                'Dashboard tidak dapat '
                    'dimuatkan.',
            onRetry: _retryLoadingDashboard,
          ),

          HomeStatus.success =>
            homeState.summary == null
                ? HomeErrorView(
                    message:
                        'Maklumat dashboard '
                        'tidak tersedia.',
                    onRetry: _retryLoadingDashboard,
                  )
                : HomePageContent(
                    summary: homeState.summary!,
                    onRefresh: ref
                        .read(homeLoadCoordinatorProvider)
                        .refreshDashboard,
                    onOpenTopics: () {
                      context.goNamed(RouteNames.topics);
                    },
                    onStartQuiz: () {
                      context.goNamed(RouteNames.quiz);
                    },
                    onOpenLeaderboard: () {
                      context.goNamed(RouteNames.leaderboard);
                    },
                    onOpenMistakeBook: () {
                      context.pushNamed(RouteNames.mistakeBook);
                    },
                  ),
        },
      ),
    );
  }
}
