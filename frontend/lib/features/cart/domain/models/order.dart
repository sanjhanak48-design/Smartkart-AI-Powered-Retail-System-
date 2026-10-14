import 'dart:math' as math;

import 'cart.dart';

class Order {
  const Order({
    required this.orderId,
    required this.createdAt,
    required this.items,
    required this.total,
    this.discount = 0.0,
  });

  final String orderId;
  final DateTime createdAt;
  final List<CartItem> items;
  final double total;
  final double discount;

  double get totalAfterDiscount => math.max(0, total - discount);

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
}
