import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// A consistent, rounded surface card used across screens. Optional padding,
/// gradient background, and press feedback (via [onTap]) for a tactile,
/// premium feel.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
    this.borderColor,
    this.onTap,
    this.margin,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null
            ? (color ?? Theme.of(context).cardTheme.color)
            : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}
