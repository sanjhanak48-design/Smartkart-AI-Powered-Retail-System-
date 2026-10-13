import 'dart:async';
import 'dart:math' as math;

import '../../domain/models/cart.dart';
import '../../domain/models/cart_event.dart';
import '../../domain/models/order.dart';

abstract class CartRepository {
  Future<Cart> linkCart(String cartId);

  Future<List<CartItem>> loadCart(String cartId);

  Future<List<CartItem>> addItem(String cartId, String productId);

  Future<List<CartItem>> removeItem(String cartId, String productId);

  Future<List<CartItem>> clearCart(String cartId);

  Future<Order> placeOrder(
    String cartId,
    List<CartItem> items, {
    double discount = 0.0,
  });

  Future<List<Order>> getOrders();

  Future<Order?> getOrderById(String orderId);

  Future<List<Product>> getCatalog();

  Stream<CartEvent> watchCart(String cartId);
}

class MockCartRepository implements CartRepository {
  MockCartRepository() : _items = <CartItem>[], _orders = <Order>[];

  final List<CartItem> _items;
  final List<Order> _orders;
  final StreamController<CartEvent> _cartEvents =
      StreamController<CartEvent>.broadcast();

  /// Simulates a real-time source (for example an RFID reader) emitting a
  /// live cart event. Manual repository operations do not emit events.
  void emitCartEvent(CartEvent event) {
    _cartEvents.add(event);
  }

  void dispose() {
    _cartEvents.close();
  }

  static const Map<String, Product> _catalog = {
    'milk': Product(
      id: 'milk',
      name: 'Milk',
      price: 30,
      category: 'Dairy',
      emojiIcon: '🥛',
    ),
    'bread': Product(
      id: 'bread',
      name: 'Bread',
      price: 40,
      category: 'Bakery',
      emojiIcon: '🍞',
    ),
    'rice': Product(
      id: 'rice',
      name: 'Rice',
      price: 99,
      category: 'Staples',
      emojiIcon: '🍚',
    ),
    'biscuits': Product(
      id: 'biscuits',
      name: 'Biscuits',
      price: 25,
      category: 'Snacks',
      emojiIcon: '🍪',
    ),
    'eggs': Product(
      id: 'eggs',
      name: 'Eggs',
      price: 60,
      category: 'Dairy',
      emojiIcon: '🥚',
    ),
    'cheese': Product(
      id: 'cheese',
      name: 'Cheese',
      price: 120,
      category: 'Dairy',
      emojiIcon: '🧀',
    ),
    'atta': Product(
      id: 'atta',
      name: 'Wheat Atta',
      price: 55,
      category: 'Staples',
      emojiIcon: '🌾',
    ),
    'oil': Product(
      id: 'oil',
      name: 'Cooking Oil',
      price: 110,
      category: 'Staples',
      emojiIcon: '🍶',
    ),
    'chips': Product(
      id: 'chips',
      name: 'Potato Chips',
      price: 30,
      category: 'Snacks',
      emojiIcon: '🍟',
    ),
    'chocolate': Product(
      id: 'chocolate',
      name: 'Chocolate',
      price: 45,
      category: 'Snacks',
      emojiIcon: '🍫',
    ),
    'juice': Product(
      id: 'juice',
      name: 'Orange Juice',
      price: 70,
      category: 'Beverages',
      emojiIcon: '🧃',
    ),
    'tea': Product(
      id: 'tea',
      name: 'Tea',
      price: 50,
      category: 'Beverages',
      emojiIcon: '🍵',
    ),
    'soap': Product(
      id: 'soap',
      name: 'Soap',
      price: 35,
      category: 'Personal Care',
      emojiIcon: '🧼',
    ),
    'shampoo': Product(
      id: 'shampoo',
      name: 'Shampoo',
      price: 85,
      category: 'Personal Care',
      emojiIcon: '🧴',
    ),
  };

  Product _productFor(String productId) {
    final product = _catalog[productId.trim().toLowerCase()];
    if (product == null) {
      throw StateError('Unknown product: $productId');
    }
    return product;
  }

  void _validateCartId(String cartId) {
    if (cartId.trim().isEmpty) {
      throw StateError('Cart ID cannot be empty');
    }
  }

  @override
  Future<Cart> linkCart(String cartId) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _validateCartId(cartId);
    return Cart(cartId: cartId.trim(), status: CartStatus.linked);
  }

  @override
  Future<List<CartItem>> loadCart(String cartId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _validateCartId(cartId);
    return List.unmodifiable(_items);
  }

  @override
  Future<List<CartItem>> addItem(String cartId, String productId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _validateCartId(cartId);
    final product = _productFor(productId);

    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      final existing = _items[index];
      _items[index] = CartItem(
        product: existing.product,
        quantity: existing.quantity + 1,
      );
    } else {
      _items.add(CartItem(product: product, quantity: 1));
    }

    return List.unmodifiable(_items);
  }

  @override
  Future<List<CartItem>> removeItem(String cartId, String productId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _validateCartId(cartId);
    final product = _productFor(productId);

    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index < 0) {
      return List.unmodifiable(_items);
    }

    final existing = _items[index];
    if (existing.quantity <= 1) {
      _items.removeAt(index);
    } else {
      _items[index] = CartItem(
        product: existing.product,
        quantity: math.max(0, existing.quantity - 1),
      );
    }

    return List.unmodifiable(_items);
  }

  @override
  Future<List<CartItem>> clearCart(String cartId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _validateCartId(cartId);
    _items.clear();
    return List.unmodifiable(_items);
  }

  int _orderSequence = 0;

  @override
  Future<Order> placeOrder(
    String cartId,
    List<CartItem> items, {
    double discount = 0.0,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _validateCartId(cartId);
    _orderSequence += 1;
    final orderId = 'SM-${_orderSequence.toString().padLeft(4, '0')}';
    final snapshot = items
        .map((item) => CartItem(product: item.product, quantity: item.quantity))
        .toList();
    final order = Order(
      orderId: orderId,
      createdAt: DateTime.now(),
      items: List.unmodifiable(snapshot),
      total: snapshot.fold(0, (sum, item) => sum + item.lineTotal),
      discount: discount,
    );
    _orders.insert(0, order);
    return order;
  }

  @override
  Future<List<Order>> getOrders() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_orders);
  }

  @override
  Future<Order?> getOrderById(String orderId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    for (final order in _orders) {
      if (order.orderId == orderId) {
        return order;
      }
    }
    return null;
  }

  @override
  Future<List<Product>> getCatalog() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_catalog.values.toList());
  }

  @override
  Stream<CartEvent> watchCart(String cartId) => _cartEvents.stream;
}
