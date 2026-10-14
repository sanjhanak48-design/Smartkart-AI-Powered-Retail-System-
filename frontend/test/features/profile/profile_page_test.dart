// Focused widget tests for the ProfilePage account hub.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/app.dart';
import 'package:smartkart/core/router/app_router.dart';
import 'package:smartkart/features/auth/data/repositories/auth_repository.dart';
import 'package:smartkart/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:smartkart/features/auth/domain/models/auth_user.dart';
import 'package:smartkart/features/cart/data/repositories/cart_repository.dart';
import 'package:smartkart/features/cart/domain/models/cart.dart';
import 'package:smartkart/features/cart/domain/models/cart_event.dart';
import 'package:smartkart/features/cart/domain/models/order.dart';
import 'package:smartkart/features/cart/presentation/controllers/cart_controller.dart';
import 'package:smartkart/features/profile/presentation/pages/profile_page.dart';
import 'package:smartkart/features/rewards/data/repositories/rewards_repository.dart';
import 'package:smartkart/features/rewards/domain/models/smart_coin_transaction.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._user);

  AuthUser? _user;
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
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  @override
  Future<AuthUser> verifyOtp(String verificationId, String smsCode) async {
    throw UnimplementedError();
  }
}

class _FakeCartRepository implements CartRepository {
  _FakeCartRepository(this.orders);

  final List<Order> orders;

  @override
  Future<List<Order>> getOrders() async => List.unmodifiable(orders);

  @override
  Future<Order?> getOrderById(String orderId) async {
    for (final order in orders) {
      if (order.orderId == orderId) {
        return order;
      }
    }
    return null;
  }

  @override
  Future<List<Product>> getCatalog() async => const [];

  @override
  Future<Cart> linkCart(String cartId) async =>
      Cart(cartId: cartId, status: CartStatus.linked);

  @override
  Future<List<CartItem>> loadCart(String cartId) async => const [];

  @override
  Future<List<CartItem>> addItem(String cartId, String productId) async =>
      const [];

  @override
  Future<List<CartItem>> removeItem(String cartId, String productId) async =>
      const [];

  @override
  Future<List<CartItem>> clearCart(String cartId) async => const [];

  @override
  Future<Order> placeOrder(
    String cartId,
    List<CartItem> items, {
    double discount = 0.0,
  }) async {
    throw UnimplementedError();
  }

  @override
  Stream<CartEvent> watchCart(String cartId) => Stream.empty();
}

class _FailingOnceCartRepository implements CartRepository {
  _FailingOnceCartRepository(this.orders);

  final List<Order> orders;
  int getOrdersCalls = 0;

  @override
  Future<List<Order>> getOrders() async {
    getOrdersCalls += 1;
    if (getOrdersCalls == 1) {
      throw StateError('history unavailable');
    }
    return List.unmodifiable(orders);
  }

  @override
  Future<Order?> getOrderById(String orderId) async {
    for (final order in orders) {
      if (order.orderId == orderId) {
        return order;
      }
    }
    return null;
  }

  @override
  Future<List<Product>> getCatalog() async => const [];

  @override
  Future<Cart> linkCart(String cartId) async =>
      Cart(cartId: cartId, status: CartStatus.linked);

  @override
  Future<List<CartItem>> loadCart(String cartId) async => const [];

  @override
  Future<List<CartItem>> addItem(String cartId, String productId) async =>
      const [];

  @override
  Future<List<CartItem>> removeItem(String cartId, String productId) async =>
      const [];

  @override
  Future<List<CartItem>> clearCart(String cartId) async => const [];

  @override
  Future<Order> placeOrder(
    String cartId,
    List<CartItem> items, {
    double discount = 0.0,
  }) async {
    throw UnimplementedError();
  }

  @override
  Stream<CartEvent> watchCart(String cartId) => Stream.empty();
}

class _FailingOnceRewardsRepository implements RewardsRepository {
  _FailingOnceRewardsRepository(this.balance, {this.failFirst = true});

  final int balance;
  final bool failFirst;
  int balanceCalls = 0;

