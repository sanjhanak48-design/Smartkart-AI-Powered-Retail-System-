import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import 'app_card.dart';

/// A tappable action tile for the Home quick-actions grid.
/// Features an icon with a tinted background, title, subtitle, and chevron.
class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: AppSpacing.iconBox,
            height: AppSpacing.iconBox,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppTextStyles.subheading),
                const SizedBox(height: AppSpacing.xxs),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 22),
        ],
      ),
    );
  }
}
