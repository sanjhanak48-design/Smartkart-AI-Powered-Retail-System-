// Focused unit tests for the RewardsController and order-earning integration.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/features/cart/domain/models/cart.dart';
import 'package:smartkart/features/cart/domain/models/order.dart';
import 'package:smartkart/features/cart/presentation/controllers/cart_controller.dart';
import 'package:smartkart/features/rewards/domain/models/smart_coin_transaction.dart';
import 'package:smartkart/features/rewards/presentation/controllers/rewards_controller.dart';

Order _order(String id, {double total = 159}) {
  return Order(
    orderId: id,
    createdAt: DateTime(2026, 2, 1),
    items: const [
      CartItem(
        product: Product(id: 'milk', name: 'Milk', price: 30),
        quantity: 2,
      ),
      CartItem(
        product: Product(id: 'rice', name: 'Rice', price: 99),
        quantity: 1,
      ),
    ],
    total: total,
  );
}

void main() {
  test('loadRewards reports an initial zero balance', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(rewardsControllerProvider.notifier);
    await controller.loadRewards();

    final state = container.read(rewardsControllerProvider);
    expect(state, isA<RewardsLoaded>());
    final loaded = state as RewardsLoaded;
    expect(loaded.balance, 0);
    expect(loaded.transactions, isEmpty);
  });

  test('awardCoinsForOrder adds floor(total) coins to the balance', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(rewardsControllerProvider.notifier);
    final awarded = await controller.awardCoinsForOrder(
      _order('SM-0001', total: 124.5),
    );

    expect(awarded, 124);
    final loaded = container.read(rewardsControllerProvider) as RewardsLoaded;
    expect(loaded.balance, 124);
  });

  test('awardCoinsForOrder records an earned transaction', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(rewardsControllerProvider.notifier);
    await controller.awardCoinsForOrder(_order('SM-0001'));

    final loaded = container.read(rewardsControllerProvider) as RewardsLoaded;
    expect(loaded.transactions, hasLength(1));
    final transaction = loaded.transactions.first;
    expect(transaction.type, SmartCoinTransactionType.earned);
    expect(transaction.description, 'Order SM-0001');
    expect(transaction.coins, 159);
  });

  test('successful redemption subtracts 100 coins and is recorded', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(rewardsControllerProvider.notifier);
    await controller.awardCoinsForOrder(_order('SM-0001'));

    final result = await controller.redeemStoreReward();

    expect(result.isSuccessful, isTrue);
    final loaded = container.read(rewardsControllerProvider) as RewardsLoaded;
    expect(loaded.balance, 59);
    expect(loaded.transactions, hasLength(2));
    expect(loaded.transactions.first.type, SmartCoinTransactionType.redeemed);
    expect(loaded.transactions.first.coins, 100);
  });

  test('redemption is rejected when the balance is insufficient', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(rewardsControllerProvider.notifier);
    await controller.loadRewards();

    final result = await controller.redeemStoreReward();

    expect(result.isSuccessful, isFalse);
    final loaded = container.read(rewardsControllerProvider) as RewardsLoaded;
    expect(loaded.balance, 0);
    expect(loaded.transactions, isEmpty);
  });

  test('a duplicate order reward is not granted twice', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(rewardsControllerProvider.notifier);
    final order = _order('SM-0001');
    await controller.awardCoinsForOrder(order);
    final secondAward = await controller.awardCoinsForOrder(order);

    expect(secondAward, isNull);
    final loaded = container.read(rewardsControllerProvider) as RewardsLoaded;
    expect(loaded.balance, 159);
    expect(loaded.transactions, hasLength(1));
  });

  test('placing an order through the cart awards SmartCoins', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final cartController = container.read(cartControllerProvider.notifier);
    await cartController.linkCart('CART-1');
    await cartController.openLiveCart();
    await cartController.simulateAdd('milk');
    await cartController.simulateAdd('rice');

    await cartController.checkout();

    final loaded = container.read(rewardsControllerProvider) as RewardsLoaded;
    expect(loaded.balance, 129);
    expect(loaded.transactions.first.type, SmartCoinTransactionType.earned);
  });
}
