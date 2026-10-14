// Focused unit tests for the live cart mock repository and model.
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/features/cart/data/repositories/cart_repository.dart';
import 'package:smartkart/features/cart/domain/models/cart.dart';
import 'package:smartkart/features/cart/domain/models/order.dart';

void main() {
  group('Order model', () {
    test('captures a snapshot with correct total and quantity', () {
      const milk = Product(id: 'milk', name: 'Milk', price: 30);
      const rice = Product(id: 'rice', name: 'Rice', price: 99);
      final order = Order(
        orderId: 'SM-0001',
        createdAt: DateTime(2026, 1, 1, 10, 30),
        items: const [
          CartItem(product: milk, quantity: 2),
          CartItem(product: rice, quantity: 1),
        ],
        total: 159,
      );

      expect(order.totalQuantity, 3);
      expect(order.total, 159);
      expect(order.orderId, 'SM-0001');
    });

    test('does not reflect later mutation of source items', () {
      const milk = Product(id: 'milk', name: 'Milk', price: 30);
      final source = [CartItem(product: milk, quantity: 1)];
      final order = Order(
        orderId: 'SM-0002',
        createdAt: DateTime(2026, 1, 1),
        items: List.of(source),
        total: 30,
      );

      source.add(const CartItem(product: milk, quantity: 1));
      expect(order.items, hasLength(1));
      expect(order.total, 30);
    });
  });

  group('MockCartRepository', () {
    test('loadCart starts empty', () async {
      final repo = MockCartRepository();
      final items = await repo.loadCart('cart-1');
      expect(items, isEmpty);
    });

    test('adding a valid product creates a CartItem with quantity 1', () async {
      final repo = MockCartRepository();
      final items = await repo.addItem('cart-1', 'milk');

      expect(items, hasLength(1));
      expect(items.first.product.name, 'Milk');
      expect(items.first.quantity, 1);
      expect(items.first.lineTotal, 30);
    });

    test('adding the same product again increments quantity to 2', () async {
      final repo = MockCartRepository();
      await repo.addItem('cart-1', 'milk');
      final items = await repo.addItem('cart-1', 'milk');

      expect(items, hasLength(1));
      expect(items.first.quantity, 2);
      expect(items.first.lineTotal, 60);
    });

    test('removeItem decrements quantity and removes at zero', () async {
      final repo = MockCartRepository();
      await repo.addItem('cart-1', 'bread');
      await repo.addItem('cart-1', 'bread');

      var items = await repo.removeItem('cart-1', 'bread');
      expect(items.first.quantity, 1);

      items = await repo.removeItem('cart-1', 'bread');
      expect(items, isEmpty);
    });

    test('cart total is calculated correctly across items', () async {
      final repo = MockCartRepository();
      // Milk x2 = 60, Rice x1 = 99 -> total 159
      await repo.addItem('cart-1', 'milk');
      await repo.addItem('cart-1', 'milk');
      final items = await repo.addItem('cart-1', 'rice');

      final cart = Cart(
        cartId: 'cart-1',
        status: CartStatus.linked,
        items: items,
      );
      expect(cart.total, 159);
    });

    test('invalid product id produces a controlled error', () async {
      final repo = MockCartRepository();
      await expectLater(
        () => repo.addItem('cart-1', 'unknown'),
        throwsA(isA<StateError>()),
      );
    });

    test('cart total quantity is correct', () async {
      final repo = MockCartRepository();
      await repo.addItem('cart-1', 'milk');
      await repo.addItem('cart-1', 'milk');
      final items = await repo.addItem('cart-1', 'rice');

      final cart = Cart(
        cartId: 'cart-1',
        status: CartStatus.linked,
        items: items,
      );
      expect(cart.totalQuantity, 3);
    });

    test('clearCart empties the repository after products are added', () async {
      final repo = MockCartRepository();
      await repo.addItem('cart-1', 'milk');
      await repo.addItem('cart-1', 'bread');

      final cleared = await repo.clearCart('cart-1');
      expect(cleared, isEmpty);
    });

    test('placeOrder returns an order snapshot of the cart items', () async {
      final repo = MockCartRepository();
      final items = await repo.addItem('cart-1', 'milk');
      await repo.addItem('cart-1', 'milk');
      final itemsAfter = await repo.addItem('cart-1', 'rice');

      final order = await repo.placeOrder('cart-1', itemsAfter);
      expect(order.orderId, isNotEmpty);
      expect(order.items, hasLength(2));
      expect(order.totalQuantity, 3);
      expect(order.total, 159);
      // Snapshot is independent of the original list reference.
      expect(identical(order.items, itemsAfter), isFalse);
      // items list before final add is unaffected by the snapshot.
      expect(items, hasLength(1));
    });

    test('getCatalog returns the full expanded catalog', () async {
      final repo = MockCartRepository();
      final catalog = await repo.getCatalog();

      expect(catalog.map((product) => product.name), [
        'Milk',
        'Bread',
        'Rice',
        'Biscuits',
        'Eggs',
        'Cheese',
        'Wheat Atta',
        'Cooking Oil',
        'Potato Chips',
        'Chocolate',
        'Orange Juice',
        'Tea',
        'Soap',
        'Shampoo',
      ]);
    });

    test('getCatalog returned list cannot be modified', () async {
      final repo = MockCartRepository();
      final catalog = await repo.getCatalog();

      expect(
        () => catalog.add(const Product(id: 'chips', name: 'Chips', price: 20)),
        throwsUnsupportedError,
      );
    });
  });
}
