import 'package:flutter/material.dart';

/// SmartKart brand + UI color palette.
///
/// Warm-neutral canvas with selective premium dark green accents.
/// Presentation-only tokens. Business values and behavior are untouched.
abstract final class AppColors {
  // Primary — Refined Teal-Green (selective use)
  static const Color primary = Color(0xFF2D6B52);
  static const Color primaryDark = Color(0xFF1A4A3A);
  static const Color primaryLight = Color(0xFF6BAF9A);

  // Primary — tinted containers
  static const Color primaryFaint = Color(0x142D6B52); // primary @ ~8%
  static const Color primarySoft = Color(0x1A2D6B52); // primary @ ~10%

  // Accent — Muted Gold
  static const Color accent = Color(0xFFC49A5C);
  static const Color accentLight = Color(0xFFE2C99B);
  static const Color accentContainer = Color(0x1AC49A5C); // accent @ ~10%

  // Premium — Deep Forest Green (SELECTIVE: feature cards, hero surfaces)
  static const Color premiumDark = Color(0xFF1B3A2D);
  static const Color premiumDarkLight = Color(0xFF2A5C42);

  // Accent tones
  static const Color accentSage = Color(0xFFA8B8A0);
  static const Color accentMint = Color(0xFFD0E6D8);
  static const Color accentPeach = Color(0xFFE8C5A8);
  static const Color accentCream = Color(0xFFF5E6C8);

  // Semantic — success
  static const Color success = Color(0xFF2D6B52);
  static const Color successLight = Color(0xFFE0F2F1); // success @ ~15% fill

  // Semantic — error
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE); // error @ ~4% fill

  // Neutrals — warm canvas
  static const Color background = Color(0xFFFAF6F0);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF5F0E8);
  static const Color surfaceWarm = Color(0xFFFAF5EF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2D2A26);
  static const Color textSecondary = Color(0xFF8B8178);
  static const Color textMuted = Color(0xFFB5AFA8);
  static const Color divider = Color(0xFFE8E2DA);

  // Shadows & elevation hints
  static const Color shadow = Color(0x0D000000);
  static const Color overlay = Colors.black;

  // Placeholder icons & illustrations
  static const Color iconPlaceholder = Color(0x80757575);

  // Hero / gradient backgrounds
  static const Color heroTeal = Color(0xFF1B3A2D);

  // Badge / status colors
  static const Color badgeGreen = Color(0xFF2E7D32);
  static const Color badgeAmber = Color(0xFFC49A5C);

  // Gradient pairs
  static const List<Color> primaryGradient = [primary, primaryDark];
  static const List<Color> accentGradient = [
    Color(0xFFC49A5C),
    Color(0xFFA88542),
  ];
  static const List<Color> premiumGradient = [premiumDark, premiumDarkLight];
}
