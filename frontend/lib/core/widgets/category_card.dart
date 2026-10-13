import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// A rounded, tappable category card: a tinted circular icon/emoji tile with
/// the category name below. Reused by the Home quick-categories row and the
/// Catalog category selector.
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.label,
    required this.icon,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final active = selected || onTap == null;
    final circleColor = active
        ? (selected ? AppColors.primary : AppColors.primarySoft)
        : AppColors.surfaceMuted;
    final iconColor = selected ? Colors.white : AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: selected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
