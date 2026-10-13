import '../../../cart/domain/models/order.dart';

class OrderStats {
  const OrderStats({
    required this.ordersCount,
    required this.itemsPurchased,
    required this.totalSpent,
  });

  final int ordersCount;
  final int itemsPurchased;
  final double totalSpent;

  factory OrderStats.fromOrders(List<Order> orders) {
    var items = 0;
    var total = 0.0;
    for (final order in orders) {
      items += order.totalQuantity;
      total += order.totalAfterDiscount;
    }
    return OrderStats(
      ordersCount: orders.length,
      itemsPurchased: items,
      totalSpent: total,
    );
  }
}
