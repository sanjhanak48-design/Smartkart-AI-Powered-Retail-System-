import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// A compact quantity stepper: `− [qty] +` with circular icon buttons.
/// Used in the cart and wherever quantities are adjusted.
class AppQuantityStepper extends StatelessWidget {
  const AppQuantityStepper({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    this.enabled = true,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, VoidCallback onTap, {String? tooltip}) {
      return SizedBox(
        width: 34,
        height: 34,
        child: IconButton(
          onPressed: enabled ? onTap : null,
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          iconSize: 22,
          icon: Icon(icon, color: enabled ? AppColors.primary : null),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.remove, onDecrement, tooltip: 'Remove'),
          Container(
            width: 26,
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: AppTextStyles.subheading.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          button(Icons.add, onIncrement, tooltip: 'Add'),
        ],
      ),
    );
  }
}
