import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/session/app_authenticated_session_controller.dart';
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
    /*
     * Muatkan sesi dan paparkan Splash
     * sekurang-kurangnya 1.5 saat.
     */
    await Future.wait<void>([
      ref
          .read(authSessionControllerProvider.notifier)
          .loadSession(forceRefresh: true),
      Future<void>.delayed(const Duration(milliseconds: 1500)),
    ]);

    if (!mounted || _hasNavigated) {
      return;
    }

    final sessionState = ref.read(authSessionControllerProvider);

    if (!sessionState.isAuthenticated) {
      _hasNavigated = true;

      context.goNamed(RouteNames.login);

      return;
    }

    /*
     * Sesi lama masih sah. Kosongkan semua
     * user-scoped state sebelum Home dibuka.
     */
    final preparationError = await ref
        .read(appAuthenticatedSessionControllerProvider.notifier)
        .prepareAuthenticatedSession();

    if (!mounted || _hasNavigated) {
      return;
    }

    _hasNavigated = true;

    if (preparationError != null) {
      context.goNamed(RouteNames.login);

      return;
    }

    context.goNamed(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final screenHeight = MediaQuery.sizeOf(context).height;

    final logoSize = screenHeight < 650 ? 205.0 : 245.0;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: logoSize,
                  height: logoSize,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.extraLarge,
                  ),
                  child: Semantics(
                    image: true,
                    label:
                        'Logo Pengajian AM '
                        'STPM Objektif',
                    child: Image.asset(
                      'assets/branding/'
                      'app_logo_full.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.school_rounded,
                          size: 88,
                          color: AppColors.primary,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Belajar, Berlatih '
                  'dan Berjaya',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w600,
                  ),
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
