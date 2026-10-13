// Focused unit tests for real-time stream handling in CartController.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/features/cart/data/repositories/cart_repository.dart';
import 'package:smartkart/features/cart/domain/models/cart.dart';
import 'package:smartkart/features/cart/domain/models/cart_event.dart';
import 'package:smartkart/features/cart/presentation/controllers/cart_controller.dart';

void main() {
  const milk = Product(id: 'milk', name: 'Milk', price: 30);
  const bread = Product(id: 'bread', name: 'Bread', price: 40);
  const rice = Product(id: 'rice', name: 'Rice', price: 99);

  MockCartRepository mockRepository(ProviderContainer container) =>
      container.read(cartRepositoryProvider) as MockCartRepository;

  Future<void> openCart(ProviderContainer container) async {
    final controller = container.read(cartControllerProvider.notifier);
    await controller.linkCart('CART-1');
    await controller.openLiveCart();
  }

  Future<void> flushMicrotasks() async {
    await Future<void>.delayed(Duration.zero);
  }

  test('events are ignored before openLiveCart, applied after it', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final repository = mockRepository(container);

    repository.emitCartEvent(
      const CartEvent(type: CartEventType.itemAdded, product: milk),
    );
    await flushMicrotasks();
    expect(container.read(cartControllerProvider), isA<CartInitial>());

    await openCart(container);

    repository.emitCartEvent(
      const CartEvent(type: CartEventType.itemAdded, product: milk),
    );
    await flushMicrotasks();

    final state = container.read(cartControllerProvider);
    expect(state, isA<CartLoaded>());
    final cart = (state as CartLoaded).cart;
    expect(cart.items, hasLength(1));
    expect(cart.items.single.quantity, 1);
  });

  test(
    'streamed itemAdded events merge quantity into an existing row',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repository = mockRepository(container);
      await openCart(container);

      repository.emitCartEvent(
        const CartEvent(
          type: CartEventType.itemAdded,
          product: milk,
          quantity: 2,
        ),
      );
      await flushMicrotasks();
      repository.emitCartEvent(
        const CartEvent(type: CartEventType.itemAdded, product: milk),
      );
      await flushMicrotasks();

      final cart = (container.read(cartControllerProvider) as CartLoaded).cart;
      expect(cart.items, hasLength(1));
      expect(cart.items.single.product.id, 'milk');
      expect(cart.items.single.quantity, 3);
    },
  );

  test('streamed itemRemoved event decrements quantity', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final repository = mockRepository(container);
    await openCart(container);

    repository.emitCartEvent(
      const CartEvent(
        type: CartEventType.itemAdded,
        product: milk,
        quantity: 2,
      ),
    );
    await flushMicrotasks();
    repository.emitCartEvent(
      const CartEvent(type: CartEventType.itemRemoved, product: milk),
    );
    await flushMicrotasks();

    final cart = (container.read(cartControllerProvider) as CartLoaded).cart;
    expect(cart.items, hasLength(1));
    expect(cart.items.single.quantity, 1);
  });

  test(
    'streamed itemRemoved removes item at zero and never goes negative',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repository = mockRepository(container);
      await openCart(container);

      repository.emitCartEvent(
        const CartEvent(type: CartEventType.itemAdded, product: milk),
      );
      await flushMicrotasks();
      repository.emitCartEvent(
        const CartEvent(
          type: CartEventType.itemRemoved,
          product: milk,
          quantity: 10,
        ),
      );
      await flushMicrotasks();

      final cart = (container.read(cartControllerProvider) as CartLoaded).cart;
      expect(cart.items, isEmpty);
    },
  );

  test('streamed cartCleared event empties the cart', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final repository = mockRepository(container);
    await openCart(container);

    repository.emitCartEvent(
      const CartEvent(type: CartEventType.itemAdded, product: milk),
    );
    repository.emitCartEvent(
      const CartEvent(type: CartEventType.itemAdded, product: rice),
    );
    await flushMicrotasks();
    repository.emitCartEvent(const CartEvent(type: CartEventType.cartCleared));
    await flushMicrotasks();

    final cart = (container.read(cartControllerProvider) as CartLoaded).cart;
    expect(cart.items, isEmpty);
    expect(cart.totalQuantity, 0);
  });

  test(
    'streamed statusChanged event updates the status and keeps items',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repository = mockRepository(container);
      await openCart(container);

      repository.emitCartEvent(
        const CartEvent(
          type: CartEventType.itemAdded,
          product: milk,
          quantity: 2,
        ),
      );
      await flushMicrotasks();
      repository.emitCartEvent(
        const CartEvent(
          type: CartEventType.statusChanged,
          status: CartStatus.available,
        ),
      );
      await flushMicrotasks();

      final cart = (container.read(cartControllerProvider) as CartLoaded).cart;
      expect(cart.status, CartStatus.available);
      expect(cart.items, hasLength(1));
      expect(cart.items.single.quantity, 2);
    },
  );

  test(
    'opening the Live Cart twice does not create duplicate subscriptions',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repository = mockRepository(container);
      await openCart(container);
      await openCart(container);

      repository.emitCartEvent(
        const CartEvent(type: CartEventType.itemAdded, product: milk),
      );
      await flushMicrotasks();

      final cart = (container.read(cartControllerProvider) as CartLoaded).cart;
      expect(cart.items, hasLength(1));
      expect(cart.items.single.quantity, 1);
    },
  );

  test('streamed events do not overwrite CartOrderPlaced', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final repository = mockRepository(container);
    await openCart(container);

    final controller = container.read(cartControllerProvider.notifier);
    await controller.simulateAdd('milk');
    await controller.checkout();
    expect(container.read(cartControllerProvider), isA<CartOrderPlaced>());

    repository.emitCartEvent(
      const CartEvent(type: CartEventType.itemAdded, product: bread),
    );
    repository.emitCartEvent(
      const CartEvent(
        type: CartEventType.statusChanged,
        status: CartStatus.available,
      ),
    );
    await flushMicrotasks();

    expect(container.read(cartControllerProvider), isA<CartOrderPlaced>());
  });

  test(
    'existing checkout behavior remains functional while stream is active',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final repository = mockRepository(container);
      await openCart(container);

      repository.emitCartEvent(
        const CartEvent(
          type: CartEventType.itemAdded,
          product: milk,
          quantity: 2,
        ),
      );
      repository.emitCartEvent(
        const CartEvent(type: CartEventType.itemAdded, product: rice),
      );
      await flushMicrotasks();

      final controller = container.read(cartControllerProvider.notifier);
      await controller.checkout();

      final state = container.read(cartControllerProvider);
      expect(state, isA<CartOrderPlaced>());
      final order = (state as CartOrderPlaced).order;
      expect(order.total, 159);
      expect(order.totalQuantity, 3);
    },
  );
}
