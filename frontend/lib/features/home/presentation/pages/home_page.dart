import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../recommendations/domain/models/recommended_item.dart';
import '../../../recommendations/presentation/controllers/recommendations_controller.dart';
import '../../../rewards/presentation/controllers/rewards_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/section_label.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    final authState = ref.watch(authControllerProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final displayName =
        (user?.displayName == null || user!.displayName!.trim().isEmpty)
        ? 'SmartKart User'
        : user.displayName!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartKart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Link Cart',
            onPressed: () => context.push('/scan-cart'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom greeting header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_greeting(), style: AppTextStyles.bodySmall),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(displayName, style: AppTextStyles.heading),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/profile'),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primarySoft,
                        child: Text(
                          displayName.isEmpty
                              ? '?'
                              : displayName[0].toUpperCase(),
                          style: AppTextStyles.subheading.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Premium dark cart card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _ConnectedCartCard(
                  onTap: () => context.go('/live-cart'),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Quick actions bento
              const SectionLabel(text: 'Quick Actions'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _QuickActionsBento(),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Handpicked For You section
              const SectionLabel(text: 'Handpicked For You'),
              SizedBox(height: 120, child: _SmartPicksRail()),

              const SizedBox(height: AppSpacing.md),

              // Rewards card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _RewardsMiniCard(onTap: () => context.go('/smartcoins')),
              ),

              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() => 'Welcome!';
}

class _ConnectedCartCard extends ConsumerWidget {
  const _ConnectedCartCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartControllerProvider);

    final String label;
    final String value;
    final bool connected;
    switch (cartState) {
      case CartLinked(:final cart) || CartLoaded(:final cart):
        final count = cart.totalQuantity;
        label = cart.cartId;
        value = count == 1 ? '1 item in cart' : '$count items in cart';
        connected = true;
      case CartLoading():
        label = 'Loading...';
        value = 'Syncing your cart';
        connected = false;
      case CartLinking():
        label = 'Connecting...';
        value = 'Scanning your cart';
        connected = false;
      case CartInitial():
        label = 'No cart linked';
        value = 'Tap to connect a cart';
        connected = false;
      case CartError(:final message):
        label = 'No cart linked';
        value = message;
        connected = false;
      case CartOrderPlaced():
        label = 'Order placed';
        value = 'View your Live Cart';
        connected = true;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.premiumGradient,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            children: [
              Container(
                width: AppSpacing.iconBox,
                height: AppSpacing.iconBox,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      value,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: connected
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: connected
                            ? const Color(0xFF4ADE80)
                            : Colors.white54,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      connected ? 'Connected' : 'Link Cart',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _QuickActionsBento extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.auto_awesome,
                iconColor: AppColors.accent,
                title: 'Smart Picks',
                subtitle: 'See Recommendations',
                onTap: () => context.push('/recommendations'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _RewardsActionCard(onTap: () => context.go('/smartcoins')),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.storefront_outlined,
                iconColor: AppColors.primary,
                title: 'Shop Products',
                subtitle: 'Browse Products',
                onTap: () => context.go('/catalog'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.receipt_long_outlined,
                iconColor: AppColors.primary,
                title: 'My Orders',
                subtitle: 'View Purchase History',
                onTap: () => context.push('/history'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                title,
                style: AppTextStyles.subheading,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(subtitle, style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardsActionCard extends ConsumerWidget {
  const _RewardsActionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsState = ref.watch(rewardsControllerProvider);
    final balance = switch (rewardsState) {
      RewardsLoaded(:final balance) => balance,
      _ => 0,
    };

    return Material(
      color: AppColors.accentLight.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.accentGradient,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.star, size: 18, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '$balance',
                style: AppTextStyles.heading.copyWith(color: AppColors.accent),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text('coins', style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmartPicksRail extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recommendationsControllerProvider);
    final items = switch (state) {
      RecommendationsLoaded(:final items) => items,
      _ => const <RecommendedItem>[],
    };

    if (items.isEmpty) {
      return ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          SizedBox(
            width: 200,
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppColors.accent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Add items to your cart for AI picks.',
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          width: 180,
          margin: const EdgeInsets.only(right: AppSpacing.sm),
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.sm),
            onTap: () => context.push('/recommendations'),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accentMint,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    item.product.emojiIcon ?? '🛒',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.product.name,
                        style: AppTextStyles.subheading,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '₹${item.product.price.toStringAsFixed(2)}',
                        style: AppTextStyles.price.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RewardsMiniCard extends ConsumerWidget {
  const _RewardsMiniCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsState = ref.watch(rewardsControllerProvider);
    final balance = switch (rewardsState) {
      RewardsLoaded(:final balance) => balance,
      _ => 0,
    };

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.accentGradient),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(Icons.star, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SmartCoins', style: AppTextStyles.subheading),
                const SizedBox(height: AppSpacing.xxs),
                Text('$balance coins earned', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Text(
            'View',
            style: AppTextStyles.body.copyWith(color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.xxs),
          const Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
        ],
      ),
    );
  }
}
