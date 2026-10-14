import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../rewards/presentation/controllers/rewards_controller.dart';
import '../../data/repositories/cart_repository.dart';
import '../../domain/models/cart.dart';
import '../../domain/models/cart_event.dart';
import '../../domain/models/order.dart';

sealed class CartState {
  const CartState();
}

class CartInitial extends CartState {
  const CartInitial();
}

class CartLinking extends CartState {
  const CartLinking();
}

class CartLinked extends CartState {
  const CartLinked(this.cart);

  final Cart cart;
}

class CartLoading extends CartState {
  const CartLoading();
}

class CartLoaded extends CartState {
  const CartLoaded(this.cart);

  final Cart cart;
}

class CartError extends CartState {
  const CartError(this.message);

  final String message;
}

class CartOrderPlaced extends CartState {
  const CartOrderPlaced(this.order);

  final Order order;
}

class CartController extends Notifier<CartState> {
  late final CartRepository _cartRepository;
  Cart? _linkedCart;
  bool _busy = false;
  double _rewardDiscount = 0.0;
  StreamSubscription<CartEvent>? _eventSubscription;

  double get rewardDiscount => _rewardDiscount;

  /// Final payable amount: cart total minus the applied Store Reward discount,
  /// clamped to zero. Shared by Checkout and Payment so the price never drifts.
  double get checkoutTotal {
    final current = state;
    final total = current is CartLoaded ? current.cart.total : 0.0;
    final payable = total - _rewardDiscount;
    return payable < 0 ? 0.0 : payable;
  }

  @override
  CartState build() {
    _cartRepository = ref.watch(cartRepositoryProvider);
    ref.onDispose(() {
      _eventSubscription?.cancel();
    });
    return const CartInitial();
  }

  Future<void> linkCart(String cartId) async {
    final id = cartId.trim();
    if (id.isEmpty) {
      state = const CartError('Please enter a Cart ID.');
      return;
    }

    state = const CartLinking();
    try {
      final cart = await _cartRepository.linkCart(id);
      _linkedCart = cart;
      state = CartLinked(cart);
    } catch (_) {
      state = const CartError('Unable to link the cart. Please try again.');
    }
  }

  Future<void> openLiveCart() async {
    final linkedCart = _linkedCart;
    if (linkedCart == null) {
      state = const CartError('No cart linked yet. Please link a cart first.');
      return;
    }

    state = const CartLoading();
    try {
      final items = await _cartRepository.loadCart(linkedCart.cartId);
      _subscribeToEvents(linkedCart.cartId);
      state = CartLoaded(
        Cart(
          cartId: linkedCart.cartId,
          status: linkedCart.status,
          items: items,
        ),
      );
    } catch (_) {
      state = const CartError('Unable to load the cart. Please try again.');
    }
  }

  void _subscribeToEvents(String cartId) {
    _eventSubscription?.cancel();
    _eventSubscription = _cartRepository.watchCart(cartId).listen(_onCartEvent);
  }

  void _onCartEvent(CartEvent event) {
    final linkedCart = _linkedCart;
    if (linkedCart == null) {
      return;
    }
    if (state is CartOrderPlaced) {
      return;
    }

    final currentState = state;
    final currentStatus = currentState is CartLoaded
        ? currentState.cart.status
        : linkedCart.status;
    final status = event.type == CartEventType.statusChanged
        ? (event.status ?? currentStatus)
        : currentStatus;

    var items = currentState is CartLoaded
        ? currentState.cart.items
        : <CartItem>[];

    switch (event.type) {
      case CartEventType.itemAdded:
        final product = event.product;
        if (product != null) {
          items = _increment(items, product, event.quantity);
        }
      case CartEventType.itemRemoved:
        final product = event.product;
        if (product != null) {
          items = _decrement(items, product, event.quantity);
        }
      case CartEventType.cartCleared:
        items = const [];
      case CartEventType.statusChanged:
        break;
    }

    state = CartLoaded(
      Cart(cartId: linkedCart.cartId, status: status, items: items),
    );
  }

  List<CartItem> _increment(
    List<CartItem> items,
    Product product,
    int quantity,
  ) {
    final qty = quantity > 0 ? quantity : 1;
    final index = items.indexWhere((item) => item.product.id == product.id);
    if (index < 0) {
      return [...items, CartItem(product: product, quantity: qty)];
    }
    final updated = [...items];
    final existing = updated[index];
    updated[index] = CartItem(
      product: existing.product,
      quantity: existing.quantity + qty,
    );
    return updated;
  }

