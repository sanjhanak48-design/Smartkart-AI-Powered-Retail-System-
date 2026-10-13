import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../rewards/presentation/controllers/rewards_controller.dart';
import '../controllers/cart_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/cart_item_row.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/summary_line.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  bool _busy = false;
  bool _rewardApplied = false;

  @override
  void initState() {
    super.initState();
    _rewardApplied =
        ref.read(cartControllerProvider.notifier).rewardDiscount > 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rewardsState = ref.read(rewardsControllerProvider);
      if (rewardsState is! RewardsLoaded) {
        ref.read(rewardsControllerProvider.notifier).loadRewards();
      }
    });
  }

  Future<void> _applyReward() async {
    if (_busy) {
      return;
    }
    final applied = await ref
        .read(cartControllerProvider.notifier)
        .applyStoreReward();
    if (mounted) {
      setState(() => _rewardApplied = applied);
    }
  }

  Future<void> _removeReward() async {
    if (_busy) {
      return;
    }
    await ref.read(cartControllerProvider.notifier).removeStoreReward();
    if (mounted) {
      setState(() => _rewardApplied = false);
    }
  }

  Future<void> _pay() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await context.push('/payment');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    if (cartState is CartLoading ||
        cartState is CartLinked ||
        cartState is CartInitial) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const LoadingIndicator(),
      );
    }

    if (cartState is CartOrderPlaced) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: SafeArea(
          child: _CheckoutPlacedView(
            onViewReceipt: () => context.pushReplacement('/receipt'),
          ),
        ),
      );
    }

    if (cartState is CartError || cartState is! CartLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: EmptyStateView(
          icon: Icons.shopping_cart_outlined,
          title: 'Nothing to check out',
          message: 'Add products to your live cart before checking out.',
          action: FilledButton(
            onPressed: () => context.go('/live-cart'),
            child: const Text('Back to Cart'),
          ),
        ),
      );
    }

    final cart = cartState.cart;
    final rewardsController = ref.read(rewardsControllerProvider.notifier);
    final rewardsState = ref.watch(rewardsControllerProvider);
    final rewardLoaded = rewardsState is RewardsLoaded;
    final discount = _rewardApplied
        ? ref.read(cartControllerProvider.notifier).rewardDiscount
        : 0.0;
    final grandTotal = ref.read(cartControllerProvider.notifier).checkoutTotal;
    final canApplyReward =
        rewardLoaded &&
        (rewardsController.pendingStoreRewards > 0 ||
            rewardsState.balance >= RewardsController.storeRewardCost);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user != null) ...[
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: AppColors.primaryGradient,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Checked out as', style: AppTextStyles.label),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              user.phone,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text('Order Summary', style: AppTextStyles.heading),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      for (final item in cart.items) CartItemRow(item: item),
                      const Divider(height: 24),
                      SummaryLine(
                        label: 'Products',
                        value: '${cart.items.length}',
                      ),
                      const SizedBox(height: 6),
                      SummaryLine(
                        label: 'Items',
                        value: '${cart.totalQuantity}',
                      ),
                      if (discount > 0) ...[
                        const SizedBox(height: 6),
                        SummaryLine(
                          label: 'Store Reward Discount',
                          value: '−₹${discount.toStringAsFixed(2)}',
                          isDiscount: true,
                        ),
                      ],
                      const SizedBox(height: 6),
                      SummaryLine(
                        label: 'Grand Total',
                        value: '₹${grandTotal.toStringAsFixed(2)}',
                        emphasized: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _StoreRewardSection(
                rewardLoaded: rewardLoaded,
                rewardApplied: _rewardApplied,
                canApplyReward: canApplyReward,
                balance: rewardLoaded ? rewardsState.balance : 0,
                onApply: _applyReward,
                onRemove: _removeReward,
              ),
              const SizedBox(height: AppSpacing.lg),
              const InfoBanner(
                message: 'This is a mock checkout. No real payment will be processed.',
              ),
              const SizedBox(height: AppSpacing.lg),
              LoadingButton(
                isLoading: _busy,
                onPressed: _pay,
                spinnerColor: Colors.white,
                child: Text('Pay ₹${grandTotal.toStringAsFixed(2)}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreRewardSection extends StatelessWidget {
  const _StoreRewardSection({
    required this.rewardLoaded,
    required this.rewardApplied,
    required this.canApplyReward,
    required this.balance,
    required this.onApply,
    required this.onRemove,
  });

  final bool rewardLoaded;
  final bool rewardApplied;
  final bool canApplyReward;
  final int balance;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.card_giftcard, color: AppColors.accent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apply ₹10 Store Reward',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rewardLoaded
                      ? '100 SmartCoins — balance: $balance'
                      : '100 SmartCoins',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch(
            value: rewardApplied,
            onChanged: rewardApplied
                ? (_) => onRemove()
                : canApplyReward
                ? (_) => onApply()
                : null,
          ),
        ],
      ),
    );
  }
}

class _CheckoutPlacedView extends StatelessWidget {
  const _CheckoutPlacedView({required this.onViewReceipt});

  final VoidCallback onViewReceipt;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Order placed', style: AppTextStyles.heading),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Your order is ready. View the receipt to finish.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onViewReceipt,
              child: const Text('View Receipt'),
            ),
          ],
        ),
      ),
    );
  }
}
