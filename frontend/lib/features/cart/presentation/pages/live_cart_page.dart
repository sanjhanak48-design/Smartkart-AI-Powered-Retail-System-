import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/cart_controller.dart';
import '../../domain/models/cart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_quantity_stepper.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';

class LiveCartPage extends ConsumerStatefulWidget {
  const LiveCartPage({super.key});

  @override
  ConsumerState<LiveCartPage> createState() => _LiveCartPageState();
}

class _LiveCartPageState extends ConsumerState<LiveCartPage> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartControllerProvider.notifier).openLiveCart();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _confirmAndClearCart() async {
    if (_busy) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text(
          'All current mock cart items will be removed from the cart.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _run(() => ref.read(cartControllerProvider.notifier).clearCart());
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartControllerProvider);
    final showClear =
        cartState is CartLoaded && cartState.cart.items.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Cart',
            onPressed: showClear && !_busy ? _confirmAndClearCart : null,
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(context, cartState)),
    );
  }

  Widget _buildBody(BuildContext context, CartState cartState) {
    if (cartState is CartLoading ||
        cartState is CartLinked ||
        cartState is CartInitial) {
      return const LoadingIndicator();
    }

    if (cartState is CartOrderPlaced) {
      return const LoadingIndicator();
    }

    if (cartState is CartError) {
      if (cartState.message.contains('No cart linked')) {
        return EmptyStateView(
          icon: Icons.remove_shopping_cart_outlined,
          title: 'No cart linked',
          message: 'Link a cart to start scanning products.',
          action: FilledButton(
            onPressed: () => context.push('/link-cart'),
            child: const Text('Link a Cart'),
          ),
        );
      }
      return ErrorView(
        message: cartState.message,
        onAction: () =>
            ref.read(cartControllerProvider.notifier).openLiveCart(),
      );
    }

    if (cartState is CartLoaded) {
      return _CartContentView(
        cart: cartState.cart,
        isBusy: _busy,
        onAdd: (productId) => _run(
          () =>
              ref.read(cartControllerProvider.notifier).simulateAdd(productId),
        ),
        onRemove: (productId) => _run(
          () => ref
              .read(cartControllerProvider.notifier)
              .simulateRemove(productId),
        ),
        onCheckout: () => context.push('/checkout'),
      );
    }

    return const SizedBox.shrink();
  }
}

class _CartContentView extends StatelessWidget {
  const _CartContentView({
    required this.cart,
    required this.isBusy,
    required this.onAdd,
    required this.onRemove,
    required this.onCheckout,
  });

  final Cart cart;
  final bool isBusy;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final VoidCallback onCheckout;

  static const _products = [
    ('milk', 'Milk'),
    ('bread', 'Bread'),
    ('rice', 'Rice'),
    ('biscuits', 'Biscuits'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ConnectionStrip(cartId: cart.cartId),
          const SizedBox(height: AppSpacing.lg),
          if (cart.items.isEmpty)
            const _EmptyCartView()
          else ...[
            _CartSummaryCard(cart: cart),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Column(
                children: [
                  for (final item in cart.items)
                    _CartItemRow(
                      item: item,
                      isBusy: isBusy,
                      onAdd: () => onAdd(item.product.id),
                      onRemove: () => onRemove(item.product.id),
                    ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: AppTextStyles.subheading),
                        Text(
                          '₹${cart.total.toStringAsFixed(2)}',
                          style: AppTextStyles.heading.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: AppSpacing.iconBox,
                      height: AppSpacing.iconBox,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: const Icon(
                        Icons.perm_media_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'RFID Simulation',
                        style: AppTextStyles.heading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'These buttons simulate products being detected by an RFID '
                  'reader. Real hardware is not connected.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final (id, name) in _products)
                      FilledButton.tonal(
                        onPressed: isBusy ? null : () => onAdd(id),
                        child: Text('+ Add $name'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: cart.items.isEmpty || isBusy ? null : onCheckout,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: const Text('Checkout'),
          ),
        ],
      ),
    );
  }
}

class _ConnectionStrip extends StatelessWidget {
  const _ConnectionStrip({required this.cartId});

  final String cartId;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.qr_code, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Linked Cart ID: $cartId',
              style: AppTextStyles.bodySmall,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Cart Connected',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartSummaryCard extends StatelessWidget {
  const _CartSummaryCard({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.primaryFaint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cart Summary', style: AppTextStyles.subheading),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Products', style: AppTextStyles.bodySmall),
              Text(
                '${cart.items.length}',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Items', style: AppTextStyles.bodySmall),
              Text(
                '${cart.totalQuantity}',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTextStyles.bodySmall),
              Text(
                '₹${cart.total.toStringAsFixed(2)}',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 40,
            color: AppColors.iconPlaceholder,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Your cart is empty', style: AppTextStyles.subheading),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Add products using the RFID Simulation buttons below.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({
    required this.item,
    required this.isBusy,
    required this.onAdd,
    required this.onRemove,
  });

  final CartItem item;
  final bool isBusy;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      child: Row(
        children: [
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
                const SizedBox(height: 2),
                Text(
                  '₹${item.product.price.toStringAsFixed(2)} each',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          AppQuantityStepper(
            quantity: item.quantity,
            enabled: !isBusy,
            onDecrement: onRemove,
            onIncrement: onAdd,
          ),
          SizedBox(
            width: 84,
            child: Text(
              '₹${item.lineTotal.toStringAsFixed(2)}',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
