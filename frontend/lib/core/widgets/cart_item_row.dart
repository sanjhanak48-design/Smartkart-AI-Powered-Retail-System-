import 'package:flutter/material.dart';

import '../../features/cart/domain/models/cart.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// A read-only cart order line: item emoji/icon, name, price × qty on the left
/// with the right-aligned line total. Consolidates the identical item rows from
/// checkout, receipt and order-detail views.
class CartItemRow extends StatelessWidget {
  const CartItemRow({super.key, required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final emoji = item.product.emojiIcon;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          // Product emoji/glyph
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: emoji != null
                ? Text(emoji, style: const TextStyle(fontSize: 18))
                : Text(
                    item.product.name.isEmpty
                        ? '?'
                        : item.product.name[0].toUpperCase(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '\u20B9${item.product.price.toStringAsFixed(2)} \u00D7 ${item.quantity}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 84,
            child: Text(
              '\u20B9${item.lineTotal.toStringAsFixed(2)}',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
