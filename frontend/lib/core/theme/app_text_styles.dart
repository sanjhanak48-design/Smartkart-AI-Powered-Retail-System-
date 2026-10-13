import 'package:flutter/material.dart';

import 'app_colors.dart';

/// SmartKart typography hierarchy.
///
/// Compact premium density. Existing style names preserved so all screens
/// that reference them keep working.
abstract final class AppTextStyles {
  // Display / hero — compact but strong
  static const TextStyle display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.6,
    height: 1.15,
  );

  static const TextStyle headingLarge = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle heading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle label = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.accent,
    letterSpacing: 0.6,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
  );

  static const TextStyle error = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.error,
    height: 1.5,
  );

  static const TextStyle errorSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.error,
  );

  static const TextStyle chip = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static const TextStyle price = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static const TextStyle priceLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
    height: 1.2,
  );

  // Hero typography — white text for gradient backgrounds
  static const TextStyle heroTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle heroSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Colors.white70,
    height: 1.4,
  );

  // Stat typography — compact numeric callouts
  static const TextStyle statLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
  );

  static const TextStyle statValue = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // Section number — large numeric callouts
  static const TextStyle sectionNumber = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
    height: 1.2,
  );

  // Section label — small uppercase section labels
  static const TextStyle sectionLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    letterSpacing: 1.0,
  );
}
