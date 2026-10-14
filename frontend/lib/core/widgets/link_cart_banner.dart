import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// A banner prompting the user to link a cart before browsing. Shared by the
/// catalog and recommendations pages.
class LinkCartBanner extends StatelessWidget {
  const LinkCartBanner({
    super.key,
    required this.message,
    required this.onLinkCart,
  });

  final String message;
  final VoidCallback onLinkCart;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accentLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.link,
                  size: 18,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(message, style: AppTextStyles.bodySmall)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonal(
            onPressed: onLinkCart,
            child: const Text('Link Cart'),
          ),
        ],
      ),
    );
  }
}
