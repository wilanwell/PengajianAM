/// Centralized route names used for navigation.
///
/// Use route names instead of writing route strings directly
/// throughout pages and widgets.
abstract final class RouteNames {
  static const String login = 'login';
  static const String home = 'home';

  const RouteNames._();
}

/// Centralized URL paths used by GoRouter.
abstract final class RoutePaths {
  static const String login = '/login';
  static const String home = '/home';

  const RoutePaths._();
}
