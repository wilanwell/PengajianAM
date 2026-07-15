/// Centralized route names used for navigation.
abstract final class RouteNames {
  // Authentication
  static const String login = 'login';
  static const String register = 'register';

  // Main navigation
  static const String home = 'home';
  static const String topics = 'topics';
  static const String quiz = 'quiz';
  static const String quizInstruction = 'quiz-instruction';
  static const String leaderboard = 'leaderboard';
  static const String profile = 'profile';

  const RouteNames._();
}

/// Centralized URL paths used by GoRouter.
abstract final class RoutePaths {
  // Authentication
  static const String login = '/login';
  static const String register = '/register';

  // Main navigation
  static const String home = '/home';
  static const String topics = '/topics';
  static const String quiz = '/quiz';
  static const String quizInstruction = '/quiz/instruction';
  static const String leaderboard = '/leaderboard';
  static const String profile = '/profile';

  const RoutePaths._();
}
