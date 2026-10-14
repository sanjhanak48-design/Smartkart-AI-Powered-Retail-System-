// Focused widget tests for the SmartPicksPage and its navigation entry point.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/app.dart';
import 'package:smartkart/features/auth/data/repositories/auth_repository.dart';
import 'package:smartkart/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:smartkart/features/auth/domain/models/auth_user.dart';
import 'package:smartkart/features/cart/data/repositories/cart_repository.dart';
import 'package:smartkart/features/cart/domain/models/cart.dart';
import 'package:smartkart/features/cart/domain/models/cart_event.dart';
import 'package:smartkart/features/cart/domain/models/order.dart';
import 'package:smartkart/features/cart/presentation/controllers/cart_controller.dart';
import 'package:smartkart/features/recommendations/data/repositories/recommendation_repository.dart';
import 'package:smartkart/features/recommendations/domain/models/recommended_item.dart';
import 'package:smartkart/features/recommendations/presentation/pages/smart_picks_page.dart';

const _milk = Product(id: 'milk', name: 'Milk', price: 30);
const _bread = Product(id: 'bread', name: 'Bread', price: 40);
const _rice = Product(id: 'rice', name: 'Rice', price: 99);
const _biscuits = Product(id: 'biscuits', name: 'Biscuits', price: 25);

const _user = AuthUser(
  uid: 'uid-123',
  phone: '+91 9876543210',
  displayName: 'Asha',
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._user);

  final AuthUser? _user;
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  @override
  String? get verificationId => null;

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  @override
  AuthUser? getUser() => _user;

  @override
  Future<String?> getIdToken() async => null;

  @override
  Future<void> sendOtp(String phone) async {}

  @override
  Future<void> resendOtp(String phone) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthUser> verifyOtp(String verificationId, String smsCode) async {
    throw UnimplementedError();
  }
}

class _FakeCartRepository implements CartRepository {
  final List<Product> _catalog = const [_milk, _bread, _rice, _biscuits];
  final List<CartItem> _items = [];
  final List<String> addedIds = [];

  @override
  Future<Cart> linkCart(String cartId) async =>
      Cart(cartId: cartId, status: CartStatus.linked);

  @override
  Future<List<CartItem>> loadCart(String cartId) async =>
      List.unmodifiable(_items);

