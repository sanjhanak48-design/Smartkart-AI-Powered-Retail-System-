import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/domain/models/order.dart';
import '../../data/repositories/rewards_repository.dart';
import '../../domain/models/smart_coin_transaction.dart';

sealed class RewardsState {
  const RewardsState();
}

class RewardsInitial extends RewardsState {
  const RewardsInitial();
}

class RewardsLoading extends RewardsState {
  const RewardsLoading();
}

class RewardsEarning extends RewardsState {
  const RewardsEarning(this.coins);

  final int coins;
}

class RewardsLoaded extends RewardsState {
  const RewardsLoaded({required this.balance, required this.transactions});

  final int balance;
  final List<SmartCoinTransaction> transactions;
}

class RewardsRedeeming extends RewardsState {
  const RewardsRedeeming();
}

class RewardsError extends RewardsState {
  const RewardsError(this.message);

  final String message;
}

class RewardRedemptionResult {
  const RewardRedemptionResult.successful()
    : isSuccessful = true,
      message = '₹10 Store Reward redeemed!';

  const RewardRedemptionResult.insufficient()
    : isSuccessful = false,
      message = 'Not enough SmartCoins to redeem this reward.';

  final bool isSuccessful;
  final String message;
}

class RewardsController extends Notifier<RewardsState> {
  static const String storeRewardName = '₹10 Store Reward';
  static const int storeRewardCost = 100;

  late final RewardsRepository _repository;
  final Set<String> _awardedOrderIds = {};
  int _pendingStoreRewards = 0;

  int get pendingStoreRewards => _pendingStoreRewards;

  @override
  RewardsState build() {
    _repository = ref.watch(rewardsRepositoryProvider);
    return const RewardsInitial();
  }

  int get _currentBalance {
    final current = state;
    return current is RewardsLoaded ? current.balance : 0;
  }

  Future<void> loadRewards() async {
    state = const RewardsLoading();
    try {
      final balance = await _repository.getBalance();
      final transactions = await _repository.getTransactions();
      state = RewardsLoaded(balance: balance, transactions: transactions);
    } catch (_) {
      state = const RewardsError(
        'Unable to load SmartCoins. Please try again.',
      );
    }
  }

  /// Awards floor(order.total) SmartCoins once per order.
  /// Returns the number of coins awarded, or null if already awarded.
  Future<int?> awardCoinsForOrder(Order order) async {
    if (_awardedOrderIds.contains(order.orderId)) {
      return null;
    }

    final coins = order.total.floor();
    state = RewardsEarning(coins);
    try {
      await _repository.addCoins(
        coins: coins,
        description: 'Order ${order.orderId}',
      );
      _awardedOrderIds.add(order.orderId);
      final balance = await _repository.getBalance();
      final transactions = await _repository.getTransactions();
      state = RewardsLoaded(balance: balance, transactions: transactions);
      return coins;
    } catch (_) {
      state = const RewardsError(
        'Unable to update SmartCoins. Please try again.',
      );
      return null;
    }
  }

  Future<RewardRedemptionResult> redeemStoreReward() async {
    if (_currentBalance < storeRewardCost) {
      return const RewardRedemptionResult.insufficient();
    }

    state = const RewardsRedeeming();
    try {
      await _repository.redeemCoins(
        coins: storeRewardCost,
        description: storeRewardName,
      );
      _pendingStoreRewards += 1;
      final balance = await _repository.getBalance();
      final transactions = await _repository.getTransactions();
      state = RewardsLoaded(balance: balance, transactions: transactions);
      return const RewardRedemptionResult.successful();
    } catch (_) {
      state = const RewardsError(
        'Unable to redeem the reward. Please try again.',
      );
      return const RewardRedemptionResult.insufficient();
    }
  }

  /// Reverses a previously redeemed Store Reward, restoring the 100 SmartCoins.
  /// A pending reward is only reversed if one is available.
  Future<void> reverseRedemption() async {
    if (_pendingStoreRewards <= 0) {
      return;
    }
    try {
      await _repository.addCoins(
        coins: storeRewardCost,
        description: 'Store Reward reversal',
      );
      _pendingStoreRewards -= 1;
      final balance = await _repository.getBalance();
      final transactions = await _repository.getTransactions();
      state = RewardsLoaded(balance: balance, transactions: transactions);
    } catch (_) {
      state = const RewardsError(
        'Unable to reverse the reward. Please try again.',
      );
    }
  }

  /// Consumes one applied Store Reward after a successful checkout.
  void consumeStoreReward() {
    if (_pendingStoreRewards > 0) {
      _pendingStoreRewards -= 1;
    }
  }
}

final rewardsControllerProvider =
    NotifierProvider<RewardsController, RewardsState>(RewardsController.new);
