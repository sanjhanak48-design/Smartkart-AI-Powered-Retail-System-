// Focused unit test for the CartController cart-linking flow.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/features/cart/presentation/controllers/cart_controller.dart';
import 'package:smartkart/features/cart/domain/models/cart.dart';

void main() {
  Future<ProviderContainer> setupPopulatedCart() async {
    final container = ProviderContainer();
    final controller = container.read(cartControllerProvider.notifier);
    await controller.linkCart('CART-1');
    await controller.openLiveCart();
    await controller.simulateAdd('milk');
    await controller.simulateAdd('milk');
    await controller.simulateAdd('rice');
    return container;
  }

  test('linkCart links a valid cart ID', () async {
    final container = ProviderContainer();

    final controller = container.read(cartControllerProvider.notifier);
    await controller.linkCart('CART-123');

    final state = container.read(cartControllerProvider);
    expect(state, isA<CartLinked>());
    final linked = state as CartLinked;
    expect(linked.cart.cartId, 'CART-123');
    expect(linked.cart.status, CartStatus.linked);

    container.dispose();
  });

  test('linkCart reports an error for an empty cart ID', () async {
    final container = ProviderContainer();

    final controller = container.read(cartControllerProvider.notifier);
    await controller.linkCart('   ');

    final state = container.read(cartControllerProvider);
    expect(state, isA<CartError>());

    container.dispose();
  });

  test('clearCart clears items after a cart is linked and populated', () async {
    final container = ProviderContainer();

    final controller = container.read(cartControllerProvider.notifier);
    await controller.linkCart('CART-1');
    await controller.openLiveCart();
    await controller.simulateAdd('milk');
    await controller.simulateAdd('bread');
    await controller.clearCart();

    final state = container.read(cartControllerProvider);
    expect(state, isA<CartLoaded>());
    final loaded = state as CartLoaded;
    expect(loaded.cart.items, isEmpty);
    expect(loaded.cart.status, CartStatus.linked);
    expect(loaded.cart.cartId, 'CART-1');

    container.dispose();
  });

  test('checkout places an order snapshot with the correct total', () async {
    final container = await setupPopulatedCart();

    final controller = container.read(cartControllerProvider.notifier);
    await controller.checkout();

    final state = container.read(cartControllerProvider);
    expect(state, isA<CartOrderPlaced>());
    final placed = state as CartOrderPlaced;
    expect(placed.order.orderId, isNotEmpty);
    expect(placed.order.totalQuantity, 3);
    expect(placed.order.total, 159);

    container.dispose();
  });

  test('checkout rejects an empty cart', () async {
    final container = ProviderContainer();
    final controller = container.read(cartControllerProvider.notifier);
    await controller.linkCart('CART-1');
    await controller.openLiveCart();
    await controller.checkout();

    final state = container.read(cartControllerProvider);
    expect(state, isA<CartError>());

    container.dispose();
  });

  test(
    'completeOrder clears the cart and preserves the linked state',
    () async {
      final container = await setupPopulatedCart();
      final controller = container.read(cartControllerProvider.notifier);
      await controller.checkout();

      await controller.completeOrder();

      final state = container.read(cartControllerProvider);
      expect(state, isA<CartLoaded>());
      final loaded = state as CartLoaded;
      expect(loaded.cart.items, isEmpty);
      expect(loaded.cart.status, CartStatus.linked);
      expect(loaded.cart.cartId, 'CART-1');

      container.dispose();
    },
  );
}
