import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/leaderboard/presentation/pages/leaderboard_page.dart';
import '../../features/navigation/presentation/pages/main_navigation_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/quiz/domain/entities/quiz_mode.dart';
import '../../features/quiz/domain/entities/quiz_result.dart';
import '../../features/quiz/presentation/pages/quiz_hub_page.dart';
import '../../features/quiz/presentation/pages/quiz_instruction_page.dart';
import '../../features/quiz/presentation/pages/quiz_question_page.dart';
import '../../features/quiz/presentation/pages/quiz_result_page.dart';
import '../../features/quiz/presentation/pages/quiz_review_page.dart';
import '../../features/quiz/presentation/pages/quiz_history_page.dart';
import '../../features/topics/presentation/pages/topics_page.dart';
import '../../features/analytics/presentation/pages/topic_analytics_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/authentication/presentation/pages/splash_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: kDebugMode,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) {
          return const SplashPage();
        },
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) {
          return const LoginPage();
        },
      ),
      GoRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        builder: (context, state) {
          return const RegisterPage();
        },
      ),
      GoRoute(
        path: RoutePaths.quizInstruction,
        name: RouteNames.quizInstruction,
        builder: (context, state) {
          final parameters = state.uri.queryParameters;

          final topicId = parameters['topicId'] ?? '';

          final mode = quizModeFromRouteValue(parameters['mode']);

          final questionCount =
              int.tryParse(parameters['questionCount'] ?? '') ?? 10;

          return QuizInstructionPage(
            topicId: topicId,
            mode: mode,
            questionCount: questionCount,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.quizQuestion,
        name: RouteNames.quizQuestion,
        builder: (context, state) {
          final parameters = state.uri.queryParameters;

          final topicId = parameters['topicId'] ?? '';

          final mode = quizModeFromRouteValue(parameters['mode']);

          final questionCount =
              int.tryParse(parameters['questionCount'] ?? '') ?? 10;

          return QuizQuestionPage(
            topicId: topicId,
            mode: mode,
            questionCount: questionCount,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.quizResult,
        name: RouteNames.quizResult,
        builder: (context, state) {
          final result = state.extra;

          if (result is! QuizResult) {
            return const _RouteErrorPage(
              message: 'Keputusan kuiz tidak tersedia.',
            );
          }

          return QuizResultPage(result: result);
        },
      ),
      GoRoute(
        path: RoutePaths.quizReview,
        name: RouteNames.quizReview,
        builder: (context, state) {
          final result = state.extra;

          if (result is! QuizResult) {
            return const _RouteErrorPage(
              message: 'Data semakan jawapan tidak tersedia.',
            );
          }

          return QuizReviewPage(result: result);
        },
      ),
      GoRoute(
        path: RoutePaths.quizHistory,
        name: RouteNames.quizHistory,
        builder: (context, state) {
          return const QuizHistoryPage();
        },
      ),
      GoRoute(
        path: RoutePaths.topicAnalytics,
        name: RouteNames.topicAnalytics,
        builder: (context, state) {
          return const TopicAnalyticsPage();
        },
      ),
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        builder: (context, state) {
          return const SettingsPage();
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationPage(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                name: RouteNames.home,
                builder: (context, state) {
                  return const HomePage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.topics,
                name: RouteNames.topics,
                builder: (context, state) {
                  return const TopicsPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.quiz,
                name: RouteNames.quiz,
                builder: (context, state) {
                  return QuizHubPage(
                    selectedTopicId: state.uri.queryParameters['topicId'],
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.leaderboard,
                name: RouteNames.leaderboard,
                builder: (context, state) {
                  return const LeaderboardPage();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                name: RouteNames.profile,
                builder: (context, state) {
                  return const ProfilePage();
                },
              ),
            ],
          ),
        ],
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