  @override
  Future<int> getBalance() async {
    balanceCalls += 1;
    if (failFirst && balanceCalls == 1) {
      throw StateError('rewards unavailable');
    }
    return balance;
  }

  @override
  Future<List<SmartCoinTransaction>> getTransactions() async => const [];

  @override
  Future<SmartCoinTransaction> addCoins({
    required int coins,
    required String description,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<SmartCoinTransaction> redeemCoins({
    required int coins,
    required String description,
  }) async {
    throw UnimplementedError();
  }
}

const _user = AuthUser(
  uid: 'uid-123',
  phone: '+91 9876543210',
  displayName: 'Asha',
);

List<Order> _buildOrders() {
  const milk = Product(id: 'milk', name: 'Milk', price: 30);
  const bread = Product(id: 'bread', name: 'Bread', price: 40);
  const rice = Product(id: 'rice', name: 'Rice', price: 99);
  return [
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
}

void main() {
  void usePhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
  }

  Widget buildProfile({AuthUser? user, required List<Order> orders}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository(user)),
        cartRepositoryProvider.overrideWithValue(_FakeCartRepository(orders)),
      ],
      child: const MaterialApp(home: ProfilePage()),
    );
  }

  testWidgets('ProfilePage renders account information', (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(buildProfile(user: _user, orders: []));
    await tester.pumpAndSettle();

    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('+91 9876543210'), findsOneWidget);
    expect(find.text('uid-123'), findsOneWidget);
  });

  testWidgets('ProfilePage shows order activity summary', (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(buildProfile(user: _user, orders: _buildOrders()));
    await tester.pumpAndSettle();

    expect(find.text('Order Activity'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Total Spent'), findsOneWidget);
    expect(find.text('₹309.00'), findsOneWidget);
  });

  testWidgets('ProfilePage shows empty activity state', (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(buildProfile(user: _user, orders: []));
    await tester.pumpAndSettle();

    expect(find.text('No orders yet.'), findsOneWidget);
    expect(
      find.text('Complete a checkout to see your activity here.'),
      findsOneWidget,
    );
  });

  testWidgets('Profile navigates to Purchase History', (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository(_user)),
          cartRepositoryProvider.overrideWithValue(_FakeCartRepository([])),
        ],
        child: const SmartKartApp(),
      ),
    );
    await tester.pumpAndSettle();

    final router = ProviderScope.containerOf(
      tester.element(find.byType(SmartKartApp)),
    ).read(appRouterProvider);
    router.go('/profile');
    await tester.pumpAndSettle();

    await tester.tap(find.text('View Purchase History'));
    await tester.pumpAndSettle();

    expect(find.text('Purchase History'), findsOneWidget);
    expect(find.text('No orders yet'), findsOneWidget);
  });

  testWidgets('Sign Out redirects to login', (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository(_user)),
          cartRepositoryProvider.overrideWithValue(_FakeCartRepository([])),
        ],
        child: const SmartKartApp(),
      ),
    );
    await tester.pumpAndSettle();

    final router = ProviderScope.containerOf(
      tester.element(find.byType(SmartKartApp)),
    ).read(appRouterProvider);
    router.go('/profile');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to start shopping'), findsOneWidget);
  });

  testWidgets('Profile history error shows a Retry that recovers', (
    tester,
  ) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository(_user)),
          cartRepositoryProvider.overrideWithValue(
            _FailingOnceCartRepository(_buildOrders()),
          ),
          rewardsRepositoryProvider.overrideWithValue(
            _FailingOnceRewardsRepository(0, failFirst: false),
          ),
        ],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to load order history. Please try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('Profile SmartCoins error shows a Retry that recovers', (
    tester,
  ) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository(_user)),
          cartRepositoryProvider.overrideWithValue(_FakeCartRepository([])),
          rewardsRepositoryProvider.overrideWithValue(
            _FailingOnceRewardsRepository(259),
          ),
        ],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to load SmartCoins. Please try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('259 coins'), findsOneWidget);
  });
}