  @override
  Future<List<CartItem>> addItem(String cartId, String productId) async {
    addedIds.add(productId);
    final product = _catalog.firstWhere((p) => p.id == productId);
    final index = _items.indexWhere((item) => item.product.id == productId);
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
  Future<List<CartItem>> removeItem(String cartId, String productId) async =>
      List.unmodifiable(_items);

  @override
  Future<List<CartItem>> clearCart(String cartId) async {
    _items.clear();
    return const [];
  }

  @override
  Future<Order> placeOrder(
    String cartId,
    List<CartItem> items, {
    double discount = 0.0,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Order>> getOrders() async => const [];

  @override
  Future<Order?> getOrderById(String orderId) async => null;

  @override
  Future<List<Product>> getCatalog() async => List.unmodifiable(_catalog);

  @override
  Stream<CartEvent> watchCart(String cartId) => Stream.empty();
}

class _FakeRecommendationRepository implements RecommendationRepository {
  _FakeRecommendationRepository(this.result);

  final List<RecommendedItem> result;

  @override
  Future<List<RecommendedItem>> fetchRecommendations({
    required List<CartItem> cartItems,
  }) async {
    return List.unmodifiable(result);
  }
}

class _FlakyRecommendationRepository implements RecommendationRepository {
  _FlakyRecommendationRepository(this.items);

  final List<RecommendedItem> items;
  int calls = 0;

  @override
  Future<List<RecommendedItem>> fetchRecommendations({
    required List<CartItem> cartItems,
  }) async {
    calls += 1;
    if (calls == 1) {
      throw StateError('recommendations temporarily unavailable');
    }
    return List.unmodifiable(items);
  }
}

void main() {
  Widget buildPage({
    required CartRepository cartRepository,
    required RecommendationRepository recommendationRepository,
  }) {
    return ProviderScope(
      overrides: [
        cartRepositoryProvider.overrideWithValue(cartRepository),
        recommendationRepositoryProvider.overrideWithValue(
          recommendationRepository,
        ),
      ],
      child: const MaterialApp(home: SmartPicksPage()),
    );
  }

  testWidgets('Smart Picks renders recommendations with reason chips', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildPage(
        cartRepository: _FakeCartRepository(),
        recommendationRepository: _FakeRecommendationRepository(const [
          RecommendedItem(product: _milk, reason: 'Popular choice', score: 2),
          RecommendedItem(product: _rice, reason: 'Featured for you', score: 0),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('₹30.00'), findsOneWidget);
    expect(find.text('Popular choice'), findsOneWidget);
    expect(find.text('Rice'), findsOneWidget);
    expect(find.text('Featured for you'), findsOneWidget);
    expect(find.text('+ Add'), findsNWidgets(2));
  });

  testWidgets('Add button calls simulateAdd and shows a SnackBar', (
    tester,
  ) async {
    final fakeCart = _FakeCartRepository();
    final container = ProviderContainer(
      overrides: [
        cartRepositoryProvider.overrideWithValue(fakeCart),
        recommendationRepositoryProvider.overrideWithValue(
          _FakeRecommendationRepository(const [
            RecommendedItem(product: _milk, reason: 'Popular choice', score: 2),
            RecommendedItem(
              product: _biscuits,
              reason: 'Featured for you',
              score: 0,
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.runAsync(() async {
      final cartController = container.read(cartControllerProvider.notifier);
      await cartController.linkCart('CART-1');
      await cartController.openLiveCart();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SmartPicksPage()),
      ),
    );
    await tester.pumpAndSettle();

    final addButton = find.descendant(
      of: find.ancestor(of: find.text('Milk'), matching: find.byType(Card)),
      matching: find.text('+ Add'),
    );
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(fakeCart.addedIds, contains('milk'));
    expect(find.text('Milk added to your cart'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('Empty state renders when no recommendations are available', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildPage(
        cartRepository: _FakeCartRepository(),
        recommendationRepository: _FakeRecommendationRepository([]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No recommendations right now'), findsOneWidget);
    expect(
      find.text('Try linking a cart and adding a few products.'),
      findsOneWidget,
    );
    expect(find.text('Go Home'), findsOneWidget);
  });

  testWidgets('Error shows Retry and a second attempt refetches', (
    tester,
  ) async {
    final flakyRepository = _FlakyRecommendationRepository(const [
      RecommendedItem(product: _milk, reason: 'Popular choice', score: 1),
    ]);

    await tester.pumpWidget(
      buildPage(
        cartRepository: _FakeCartRepository(),
        recommendationRepository: flakyRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to load recommendations. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(flakyRepository.calls, 2);
    expect(find.text('Milk'), findsOneWidget);
  });

  testWidgets('CartInitial displays the Link Cart banner', (tester) async {
    await tester.pumpWidget(
      buildPage(
        cartRepository: _FakeCartRepository(),
        recommendationRepository: _FakeRecommendationRepository(const [
          RecommendedItem(product: _milk, reason: 'Popular choice', score: 1),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Link a cart to add recommended items.'), findsOneWidget);
    expect(find.text('Link Cart'), findsOneWidget);
  });

  testWidgets('Home Smart Picks card navigates to the Smart Picks page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final fakeCart = _FakeCartRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository(_user)),
          cartRepositoryProvider.overrideWithValue(fakeCart),
          recommendationRepositoryProvider.overrideWithValue(
            _FakeRecommendationRepository(const [
              RecommendedItem(
                product: _milk,
                reason: 'Popular choice',
                score: 2,
              ),
              RecommendedItem(
                product: _biscuits,
                reason: 'Featured for you',
                score: 0,
              ),
            ]),
          ),
        ],
        child: const SmartKartApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Smart Picks'), findsOneWidget);
    await tester.tap(find.text('See Recommendations'));
    await tester.pumpAndSettle();

    expect(find.text('Smart Picks'), findsOneWidget);
    expect(find.text('Popular choice'), findsOneWidget);
    expect(find.text('Link a cart to add recommended items.'), findsOneWidget);
  });
}
