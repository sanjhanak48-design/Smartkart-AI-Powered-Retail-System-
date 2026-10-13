import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// A centered empty-state layout: an icon, a heading, an optional message and
/// an optional action widget. Replaces duplicated empty/placeholder views
/// across pages while allowing each caller to supply its own action button.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.action,
    this.iconSize = 44,
  });

  final String title;
  final String? message;

  /// Leading icon; defaults to a document-style placeholder when omitted.
  final IconData? icon;

  /// Optional action widget (e.g. a button) rendered below the message.
  final Widget? action;

  /// Size of the icon inside the circle.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSpacing.iconBoxLg,
              height: AppSpacing.iconBoxLg,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.receipt_long_outlined,
                size: iconSize,
                color: AppColors.primary.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTextStyles.heading,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
