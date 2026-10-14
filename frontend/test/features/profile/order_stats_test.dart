// Focused unit tests for the OrderStats aggregation model.
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/features/cart/domain/models/cart.dart';
import 'package:smartkart/features/cart/domain/models/order.dart';
import 'package:smartkart/features/profile/domain/models/order_stats.dart';

void main() {
  group('OrderStats', () {
    test('empty orders produce zero statistics', () {
      final stats = OrderStats.fromOrders(const []);

      expect(stats.ordersCount, 0);
      expect(stats.itemsPurchased, 0);
      expect(stats.totalSpent, 0);
    });

    test('multiple orders aggregate counts, items and spend', () {
      const milk = Product(id: 'milk', name: 'Milk', price: 30);
      const bread = Product(id: 'bread', name: 'Bread', price: 40);
      const rice = Product(id: 'rice', name: 'Rice', price: 99);

      final orders = [
        Order(
          orderId: 'SM-0001',
          createdAt: DateTime(2026, 1, 1),
          items: const [
            CartItem(product: milk, quantity: 2),
            CartItem(product: rice, quantity: 1),
          ],
          total: 159,
        ),
        Order(
          orderId: 'SM-0002',
          createdAt: DateTime(2026, 1, 2),
          items: const [
            CartItem(product: bread, quantity: 3),
            CartItem(product: milk, quantity: 1),
          ],
          total: 150,
        ),
      ];

      final stats = OrderStats.fromOrders(orders);

      expect(stats.ordersCount, 2);
      expect(stats.itemsPurchased, 7);
      expect(stats.totalSpent, 309);
    });
  });
}
