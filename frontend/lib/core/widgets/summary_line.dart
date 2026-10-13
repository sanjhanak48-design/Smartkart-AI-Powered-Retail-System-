import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// A single label/value row for summaries and receipts, with an optional
/// emphasized (grand-total) and discount (red) presentation. Consolidates the
/// repeated summary/detail line widgets across checkout, receipt and order
/// detail views.
class SummaryLine extends StatelessWidget {
  const SummaryLine({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
    this.isDiscount = false,
  });

  final String label;
  final String value;
  final bool emphasized;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: emphasized
                  ? AppTextStyles.subheading
                  : AppTextStyles.bodySmall,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            style: emphasized
                ? AppTextStyles.heading.copyWith(color: AppColors.primary)
                : AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDiscount ? AppColors.error : null,
                  ),
          ),
        ],
      ),
    );
  }
}
