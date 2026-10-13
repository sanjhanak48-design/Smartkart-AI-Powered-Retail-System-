// Focused tests for Store Reward discount application and checkout billing.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/features/cart/data/repositories/cart_repository.dart';
import 'package:smartkart/features/cart/domain/models/cart.dart';
import 'package:smartkart/features/cart/domain/models/cart_event.dart';
import 'package:smartkart/features/cart/domain/models/order.dart';
import 'package:smartkart/features/cart/presentation/controllers/cart_controller.dart';
import 'package:smartkart/features/rewards/domain/models/smart_coin_transaction.dart';
import 'package:smartkart/features/rewards/presentation/controllers/rewards_controller.dart';

void main() {
  const milk = Product(id: 'milk', name: 'Milk', price: 30);
  const rice = Product(id: 'rice', name: 'Rice', price: 99);

  Order seedOrder({double total = 129}) {
    return Order(
      orderId: 'SEED-1',
      createdAt: DateTime(2026, 2, 1),
      items: const [
        CartItem(product: milk, quantity: 2),
        CartItem(product: rice, quantity: 1),
      ],
      total: total,
    );
  }

  /// Seeds 129 SmartCoins, links a cart and loads milk + rice (subtotal 129).
  Future<ProviderContainer> populatedCart() async {
    final container = ProviderContainer();
    await container
        .read(rewardsControllerProvider.notifier)
        .awardCoinsForOrder(seedOrder());
    final cart = container.read(cartControllerProvider.notifier);
    await cart.linkCart('CART-1');
    await cart.openLiveCart();
    await cart.simulateAdd('milk');
    await cart.simulateAdd('rice');
    return container;
  }

  group('Order discount model', () {
    test('totalAfterDiscount subtracts the discount from total', () {
      final order = Order(
        orderId: 'SM-0001',
        createdAt: DateTime(2026, 2, 1),
        items: const [],
        total: 129,
        discount: 10,
      );
      expect(order.totalAfterDiscount, 119);
    });

    test('discount greater than total clamps the final total to zero', () {
      final order = Order(
        orderId: 'SM-0002',
        createdAt: DateTime(2026, 2, 1),
        items: const [],
        total: 5,
        discount: 10,
      );
      expect(order.totalAfterDiscount, 0);
    });

    test('Orders without discount behave exactly as before', () {
      final order = Order(
        orderId: 'SM-0003',
        createdAt: DateTime(2026, 2, 1),
        items: const [],
        total: 159,
      );
      expect(order.discount, 0);
      expect(order.totalAfterDiscount, 159);
    });
  });

  group('MockCartRepository placeOrder', () {
    test(
      'placeOrder with discount creates an Order with the discount',
      () async {
        final repository = MockCartRepository();
        final order = await repository.placeOrder('cart-1', const [
          CartItem(product: milk, quantity: 2),
          CartItem(product: rice, quantity: 1),
        ], discount: 10);
        expect(order.total, 159);
        expect(order.discount, 10);
        expect(order.totalAfterDiscount, 149);
      },
    );

    test('placeOrder without discount remains compatible', () async {
      final repository = MockCartRepository();
      final order = await repository.placeOrder('cart-1', const [
        CartItem(product: milk, quantity: 1),
      ]);
      expect(order.discount, 0);
      expect(order.totalAfterDiscount, 30);
    });
  });

  group('applyStoreReward', () {
    test('succeeds when the balance is at least 100 coins', () async {
      final container = await populatedCart();
      addTearDown(container.dispose);
      final cart = container.read(cartControllerProvider.notifier);

      final applied = await cart.applyStoreReward();

      expect(applied, isTrue);
      expect(cart.rewardDiscount, 10.0);
    });

    test('deducts exactly 100 coins when redeeming at checkout', () async {
      final container = await populatedCart();
      addTearDown(container.dispose);
      final cart = container.read(cartControllerProvider.notifier);

      await cart.applyStoreReward();

      final loaded = container.read(rewardsControllerProvider) as RewardsLoaded;
      expect(loaded.balance, 29);
      expect(loaded.transactions.first.type, SmartCoinTransactionType.redeemed);
      expect(loaded.transactions.first.coins, 100);
    });

    test('fails with insufficient balance', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(rewardsControllerProvider.notifier)
          .awardCoinsForOrder(seedOrder(total: 50));
      final cart = container.read(cartControllerProvider.notifier);
      await cart.linkCart('CART-1');
      await cart.openLiveCart();

      final applied = await cart.applyStoreReward();

      expect(applied, isFalse);
    });

    test('failed application does not change the discount', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container
          .read(rewardsControllerProvider.notifier)
          .awardCoinsForOrder(seedOrder(total: 50));
      final cart = container.read(cartControllerProvider.notifier);
      await cart.linkCart('CART-1');
      await cart.openLiveCart();

      await cart.applyStoreReward();

      expect(cart.rewardDiscount, 0.0);
    });

    test(
      'applying the reward twice does not deduct a second 100 coins',
      () async {
        final container = await populatedCart();
        addTearDown(container.dispose);
        final cart = container.read(cartControllerProvider.notifier);

        final first = await cart.applyStoreReward();
        final second = await cart.applyStoreReward();

        expect(first, isTrue);
        expect(second, isTrue);
        expect(cart.rewardDiscount, 10.0);
        final loaded =
            container.read(rewardsControllerProvider) as RewardsLoaded;
        expect(loaded.balance, 29);
      },
    );

    test(
      'a pre-redeemed reward is applied without another deduction',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final rewards = container.read(rewardsControllerProvider.notifier);
        await rewards.awardCoinsForOrder(seedOrder());
        await rewards.redeemStoreReward();
        final cart = container.read(cartControllerProvider.notifier);
        await cart.linkCart('CART-1');
        await cart.openLiveCart();

        final applied = await cart.applyStoreReward();

        expect(applied, isTrue);
        expect(cart.rewardDiscount, 10.0);
        final loaded =
            container.read(rewardsControllerProvider) as RewardsLoaded;
        expect(loaded.balance, 29);
      },
    );
  });

  group('removeStoreReward', () {
    test('restores 100 coins and resets the discount', () async {
      final container = await populatedCart();
      addTearDown(container.dispose);
      final cart = container.read(cartControllerProvider.notifier);
      await cart.applyStoreReward();

      await cart.removeStoreReward();

      expect(cart.rewardDiscount, 0.0);
      final loaded = container.read(rewardsControllerProvider) as RewardsLoaded;
      expect(loaded.balance, 129);
      expect(loaded.transactions.first.description, 'Store Reward reversal');
    });
  });

  group('checkout with Store Reward', () {
    test('passes the discount into the Order', () async {
      final container = await populatedCart();
      addTearDown(container.dispose);
      final cart = container.read(cartControllerProvider.notifier);
      await cart.applyStoreReward();

      await cart.checkout();

      final state = container.read(cartControllerProvider);
      expect(state, isA<CartOrderPlaced>());
      final order = (state as CartOrderPlaced).order;
      expect(order.total, 129);
      expect(order.discount, 10);
      expect(order.totalAfterDiscount, 119);
    });

    test(
      'consumes the applied Store Reward after a successful checkout',
      () async {
        final container = await populatedCart();
        addTearDown(container.dispose);
        final rewards = container.read(rewardsControllerProvider.notifier);
        final cart = container.read(cartControllerProvider.notifier);
        await cart.applyStoreReward();
        expect(rewards.pendingStoreRewards, 1);

        await cart.checkout();

        expect(rewards.pendingStoreRewards, 0);
      },
    );

    test('checkout without a reward creates a discount of zero', () async {
      final container = await populatedCart();
      addTearDown(container.dispose);
      final cart = container.read(cartControllerProvider.notifier);

      await cart.checkout();

      final order =
          (container.read(cartControllerProvider) as CartOrderPlaced).order;
      expect(order.discount, 0);
      expect(order.totalAfterDiscount, order.total);
    });

    test('still earns SmartCoins on the original total after a discounted '
        'checkout', () async {
      final container = await populatedCart();
      addTearDown(container.dispose);
      final cart = container.read(cartControllerProvider.notifier);
      await cart.applyStoreReward();
      expect(
        (container.read(rewardsControllerProvider) as RewardsLoaded).balance,
        29,
      );

      await cart.checkout();

      final loaded = container.read(rewardsControllerProvider) as RewardsLoaded;
      expect(loaded.balance, 158);
    });

    test('clearCart resets rewardDiscount', () async {
      final container = await populatedCart();
      addTearDown(container.dispose);
      final cart = container.read(cartControllerProvider.notifier);
      await cart.applyStoreReward();
      expect(cart.rewardDiscount, 10.0);

      await cart.clearCart();

      expect(cart.rewardDiscount, 0.0);
    });

    test('streamed events preserve the applied rewardDiscount', () async {
      final container = await populatedCart();
      addTearDown(container.dispose);
      final repository =
          container.read(cartRepositoryProvider) as MockCartRepository;
      final cart = container.read(cartControllerProvider.notifier);
      await cart.applyStoreReward();

      repository.emitCartEvent(
        const CartEvent(type: CartEventType.itemAdded, product: milk),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final cartState = container.read(cartControllerProvider);
      expect(cartState, isA<CartLoaded>());
      expect((cartState as CartLoaded).cart.items, hasLength(2));
      expect(cart.rewardDiscount, 10.0);
    });

    test('late stream events never overwrite CartOrderPlaced', () async {
      final container = await populatedCart();
      addTearDown(container.dispose);
      final repository =
          container.read(cartRepositoryProvider) as MockCartRepository;
      final cart = container.read(cartControllerProvider.notifier);
      final rewards = container.read(rewardsControllerProvider.notifier);
      await cart.applyStoreReward();
      await cart.checkout();
      expect(container.read(cartControllerProvider), isA<CartOrderPlaced>());

      repository.emitCartEvent(
        const CartEvent(type: CartEventType.itemAdded, product: milk),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(container.read(cartControllerProvider), isA<CartOrderPlaced>());
      expect(rewards.pendingStoreRewards, 0);
    });
  });
}
