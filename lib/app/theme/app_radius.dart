import 'package:flutter/widgets.dart';

/// Central corner-radius tokens.
///
/// Keeping radius values centralized ensures that buttons, cards,
/// dialogs, and input fields have a consistent appearance.
abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 999;

  static const BorderRadius small = BorderRadius.all(Radius.circular(sm));

  static const BorderRadius medium = BorderRadius.all(Radius.circular(md));

  static const BorderRadius large = BorderRadius.all(Radius.circular(lg));

  static const BorderRadius extraLarge = BorderRadius.all(Radius.circular(xl));

  static const BorderRadius fullyRounded = BorderRadius.all(
    Radius.circular(pill),
  );

  const AppRadius._();
}
