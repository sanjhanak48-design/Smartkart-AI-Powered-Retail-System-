// Focused widget tests for the SmartCoinsPage and its Profile entry point.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/app.dart';
import 'package:smartkart/core/router/app_router.dart';
import 'package:smartkart/core/theme/app_colors.dart';
import 'package:smartkart/features/auth/data/repositories/auth_repository.dart';
import 'package:smartkart/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:smartkart/features/auth/domain/models/auth_user.dart';
import 'package:smartkart/features/cart/data/repositories/cart_repository.dart';
import 'package:smartkart/features/cart/domain/models/cart.dart';
import 'package:smartkart/features/cart/domain/models/cart_event.dart';
import 'package:smartkart/features/cart/domain/models/order.dart';
import 'package:smartkart/features/cart/presentation/controllers/cart_controller.dart';
import 'package:smartkart/features/rewards/data/repositories/rewards_repository.dart';
import 'package:smartkart/features/rewards/domain/models/smart_coin_transaction.dart';
import 'package:smartkart/features/rewards/presentation/pages/smart_coins_page.dart';

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
  Future<List<Order>> getOrders() async => const [];

  @override
  Future<Order?> getOrderById(String orderId) async => null;

  @override
  Future<List<Product>> getCatalog() async => const [];

  @override
  Stream<CartEvent> watchCart(String cartId) => Stream.empty();
}

class _FakeRewardsRepository implements RewardsRepository {
  _FakeRewardsRepository({
    int initialBalance = 0,
    List<SmartCoinTransaction>? transactions,
  }) : _balance = initialBalance,
       _transactions = transactions ?? [];

  int _balance;
  final List<SmartCoinTransaction> _transactions;
  int _sequence = 0;

  @override
  Future<int> getBalance() async => _balance;

  @override
  Future<List<SmartCoinTransaction>> getTransactions() async =>
      List.unmodifiable(_transactions);

  @override
  Future<SmartCoinTransaction> addCoins({
    required int coins,
    required String description,
  }) async {
    _balance += coins;
    return _record(
      type: SmartCoinTransactionType.earned,
      coins: coins,
      description: description,
    );
  }

  @override
  Future<SmartCoinTransaction> redeemCoins({
    required int coins,
    required String description,
  }) async {
    if (coins > _balance) {
      throw StateError('Insufficient SmartCoins balance');
    }
    _balance -= coins;
    return _record(
      type: SmartCoinTransactionType.redeemed,
      coins: coins,
      description: description,
    );
  }

  SmartCoinTransaction _record({
    required SmartCoinTransactionType type,
    required int coins,
    required String description,
  }) {
    _sequence += 1;
    final transaction = SmartCoinTransaction(
      id: 'SC-${_sequence.toString().padLeft(4, '0')}',
      type: type,
      coins: coins,
      description: description,
      createdAt: DateTime(2026, 2, 1),
    );
    _transactions.insert(0, transaction);
    return transaction;
  }
}

void main() {
  Widget buildPage(RewardsRepository repository) {
    return ProviderScope(
      overrides: [rewardsRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: SmartCoinsPage()),
    );
  }

  testWidgets('SmartCoins page displays the balance and empty history', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildPage(_FakeRewardsRepository(initialBalance: 124)),
    );
    await tester.pumpAndSettle();

    expect(find.text('124'), findsOneWidget);
    expect(find.text('coins'), findsOneWidget);
    expect(
      find.text(
        'No transactions yet. Place an order to start earning '
        'SmartCoins.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('SmartCoins page displays the reward option', (tester) async {
    await tester.pumpWidget(
      buildPage(_FakeRewardsRepository(initialBalance: 124)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rewards'), findsOneWidget);
    expect(find.text('₹10 Store Reward'), findsOneWidget);
    expect(find.text('100 SmartCoins'), findsOneWidget);
    expect(find.text('Redeem'), findsOneWidget);
  });

  testWidgets('successful redemption updates the balance and shows feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildPage(_FakeRewardsRepository(initialBalance: 124)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Redeem'));
    await tester.pumpAndSettle();

    expect(find.text('₹10 Store Reward redeemed!'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('insufficient balance shows appropriate feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildPage(_FakeRewardsRepository(initialBalance: 50)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Redeem'));
    await tester.pumpAndSettle();

    expect(
      find.text('Not enough SmartCoins to redeem this reward.'),
      findsOneWidget,
    );
    expect(find.text('50'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('SmartCoins page displays the transaction history', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildPage(
        _FakeRewardsRepository(
          initialBalance: 24,
          transactions: [
            SmartCoinTransaction(
              id: 'SC-0002',
              type: SmartCoinTransactionType.redeemed,
              coins: 100,
              description: '₹10 Store Reward',
              createdAt: DateTime(2026, 2, 3),
            ),
            SmartCoinTransaction(
              id: 'SC-0001',
              type: SmartCoinTransactionType.earned,
              coins: 124,
              description: 'Order SM-0001',
              createdAt: DateTime(2026, 2, 1),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Transaction History'), findsOneWidget);
    expect(find.text('+124'), findsOneWidget);
    expect(find.text('Order SM-0001'), findsOneWidget);
    expect(find.text('Earned from purchase'), findsOneWidget);
    expect(find.text('-100'), findsOneWidget);
    expect(find.text('Redeemed'), findsOneWidget);
    final redeemedText = tester.widget<Text>(find.text('-100'));
    expect(redeemedText.style?.color, AppColors.error);
  });

  testWidgets('Profile SmartCoins entry navigates to the SmartCoins page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository(_user)),
          cartRepositoryProvider.overrideWithValue(_FakeCartRepository()),
          rewardsRepositoryProvider.overrideWithValue(
            _FakeRewardsRepository(initialBalance: 124),
          ),
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

    expect(find.text('124 coins'), findsOneWidget);
    await tester.tap(find.text('View SmartCoins'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('SmartCoins'),
      ),
      findsOneWidget,
    );
    expect(find.text('124'), findsOneWidget);
    expect(find.text('Rewards'), findsOneWidget);
  });
}
