import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/cart_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';

class LinkCartPage extends ConsumerStatefulWidget {
  const LinkCartPage({super.key});

  @override
  ConsumerState<LinkCartPage> createState() => _LinkCartPageState();
}

class _LinkCartPageState extends ConsumerState<LinkCartPage> {
  final _cartIdController = TextEditingController();

  @override
  void dispose() {
    _cartIdController.dispose();
    super.dispose();
  }

  void _linkCart() {
    final cartId = _cartIdController.text;
    ref.read(cartControllerProvider.notifier).linkCart(cartId);
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartControllerProvider);
    final linking = cartState is CartLinking;

    String? errorMessage;
    if (cartState is CartError) {
      errorMessage = cartState.message;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Link Cart')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text(
                'Link a shopping cart to start scanning. '
                'Scan the QR code on the cart or enter its ID below.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                onTap: () => context.push('/scan-cart'),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner,
                        size: 44,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('QR Scanner', style: AppTextStyles.heading),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Open the camera to scan the QR code on your cart.',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _cartIdController,
                enabled: !linking,
                decoration: const InputDecoration(
                  labelText: 'Cart ID',
                  hintText: 'Enter Cart ID',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: linking ? null : _linkCart,
                child: linking
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Link Cart'),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Text(
                    errorMessage,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
              if (cartState is CartLinked) ...[
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  color: AppColors.primarySoft,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 40,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Cart linked successfully!',
                        style: AppTextStyles.heading,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Cart ID: ${cartState.cart.cartId}',
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: () => context.push('/live-cart'),
                        icon: const Icon(Icons.shopping_cart_checkout),
                        label: const Text('Open Live Cart'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
