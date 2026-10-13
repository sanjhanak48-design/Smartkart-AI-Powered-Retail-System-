import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/models/payment_method.dart';
import '../controllers/payment_controller.dart';

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  PaymentMethod _method = PaymentMethod.upi;
  bool _placingOrder = false;
  String? _orderError;

  Future<void> _pay() async {
    setState(() => _orderError = null);
    final payable = ref.read(cartControllerProvider.notifier).checkoutTotal;
    if (payable <= 0) {
      return;
    }

    final paid = await ref
        .read(paymentControllerProvider.notifier)
        .pay(amount: payable, method: _method);
    if (!mounted) {
      return;
    }
    if (!paid) {
      return; // PaymentFailure is surfaced through the payment state.
    }
    await _placeOrder();
  }

  /// Retries only the order placement when the payment already succeeded,
  /// so a retry never issues a duplicate payment.
  Future<void> _retry() async {
    if (ref.read(paymentControllerProvider) is PaymentSuccess) {
      await _placeOrder();
    } else {
      await _pay();
    }
  }

  Future<void> _placeOrder() async {
    setState(() {
      _orderError = null;
      _placingOrder = true;
    });
    await ref.read(cartControllerProvider.notifier).checkout();
    if (!mounted) {
      return;
    }
    if (ref.read(cartControllerProvider) is! CartOrderPlaced) {
      setState(() {
        _placingOrder = false;
        _orderError = 'Your order could not be placed. Please try again.';
      });
      return;
    }
    setState(() => _placingOrder = false);
    context.pushReplacement('/receipt');
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartControllerProvider);
    final paymentState = ref.watch(paymentControllerProvider);

    if (cartState is! CartLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: const LoadingIndicator(),
      );
    }

    final payable = ref.read(cartControllerProvider.notifier).checkoutTotal;
    final processing = paymentState is PaymentProcessing || _placingOrder;
    final error = paymentState is PaymentFailure
        ? paymentState.message
        : _orderError;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
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
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primarySoft, AppColors.surface],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.primaryFaint),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount Payable', style: AppTextStyles.label),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '₹${payable.toStringAsFixed(2)}',
                      style: AppTextStyles.priceLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Payment Method', style: AppTextStyles.subheading),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Column(
                    children: [
                      _PaymentMethodTile(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'UPI',
                        subtitle: 'Google Pay, PhonePe, Paytm',
                        selected: _method == PaymentMethod.upi,
                        onTap: processing
                            ? null
                            : () => setState(() => _method = PaymentMethod.upi),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _PaymentMethodTile(
                        icon: Icons.credit_card,
                        title: 'Card',
                        subtitle: 'Credit or Debit Card',
                        selected: _method == PaymentMethod.card,
                        onTap: processing
                            ? null
                            : () =>
                                  setState(() => _method = PaymentMethod.card),
                      ),
                    ],
                  ),
                ),
              ),
              if (paymentState is PaymentProcessing) ...[
                const SizedBox(height: AppSpacing.lg),
                const _ProgressLine(label: 'Processing payment...'),
              ],
              if (_placingOrder) ...[
                const SizedBox(height: AppSpacing.lg),
                const _ProgressLine(label: 'Placing your order...'),
              ],
              if (error != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _PaymentErrorBox(
                  message: error,
                  onRetry: processing ? null : _retry,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              const InfoBanner(
                message: 'Simulated payment — no real money will be charged.',
              ),
              const SizedBox(height: AppSpacing.lg),
              LoadingButton(
                isLoading: processing,
                onPressed: _pay,
                child: Text('Pay ₹${payable.toStringAsFixed(2)}'),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: processing ? null : () => context.pop(),
                  child: const Text('Cancel Payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(icon, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTextStyles.body),
      ],
    );
  }
}

class _PaymentErrorBox extends StatelessWidget {
  const _PaymentErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