  List<CartItem> _decrement(
    List<CartItem> items,
    Product product,
    int quantity,
  ) {
    final index = items.indexWhere((item) => item.product.id == product.id);
    if (index < 0) {
      return items;
    }
    final qty = quantity > 0 ? quantity : 1;
    final updated = [...items];
    final existing = updated[index];
    if (existing.quantity <= qty) {
      updated.removeAt(index);
    } else {
      updated[index] = CartItem(
        product: existing.product,
        quantity: existing.quantity - qty,
      );
    }
    return updated;
  }

  Future<void> simulateAdd(String productId) async {
    if (_busy) {
      return;
    }
    final linkedCart = _linkedCart;
    if (linkedCart == null) {
      state = const CartError('No cart linked yet. Please link a cart first.');
      return;
    }

    _busy = true;
    try {
      final items = await _cartRepository.addItem(linkedCart.cartId, productId);
      state = CartLoaded(
        Cart(
          cartId: linkedCart.cartId,
          status: linkedCart.status,
          items: items,
        ),
      );
    } catch (_) {
      state = const CartError('Unable to add the product. Please try again.');
    } finally {
      _busy = false;
    }
  }

  Future<void> simulateRemove(String productId) async {
    if (_busy) {
      return;
    }
    final linkedCart = _linkedCart;
    if (linkedCart == null) {
      state = const CartError('No cart linked yet. Please link a cart first.');
      return;
    }

    _busy = true;
    try {
      final items = await _cartRepository.removeItem(
        linkedCart.cartId,
        productId,
      );
      state = CartLoaded(
        Cart(
          cartId: linkedCart.cartId,
          status: linkedCart.status,
          items: items,
        ),
      );
    } catch (_) {
      state = const CartError(
        'Unable to remove the product. Please try again.',
      );
    } finally {
      _busy = false;
    }
  }

  Future<bool> applyStoreReward() async {
    if (_rewardDiscount > 0) {
      return true;
    }
    final rewards = ref.read(rewardsControllerProvider.notifier);
    if (rewards.pendingStoreRewards > 0) {
      _rewardDiscount = 10.0;
      return true;
    }
    final result = await rewards.redeemStoreReward();
    if (result.isSuccessful) {
      _rewardDiscount = 10.0;
      return true;
    }
    return false;
  }

  Future<void> removeStoreReward() async {
    if (_rewardDiscount <= 0) {
      return;
    }
    _rewardDiscount = 0.0;
    await ref.read(rewardsControllerProvider.notifier).reverseRedemption();
  }

  Future<void> clearCart() async {
    if (_busy) {
      return;
    }
    final linkedCart = _linkedCart;
    if (linkedCart == null) {
      state = const CartError('No cart linked yet. Please link a cart first.');
      return;
    }

    _busy = true;
    try {
      await _cartRepository.clearCart(linkedCart.cartId);
      _rewardDiscount = 0.0;
      state = CartLoaded(
        Cart(
          cartId: linkedCart.cartId,
          status: linkedCart.status,
          items: const [],
        ),
      );
    } catch (_) {
      state = const CartError('Unable to clear the cart. Please try again.');
    } finally {
      _busy = false;
    }
  }

  Future<void> checkout() async {
    if (_busy) {
      return;
    }
    if (state is! CartLoaded) {
      return;
    }
    final loaded = state as CartLoaded;
    if (loaded.cart.items.isEmpty) {
      state = const CartError('Your cart is empty. Add products to checkout.');
      return;
    }

    _busy = true;
    final rewardDiscount = _rewardDiscount;
    try {
      final order = await _cartRepository.placeOrder(
        loaded.cart.cartId,
        loaded.cart.items,
        discount: rewardDiscount,
      );
      state = CartOrderPlaced(order);
      _rewardDiscount = 0.0;
      await ref
          .read(rewardsControllerProvider.notifier)
          .awardCoinsForOrder(order);
      ref.read(rewardsControllerProvider.notifier).consumeStoreReward();
    } catch (_) {
      state = const CartError('Unable to place the order. Please try again.');
    } finally {
      _busy = false;
    }
  }

  Future<void> completeOrder() async {
    if (_busy) {
      return;
    }
    final linkedCart = _linkedCart;
    if (linkedCart == null) {
      state = const CartError('No cart linked yet. Please link a cart first.');
      return;
    }

    _busy = true;
    try {
      await _cartRepository.clearCart(linkedCart.cartId);
      _rewardDiscount = 0.0;
      state = CartLoaded(
        Cart(
          cartId: linkedCart.cartId,
          status: linkedCart.status,
          items: const [],
        ),
      );
    } catch (_) {
      state = const CartError('Unable to finish the order. Please try again.');
    } finally {
      _busy = false;
    }
  }
}

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => MockCartRepository(),
);

final cartControllerProvider = NotifierProvider<CartController, CartState>(
  CartController.new,
);
