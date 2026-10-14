enum CartStatus { available, linked }

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.category = '',
    this.emojiIcon,
  });

  final String id;
  final String name;
  final double price;
  final String category;
  final String? emojiIcon;
}

class CartItem {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get lineTotal => product.price * quantity;
}

class Cart {
  const Cart({
    required this.cartId,
    required this.status,
    this.items = const [],
  });

  final String cartId;
  final CartStatus status;
  final List<CartItem> items;

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  double get total => items.fold(0, (sum, item) => sum + item.lineTotal);

  Cart copyWith({CartStatus? status, List<CartItem>? items}) {
    return Cart(
      cartId: cartId,
      status: status ?? this.status,
      items: items ?? this.items,
    );
  }
}
