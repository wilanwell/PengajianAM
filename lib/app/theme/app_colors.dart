import 'package:flutter/material.dart';

/// Central color tokens for the entire application.
///
/// Do not use raw hexadecimal colors directly inside pages or widgets.
/// Add or update colors through this class.
abstract final class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF123A72);
  static const Color primaryDark = Color(0xFF0B2550);
  static const Color actionBlue = Color(0xFF155EEF);
  static const Color softBlue = Color(0xFFEAF2FF);
  static const Color accentGold = Color(0xFFD6A323);

  // Neutral colors
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF2F4F7);
  static const Color border = Color(0xFFDDE3EC);

  // Text colors
  static const Color primaryText = Color(0xFF101828);
  static const Color secondaryText = Color(0xFF667085);
  static const Color disabledText = Color(0xFF98A2B3);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Semantic colors
  static const Color success = Color(0xFF168A4A);
  static const Color successBackground = Color(0xFFEAF8F0);

  static const Color warning = Color(0xFFF79009);
  static const Color warningBackground = Color(0xFFFFF4E5);

  static const Color error = Color(0xFFD92D20);
  static const Color errorBackground = Color(0xFFFFEDEC);

  static const Color info = Color(0xFF155EEF);
  static const Color infoBackground = Color(0xFFEAF2FF);

  // Leaderboard colors
  static const Color gold = Color(0xFFD6A323);
  static const Color silver = Color(0xFF98A2B3);
  static const Color bronze = Color(0xFFB76E3C);

  const AppColors._();
}
