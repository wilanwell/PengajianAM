import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../controllers/auth_session_controller.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() {
    return _SplashPageState();
  }
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    Future<void>.microtask(_resolveInitialRoute);
  }

  Future<void> _resolveInitialRoute() async {
    // Memuatkan sesi dan memastikan Splash Screen
    // dipaparkan sekurang-kurangnya 1.2 saat.
    await Future.wait<void>([
      ref
          .read(authSessionControllerProvider.notifier)
          .loadSession(forceRefresh: true),
      Future<void>.delayed(const Duration(milliseconds: 1500)),
    ]);

    if (!mounted || _hasNavigated) {
      return;
    }

    _hasNavigated = true;

    final sessionState = ref.read(authSessionControllerProvider);

    if (sessionState.isAuthenticated) {
      context.goNamed(RouteNames.home);

      return;
    }

    context.goNamed(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.extraLarge,
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 58,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Pengajian AM',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'STPM Objektif',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: AppSpacing.xl),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.accentGold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Memuatkan aplikasi...',
                  style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
