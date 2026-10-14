// Focused unit tests for the MockRewardsRepository SmartCoins store.
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/features/rewards/data/repositories/rewards_repository.dart';
import 'package:smartkart/features/rewards/domain/models/smart_coin_transaction.dart';

void main() {
  test('initial balance is zero with no transactions', () async {
    final repository = MockRewardsRepository();

    expect(await repository.getBalance(), 0);
    expect(await repository.getTransactions(), isEmpty);
  });

  test('addCoins increases the balance', () async {
    final repository = MockRewardsRepository();

    await repository.addCoins(coins: 124, description: 'Order SM-0001');
    await repository.addCoins(coins: 50, description: 'Order SM-0002');

    expect(await repository.getBalance(), 174);
  });

  test('addCoins records an earned transaction', () async {
    final repository = MockRewardsRepository();

    final transaction = await repository.addCoins(
      coins: 124,
      description: 'Order SM-0001',
    );

    expect(transaction.type, SmartCoinTransactionType.earned);
    expect(transaction.coins, 124);
    expect(transaction.description, 'Order SM-0001');
    expect(transaction.id, isNotEmpty);

    final transactions = await repository.getTransactions();
    expect(transactions, hasLength(1));
  });

  test('successful redemption subtracts 100 coins and records it', () async {
    final repository = MockRewardsRepository();

    await repository.addCoins(coins: 124, description: 'Order SM-0001');
    final transaction = await repository.redeemCoins(
      coins: 100,
      description: '₹10 Store Reward',
    );

    expect(await repository.getBalance(), 24);
    expect(transaction.type, SmartCoinTransactionType.redeemed);
    expect(transaction.coins, 100);
    expect(transaction.description, '₹10 Store Reward');
  });

  test('redemption fails when the balance is insufficient', () async {
    final repository = MockRewardsRepository();

    await repository.addCoins(coins: 50, description: 'Order SM-0001');

    await expectLater(
      repository.redeemCoins(coins: 100, description: '₹10 Store Reward'),
      throwsStateError,
    );
    expect(await repository.getBalance(), 50);
    expect(await repository.getTransactions(), hasLength(1));
  });

  test('getTransactions returns the newest transaction first', () async {
    final repository = MockRewardsRepository();

    await repository.addCoins(coins: 124, description: 'Order SM-0001');
    await repository.addCoins(coins: 35, description: 'Order SM-0002');

    final transactions = await repository.getTransactions();
    expect(transactions.map((t) => t.description).toList(), [
      'Order SM-0002',
      'Order SM-0001',
    ]);
  });
}
