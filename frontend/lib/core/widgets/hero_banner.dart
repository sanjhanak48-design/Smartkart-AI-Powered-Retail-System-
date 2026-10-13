import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import 'brand_logo_mark.dart';

/// A premium gradient hero section for the Home and Loading screens.
/// Provides a branded, visually rich top area with the SmartKart identity.
class HeroBanner extends StatelessWidget {
  const HeroBanner({
    super.key,
    this.title = 'SmartKart',
    this.subtitle,
    this.showLogo = true,
    this.logoSize = 72,
    this.iconSize = 36,
    this.child,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final bool showLogo;
  final double logoSize;
  final double iconSize;
  final Widget? child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.primaryGradient,
        ),
      ),
      child: Column(
        children: [
          if (showLogo) ...[
            BrandLogoMark(
              size: logoSize,
              iconSize: iconSize,
              background: Colors.white.withValues(alpha: 0.2),
              iconColor: Colors.white,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(title, style: AppTextStyles.heroTitle),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: AppTextStyles.heroSubtitle,
              textAlign: TextAlign.center,
            ),
          ],
          if (child != null) ...[const SizedBox(height: AppSpacing.md), child!],
        ],
      ),
    );
  }
}
