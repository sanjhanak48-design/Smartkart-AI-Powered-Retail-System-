import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../payment/domain/models/payment_method.dart';
import '../../../payment/presentation/controllers/payment_controller.dart';
import '../controllers/cart_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../../core/widgets/order_summary_card.dart';

class ReceiptPage extends ConsumerStatefulWidget {
  const ReceiptPage({super.key});

  @override
  ConsumerState<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends ConsumerState<ReceiptPage> {
  bool _busy = false;

  Future<void> _done() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(cartControllerProvider.notifier).completeOrder();
      if (mounted) {
        context.go('/');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartControllerProvider);
    if (cartState is! CartOrderPlaced) {
      return Scaffold(
        appBar: AppBar(title: const Text('Receipt')),
        body: EmptyStateView(
          icon: Icons.receipt_long_outlined,
          title: 'No receipt available',
          message: 'Place an order to generate a receipt.',
          action: FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Back to Home'),
          ),
        ),
      );
    }

    final order = cartState.order;
    final paymentState = ref.watch(paymentControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 52,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text('Order placed!', style: AppTextStyles.headingLarge),
              ),
              const SizedBox(height: AppSpacing.lg),
              OrderSummaryCard(order: order),
              if (paymentState is PaymentSuccess) ...[
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Payment', style: AppTextStyles.subheading),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Payment Status: Paid (Mock)',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Method: ${paymentState.method.label}',
                          style: AppTextStyles.body,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Amount Paid: '
                          '₹${paymentState.amount.toStringAsFixed(2)}',
                          style: AppTextStyles.body,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reference: ${paymentState.referenceId}',
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ] else ...[
                const SizedBox(height: AppSpacing.md),
                const InfoBanner(
                  message:
                      'Payment details are not available for this receipt.',
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              const InfoBanner(
                message: 'Mock payment — no real charge was made.',
              ),
              const SizedBox(height: AppSpacing.lg),
              LoadingButton(
                isLoading: _busy,
                onPressed: _done,
                spinnerColor: Colors.white,
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
