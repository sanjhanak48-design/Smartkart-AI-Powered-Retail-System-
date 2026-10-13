// Focused unit tests for the mock real-time cart event stream.
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/features/cart/data/repositories/cart_repository.dart';
import 'package:smartkart/features/cart/domain/models/cart.dart';
import 'package:smartkart/features/cart/domain/models/cart_event.dart';

void main() {
  const milk = Product(id: 'milk', name: 'Milk', price: 30);
  const bread = Product(id: 'bread', name: 'Bread', price: 40);

  Future<void> flushMicrotasks() async {
    await Future<void>.delayed(Duration.zero);
  }

  test('watchCart returns a stream for a cart', () {
    final repository = MockCartRepository();

    final stream = repository.watchCart('cart-1');

    expect(stream, isA<Stream<CartEvent>>());
  });

  test('itemAdded event is emitted correctly', () async {
    final repository = MockCartRepository();
    final events = <CartEvent>[];
    final subscription = repository.watchCart('cart-1').listen(events.add);
    addTearDown(subscription.cancel);

    repository.emitCartEvent(
      const CartEvent(
        type: CartEventType.itemAdded,
        product: milk,
        quantity: 2,
      ),
    );
    await flushMicrotasks();

    expect(events, hasLength(1));
    expect(events.single.type, CartEventType.itemAdded);
    expect(events.single.product?.id, 'milk');
    expect(events.single.product?.name, 'Milk');
    expect(events.single.quantity, 2);
  });

  test('itemRemoved event is emitted correctly', () async {
    final repository = MockCartRepository();
    final events = <CartEvent>[];
    final subscription = repository.watchCart('cart-1').listen(events.add);
    addTearDown(subscription.cancel);

    repository.emitCartEvent(
      const CartEvent(
        type: CartEventType.itemRemoved,
        product: bread,
        quantity: 1,
      ),
    );
    await flushMicrotasks();

    expect(events, hasLength(1));
    expect(events.single.type, CartEventType.itemRemoved);
    expect(events.single.product?.id, 'bread');
    expect(events.single.quantity, 1);
  });

  test('cartCleared event is emitted correctly', () async {
    final repository = MockCartRepository();
    final events = <CartEvent>[];
    final subscription = repository.watchCart('cart-1').listen(events.add);
    addTearDown(subscription.cancel);

    repository.emitCartEvent(const CartEvent(type: CartEventType.cartCleared));
    await flushMicrotasks();

    expect(events, hasLength(1));
    expect(events.single.type, CartEventType.cartCleared);
  });

  test('statusChanged event is emitted correctly', () async {
    final repository = MockCartRepository();
    final events = <CartEvent>[];
    final subscription = repository.watchCart('cart-1').listen(events.add);
    addTearDown(subscription.cancel);

    repository.emitCartEvent(
      const CartEvent(
        type: CartEventType.statusChanged,
        status: CartStatus.available,
      ),
    );
    await flushMicrotasks();

    expect(events, hasLength(1));
    expect(events.single.type, CartEventType.statusChanged);
    expect(events.single.status, CartStatus.available);
  });

  test('manual repository operations do not emit stream events', () async {
    final repository = MockCartRepository();
    final events = <CartEvent>[];
    final subscription = repository.watchCart('cart-1').listen(events.add);
    addTearDown(subscription.cancel);

    await repository.addItem('cart-1', 'milk');
    await repository.addItem('cart-1', 'bread');
    await repository.removeItem('cart-1', 'bread');
    await repository.clearCart('cart-1');

    expect(events, isEmpty);
  });
}
