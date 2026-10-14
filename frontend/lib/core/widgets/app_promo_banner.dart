import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// A soft, premium promotional banner: a tinted rounded card with an icon,
/// an optional eyebrow label, a headline and an optional call-to-action.
/// Content is provided by callers (no fabricated offers are injected).
class AppPromoBanner extends StatelessWidget {
  const AppPromoBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.icon = Icons.auto_awesome,
    this.color = AppColors.primary,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? eyebrow;
  final IconData icon;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final onColor = color.computeLuminance() > 0.6
        ? AppColors.textPrimary
        : Colors.white;
    final secondaryOnColor = onColor.withValues(alpha: 0.85);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, AppColors.primaryDark, 0.35)!],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: onColor, size: 30),
              if (eyebrow != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    eyebrow!,
                    style: AppTextStyles.label.copyWith(
                      color: onColor.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTextStyles.heading.copyWith(color: onColor)),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(color: secondaryOnColor),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: onColor,
                  foregroundColor: color,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
