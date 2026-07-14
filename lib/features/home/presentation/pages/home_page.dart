import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../authentication/presentation/controllers/login_controller.dart';

/// Temporary home page used to verify routing.
///
/// This page will later be expanded into the complete home dashboard
/// using smaller reusable widgets.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajian AM STPM Objektif'),
        actions: [
          IconButton(
            tooltip: 'Log keluar',
            onPressed: () {
              // Clear the current login form and authentication state.
              ref.read(loginControllerProvider.notifier).reset();

              // Return to the login page.
              context.goNamed(RouteNames.login);
            },
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            Text('Hai, Pelajar!', style: textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Asas aplikasi telah berjaya disediakan.',
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Main semester card
            Container(
              padding: AppSpacing.largeCardPadding,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.extraLarge,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.school_rounded,
                    color: AppColors.textOnPrimary,
                    size: 40,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Semester 1',
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Topik, kuiz, kemajuan dan leaderboard akan '
                    'ditambah secara modular.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Navigation success information card
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.large,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.successBackground,
                      borderRadius: AppRadius.medium,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Navigation berjaya',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Login → Home telah berfungsi.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
