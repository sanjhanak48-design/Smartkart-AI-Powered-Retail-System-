import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Reusable SmartKart logo mark (a rounded teal tile with a cart glyph).
/// Used on the Home, Auth and loading screens for consistent branding.
class BrandLogoMark extends StatelessWidget {
  const BrandLogoMark({
    super.key,
    this.size = AppSpacing.logoMarkSm,
    this.iconSize,
    this.background = AppColors.primary,
    this.iconColor = Colors.white,
  });

  final double size;
  final double? iconSize;
  final Color background;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        Icons.shopping_cart_outlined,
        size: iconSize ?? size * 0.5,
        color: iconColor,
      ),
    );
  }
}
