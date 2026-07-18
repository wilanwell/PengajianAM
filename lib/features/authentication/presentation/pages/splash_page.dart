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
    /*
     * Memuatkan sesi dan memastikan
     * Splash Screen dipaparkan sekurang-
     * kurangnya 1.5 saat.
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

    final screenHeight = MediaQuery.of(context).size.height;

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
                /*
                 * Logo penuh mempunyai latar
                 * cerah. Container putih ini
                 * memastikan logo kekal jelas
                 * pada Splash Screen biru.
                 */
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
                    label: 'Logo Pengajian AM STPM Objektif',
                    child: Image.asset(
                      'assets/branding/app_logo_full.png',
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
                  'Belajar, Berlatih dan Berjaya',
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
