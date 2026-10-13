// Focused unit tests for purchase history and order details.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/features/cart/data/repositories/cart_repository.dart';
import 'package:smartkart/features/cart/presentation/controllers/cart_controller.dart';
import 'package:smartkart/features/cart/presentation/controllers/purchase_history_controller.dart';

void main() {
  group('MockCartRepository purchase history', () {
    test('placeOrder stores an order in history', () async {
      final repo = MockCartRepository();
      await repo.addItem('cart-1', 'milk');
      final items = await repo.addItem('cart-1', 'bread');

      await repo.placeOrder('cart-1', items);

      final orders = await repo.getOrders();
      expect(orders, hasLength(1));
      expect(orders.first.total, 70);
    });

    test('getOrders returns newest order first', () async {
      final repo = MockCartRepository();
      await repo.addItem('cart-1', 'milk');
      final firstItems = await repo.addItem('cart-1', 'milk');
      await repo.placeOrder('cart-1', firstItems);

      await repo.clearCart('cart-1');
      await repo.addItem('cart-1', 'rice');
      final secondItems = await repo.addItem('cart-1', 'rice');
      await repo.placeOrder('cart-1', secondItems);

      final orders = await repo.getOrders();
      expect(orders, hasLength(2));
      expect(orders[0].total, 198);
      expect(orders[1].total, 60);
    });

    test('getOrderById returns the correct order', () async {
      final repo = MockCartRepository();
      await repo.addItem('cart-1', 'rice');
      final items = await repo.addItem('cart-1', 'bread');
      final order = await repo.placeOrder('cart-1', items);

      final found = await repo.getOrderById(order.orderId);
      expect(found, isNotNull);
      expect(found!.orderId, order.orderId);
      expect(found.totalQuantity, 2);
      expect(found.total, 139);
    });

    test('getOrderById returns null for unknown ID', () async {
      final repo = MockCartRepository();
      final found = await repo.getOrderById('SM-NOT-A-REAL-ORDER');
      expect(found, isNull);
    });

    test('history survives live cart clearing', () async {
      final repo = MockCartRepository();
      await repo.addItem('cart-1', 'milk');
      final items = await repo.addItem('cart-1', 'bread');
      final order = await repo.placeOrder('cart-1', items);

      await repo.clearCart('cart-1');

      final orders = await repo.getOrders();
      expect(orders, hasLength(1));
      expect(orders.first.orderId, order.orderId);
    });

    test('fresh repository returns empty history', () async {
      final repo = MockCartRepository();
      final orders = await repo.getOrders();
      expect(orders, isEmpty);
    });
  });

  group('PurchaseHistoryController', () {
    test('fetchHistory returns HistoryLoaded with orders', () async {
      final container = ProviderContainer();
      final repo = container.read(cartRepositoryProvider);
      await repo.addItem('cart-1', 'milk');
      final items = await repo.addItem('cart-1', 'bread');
      await repo.placeOrder('cart-1', items);

      final controller = container.read(
        purchaseHistoryControllerProvider.notifier,
      );
      await controller.fetchHistory();

      final state = container.read(purchaseHistoryControllerProvider);
      expect(state, isA<HistoryLoaded>());
      expect((state as HistoryLoaded).orders, hasLength(1));

      container.dispose();
    });

    test('fetchHistory returns HistoryEmpty for an empty repository', () async {
      final container = ProviderContainer();

      final controller = container.read(
        purchaseHistoryControllerProvider.notifier,
      );
      await controller.fetchHistory();

      final state = container.read(purchaseHistoryControllerProvider);
      expect(state, isA<HistoryEmpty>());

      container.dispose();
    });

    test('fetchOrderById returns OrderLoaded for a valid order', () async {
      final container = ProviderContainer();
      final repo = container.read(cartRepositoryProvider);
      await repo.addItem('cart-1', 'rice');
      final items = await repo.addItem('cart-1', 'milk');
      final order = await repo.placeOrder('cart-1', items);

      final controller = container.read(
        purchaseHistoryControllerProvider.notifier,
      );
      await controller.fetchOrderById(order.orderId);

      final state = container.read(purchaseHistoryControllerProvider);
      expect(state, isA<OrderLoaded>());
      expect((state as OrderLoaded).order.orderId, order.orderId);
      expect((state).order.totalQuantity, 2);

      container.dispose();
    });

    test('fetchOrderById returns OrderNotFound for an unknown order', () async {
      final container = ProviderContainer();

      final controller = container.read(
        purchaseHistoryControllerProvider.notifier,
      );
      await controller.fetchOrderById('SM-UNKNOWN');

      final state = container.read(purchaseHistoryControllerProvider);
      expect(state, isA<OrderNotFound>());

      container.dispose();
    });
  });
}
