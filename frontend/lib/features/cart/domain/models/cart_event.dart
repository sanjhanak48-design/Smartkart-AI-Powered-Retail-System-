import 'cart.dart';

enum CartEventType { itemAdded, itemRemoved, cartCleared, statusChanged }

class CartEvent {
  const CartEvent({
    required this.type,
    this.product,
    this.quantity = 1,
    this.status,
  });

  final CartEventType type;
  final Product? product;
  final int quantity;
  final CartStatus? status;
}
