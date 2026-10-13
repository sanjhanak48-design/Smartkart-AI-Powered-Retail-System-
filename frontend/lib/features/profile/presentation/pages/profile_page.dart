import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/models/auth_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../cart/domain/models/order.dart';
import '../../../cart/presentation/controllers/purchase_history_controller.dart';
import '../../../rewards/presentation/controllers/rewards_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/stat_module.dart';
import '../../../profile/domain/models/order_stats.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(purchaseHistoryControllerProvider.notifier).fetchHistory();
      ref.read(rewardsControllerProvider.notifier).loadRewards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: user == null
            ? const Center(child: Text('No authenticated user.'))
            : _ProfileBody(user: user),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = user.displayName;
    final displayName = (name == null || name.trim().isEmpty)
        ? 'SmartKart User'
        : name;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          // Centered identity
          Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primarySoft,
              child: Text(
                displayName.isEmpty ? '?' : displayName[0].toUpperCase(),
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.primary,
                  fontSize: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            displayName,
            style: AppTextStyles.heading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            user.phone,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  user.uid,
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(const SnackBar(content: Text('UID copied')));
                  Clipboard.setData(ClipboardData(text: user.uid));
                },
                child: const Icon(
                  Icons.copy_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Stats row
          const _OrderStatsRow(),
          const SizedBox(height: AppSpacing.md),

          // SmartCoins card
          _SmartCoinsCompactCard(),
          const SizedBox(height: AppSpacing.md),

          // Order activity
          const Text('Order Activity'),
          const SizedBox(height: AppSpacing.sm),
          _OrderActivitySection(),
          const SizedBox(height: AppSpacing.lg),

          // Sign Out
          Center(
            child: TextButton(
              onPressed: () {
                ref.read(authControllerProvider.notifier).signOut();
              },
              child: Text(
                'Sign Out',
                style: AppTextStyles.body.copyWith(color: AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderStatsRow extends ConsumerWidget {
  const _OrderStatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(purchaseHistoryControllerProvider);

    if (historyState is! HistoryLoaded) {
      return const SizedBox.shrink();
    }

    final stats = OrderStats.fromOrders(historyState.orders);
    return Row(
      children: [
        Expanded(
          child: StatModule(
            label: 'Orders',
            value: '${stats.ordersCount}',
            icon: Icons.receipt_long_outlined,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StatModule(
            label: 'Items',
            value: '${stats.itemsPurchased}',
            icon: Icons.shopping_bag_outlined,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: StatModule(
            label: 'Total Spent',
            value: '₹${stats.totalSpent.toStringAsFixed(2)}',
            icon: Icons.account_balance_wallet_outlined,
            accentColor: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

class _SmartCoinsCompactCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardsState = ref.watch(rewardsControllerProvider);

    final String value;
    final bool isError;
    switch (rewardsState) {
      case RewardsLoaded():
        value = '${rewardsState.balance} coins';
        isError = false;
      case RewardsError(:final message):
        value = message;
        isError = true;
      default:
        value = 'Loading coins...';
        isError = false;
    }

    return AppCard(
      onTap: () => context.push('/smartcoins'),
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
                Text(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isError ? AppColors.error : AppColors.textSecondary,
                  ),
                ),
                if (rewardsState is RewardsError) ...[
                  const SizedBox(height: AppSpacing.xs),
                  FilledButton.tonal(
                    onPressed: () => ref
                        .read(rewardsControllerProvider.notifier)
                        .loadRewards(),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            'View SmartCoins',
            style: AppTextStyles.body.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _OrderActivitySection extends ConsumerWidget {
  const _OrderActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(purchaseHistoryControllerProvider);

    if (historyState is HistoryInitial || historyState is HistoryLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (historyState is HistoryError) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              historyState.message,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.xs),
            FilledButton.tonal(
              onPressed: () => ref
                  .read(purchaseHistoryControllerProvider.notifier)
                  .fetchHistory(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (historyState is HistoryEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No orders yet.', style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Complete a checkout to see your activity here.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonal(
              onPressed: () => context.push('/history'),
              child: const Text('View Purchase History'),
            ),
          ],
        ),
      );
    }

    if (historyState is HistoryLoaded) {
      return Column(
        children: [
          for (final order in historyState.orders.take(3)) ...[
            _OrderRow(order: order),
            if (order != historyState.orders.last) ...[
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () => context.push('/history'),
              child: const Text('View Purchase History'),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: () => context.push('/history/${order.orderId}'),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderId,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${order.totalQuantity} items',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${order.totalAfterDiscount.toStringAsFixed(0)}',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.badgeGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  'Paid',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.badgeGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
