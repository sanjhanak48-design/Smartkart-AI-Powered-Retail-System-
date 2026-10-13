import 'package:flutter/material.dart';

import '../../features/cart/domain/models/order.dart';
import '../../core/utils/date_format.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import 'app_card.dart';
import 'cart_item_row.dart';
import 'summary_line.dart';

/// A shared order summary card used by Receipt and Order Details pages.
/// Eliminates duplicated card patterns across those screens.
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({
    super.key,
    required this.order,
    this.showPaymentInfo = false,
    this.paymentLabel,
    this.paymentMethod,
    this.paymentAmount,
    this.paymentReference,
    this.paymentDisclaimer,
  });

  final Order order;
  final bool showPaymentInfo;
  final String? paymentLabel;
  final String? paymentMethod;
  final double? paymentAmount;
  final String? paymentReference;
  final String? paymentDisclaimer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Order metadata card
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SummaryLine(label: 'Order ID', value: order.orderId),
                const SizedBox(height: AppSpacing.xs),
                SummaryLine(
                  label: 'Date',
                  value: DateTimeFormat.date(order.createdAt),
                ),
                const SizedBox(height: AppSpacing.xs),
                SummaryLine(
                  label: 'Time',
                  value: DateTimeFormat.time(order.createdAt),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Items card
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                for (final item in order.items) CartItemRow(item: item),
                const Divider(height: 24),
                SummaryLine(label: 'Items', value: '${order.totalQuantity}'),
                const SizedBox(height: AppSpacing.sm),
                if (order.discount > 0) ...[
                  SummaryLine(
                    label: 'Store Reward Discount',
                    value: '\u2212\u20B9${order.discount.toStringAsFixed(2)}',
                    isDiscount: true,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                SummaryLine(
                  label: 'Total',
                  value: '\u20B9${order.totalAfterDiscount.toStringAsFixed(2)}',
                  emphasized: true,
                ),
              ],
            ),
          ),
        ),
        // Payment info card
        if (showPaymentInfo && paymentMethod != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.payment_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        paymentLabel ?? 'Payment',
                        style: AppTextStyles.subheading,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SummaryLine(label: 'Status', value: 'Paid (Mock)'),
                  const SizedBox(height: AppSpacing.xs),
                  SummaryLine(label: 'Method', value: paymentMethod!),
                  if (paymentAmount != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    SummaryLine(
                      label: 'Amount Paid',
                      value: '\u20B9${paymentAmount!.toStringAsFixed(2)}',
                    ),
                  ],
                  if (paymentReference != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    SummaryLine(label: 'Reference', value: paymentReference!),
                  ],
                ],
              ),
            ),
          ),
        ],
        if (paymentDisclaimer != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.accentLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.accent),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    paymentDisclaimer!,
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
