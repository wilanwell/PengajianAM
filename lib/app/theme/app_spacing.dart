import 'package:flutter/widgets.dart';

/// Central spacing tokens based on a consistent spacing scale.
///
/// Use these values instead of writing random padding and margin values
/// throughout the application.
abstract final class AppSpacing {
  static const double none = 0;
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // Common page paddings
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(
    horizontal: lg,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(md);

  static const EdgeInsets largeCardPadding = EdgeInsets.all(lg);

  const AppSpacing._();
}
