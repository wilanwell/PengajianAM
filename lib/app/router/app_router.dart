import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'route_names.dart';

/// Provides the application's centralized router.
///
/// Keeping GoRouter in a provider makes it easier to:
/// - add authentication redirects later;
/// - override the router during testing;
/// - observe authentication state through Riverpod.
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: RoutePaths.login,
    debugLogDiagnostics: kDebugMode,
    routes: [
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) {
          return const LoginPage();
        },
      ),
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) {
          return const HomePage();
        },
      ),
    ],
    errorBuilder: (context, state) {
      return _RouteErrorPage(message: state.error?.toString());
    },
  );

  ref.onDispose(router.dispose);

  return router;
});

class _RouteErrorPage extends StatelessWidget {
  const _RouteErrorPage({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Halaman Tidak Ditemui')),
      body: Center(
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
              Text(
                'Halaman tidak dapat dibuka.',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall,
              ),
              if (kDebugMode && message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () {
                  context.goNamed(RouteNames.login);
                },
                child: const Text('Kembali ke Log Masuk'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
