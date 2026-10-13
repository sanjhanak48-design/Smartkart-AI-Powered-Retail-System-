import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/models/smart_coin_transaction.dart';
import '../controllers/rewards_controller.dart';

class SmartCoinsPage extends ConsumerStatefulWidget {
  const SmartCoinsPage({super.key});

  @override
  ConsumerState<SmartCoinsPage> createState() => _SmartCoinsPageState();
}

class _SmartCoinsPageState extends ConsumerState<SmartCoinsPage> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rewardsControllerProvider.notifier).loadRewards();
    });
  }

  Future<void> _redeem() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(rewardsControllerProvider.notifier)
          .redeemStoreReward();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.message)));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rewardsState = ref.watch(rewardsControllerProvider);
    final showLoading =
        rewardsState is RewardsInitial ||
        rewardsState is RewardsLoading ||
        rewardsState is RewardsEarning ||
        rewardsState is RewardsRedeeming;

    return Scaffold(
      appBar: AppBar(title: const Text('SmartCoins')),
      body: SafeArea(
        child: showLoading
            ? const LoadingIndicator()
            : rewardsState is RewardsError
            ? ErrorView(
                message: rewardsState.message,
                onAction: () =>
                    ref.read(rewardsControllerProvider.notifier).loadRewards(),
              )
            : _SmartCoinsBody(
                rewardsState: rewardsState,
                isRedeeming: _busy,
                onRedeem: _busy ? null : _redeem,
                pendingStoreRewards: ref
                    .read(rewardsControllerProvider.notifier)
                    .pendingStoreRewards,
              ),
      ),
    );
  }
}

class _SmartCoinsBody extends StatelessWidget {
  const _SmartCoinsBody({
    required this.rewardsState,
    required this.isRedeeming,
    required this.onRedeem,
    required this.pendingStoreRewards,
  });

  final RewardsState rewardsState;
  final bool isRedeeming;
  final VoidCallback? onRedeem;
  final int pendingStoreRewards;

  @override
  Widget build(BuildContext context) {
    final loaded = rewardsState as RewardsLoaded;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BalanceCard(balance: loaded.balance),
          if (pendingStoreRewards > 0) ...[
            const SizedBox(height: AppSpacing.md),
            InfoBanner(
              message: pendingStoreRewards == 1
                  ? '1 Store Reward available for checkout'
                  : '$pendingStoreRewards Store Rewards available for checkout',
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text('Rewards', style: AppTextStyles.heading),
          const SizedBox(height: AppSpacing.sm),
          _RewardCard(isRedeeming: isRedeeming, onRedeem: onRedeem),
          const SizedBox(height: AppSpacing.xl),
          const _HowItWorks(),
          const SizedBox(height: AppSpacing.xl),
          Text('Transaction History', style: AppTextStyles.heading),
          const SizedBox(height: AppSpacing.sm),
          if (loaded.transactions.isEmpty)
            const _EmptyHistory()
          else
            _TransactionList(transactions: loaded.transactions),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC49A5C), Color(0xFFA88542)],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.monetization_on_outlined,
            size: 40,
            color: Colors.white,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'SmartCoins',
            style: AppTextStyles.label.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            '$balance',
            style: AppTextStyles.headingLarge.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            'coins',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.isRedeeming, required this.onRedeem});

  final bool isRedeeming;
  final VoidCallback? onRedeem;

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
                  RewardsController.storeRewardName,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${RewardsController.storeRewardCost} SmartCoins',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton.tonal(onPressed: onRedeem, child: const Text('Redeem')),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  static const _steps = [
    ('Earn coins', 'Earn coins on every order you complete.'),
    ('Collect rewards', '100 coins converts into a ₹10 Store Reward.'),
    ('Redeem at checkout', 'Apply your reward to reduce your bill.'),
    ('Rewards carry over', 'Unused rewards stay in your account.'),
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How it works', style: AppTextStyles.subheading),
          const SizedBox(height: AppSpacing.md),
          for (final (index, (title, body)) in _steps.indexed) ...[
            if (index > 0) const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.accentGradient,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: AppTextStyles.sectionNumber,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.body),
                      const SizedBox(height: 2),
                      Text(body, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.transactions});

  final List<SmartCoinTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        children: [
          for (var i = 0; i < transactions.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _TransactionRow(transaction: transactions[i]),
          ],
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final SmartCoinTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isEarned = transaction.type == SmartCoinTransactionType.earned;
    final amount = isEarned ? '+${transaction.coins}' : '-${transaction.coins}';
    final amountColor = isEarned ? AppColors.primary : AppColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryFaint,
            child: Icon(
              isEarned ? Icons.add : Icons.remove,
              size: 20,
              color: amountColor,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEarned ? 'Earned from purchase' : 'Redeemed',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            amount,
            style: AppTextStyles.subheading.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        'No transactions yet. Place an order to start earning SmartCoins.',
        style: AppTextStyles.bodySmall,
        textAlign: TextAlign.center,
      ),
    );
  }
}
