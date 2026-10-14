// Widget tests for the Store Reward discount flow across checkout, receipt,
// order details, purchase history and profile stats.
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
import 'package:smartkart/features/cart/domain/models/order.dart';
import 'package:smartkart/features/cart/presentation/controllers/cart_controller.dart';
import 'package:smartkart/features/cart/presentation/pages/checkout_page.dart';
import 'package:smartkart/features/rewards/presentation/controllers/rewards_controller.dart';

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

Order _seedOrder({double total = 129}) {
  return Order(
    orderId: 'SEED-1',
    createdAt: DateTime(2026, 2, 1),
    items: const [
      CartItem(
        product: Product(id: 'milk', name: 'Milk', price: 30),
        quantity: 1,
      ),
      CartItem(
        product: Product(id: 'rice', name: 'Rice', price: 99),
        quantity: 1,
      ),
    ],
    total: total,
  );
}

void usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

/// Advances the fake clock past the mock repository delays (payment 400ms then
/// checkout incl. reward reloads ~700ms) before letting scheduled frames
/// settle. pumpAndSettle alone can stop early because pending repo timers do
/// not always schedule frames.
Future<void> settleAsync(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 1200));
  await tester.pumpAndSettle();
}

/// Runs the Store Reward checkout through the new payment step: taps the
/// Checkout pay CTA, waits on PaymentPage, then taps the simulated payment.
Future<void> payThroughPayment(WidgetTester tester, String amount) async {
  await tester.tap(find.text('Pay ₹$amount'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Pay ₹$amount'));
  await settleAsync(tester);
}

Future<ProviderContainer> seedCartAndRewards(
  WidgetTester tester, {
  double seedTotal = 129,
  bool preRedeem = false,
}) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository(_user)),
    ],
  );
  addTearDown(container.dispose);
  await tester.runAsync(() async {
    final rewards = container.read(rewardsControllerProvider.notifier);
    await rewards.awardCoinsForOrder(_seedOrder(total: seedTotal));
    if (preRedeem) {
      await rewards.redeemStoreReward();
    }
    final cart = container.read(cartControllerProvider.notifier);
    await cart.linkCart('CART-1');
    await cart.openLiveCart();
    await cart.simulateAdd('milk');
    await cart.simulateAdd('rice');
  });
  return container;
}

void main() {
  group('Checkout Store Reward option', () {
    Future<void> pumpCheckout(
      WidgetTester tester,
      ProviderContainer container,
    ) {
      return tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CheckoutPage()),
        ),
      );
    }

    testWidgets(
      'shows the Store Reward option when the balance is sufficient',
      (tester) async {
        usePhoneViewport(tester);
        final container = await seedCartAndRewards(tester);

        await pumpCheckout(tester, container);
        await tester.pumpAndSettle();

        expect(find.text('Apply ₹10 Store Reward'), findsOneWidget);
        expect(find.text('100 SmartCoins — balance: 129'), findsOneWidget);
        expect(find.text('Grand Total'), findsOneWidget);
        expect(find.text('₹129.00'), findsOneWidget);
      },
    );

    testWidgets(
      'disables the Store Reward option with an insufficient balance',
      (tester) async {
        usePhoneViewport(tester);
        final container = await seedCartAndRewards(tester, seedTotal: 50);

        await pumpCheckout(tester, container);
        await tester.pumpAndSettle();

        expect(find.text('Apply ₹10 Store Reward'), findsOneWidget);
        final switchWidget = tester.widget<Switch>(find.byType(Switch));
        expect(switchWidget.onChanged, isNull);

        await tester.tap(find.byType(Switch));
        await settleAsync(tester);

        expect(find.text('Store Reward Discount'), findsNothing);
        expect(find.text('₹129.00'), findsOneWidget);
      },
    );

    testWidgets('applying the reward adds the discount row and lowers the '
        'Grand Total', (tester) async {
      usePhoneViewport(tester);
      final container = await seedCartAndRewards(tester);

      await pumpCheckout(tester, container);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await settleAsync(tester);

      expect(find.text('Store Reward Discount'), findsOneWidget);
      expect(find.text('−₹10.00'), findsOneWidget);
      expect(find.text('₹119.00'), findsOneWidget);
      expect(find.text('₹129.00'), findsNothing);
      expect(find.text('100 SmartCoins — balance: 29'), findsOneWidget);
    });

    testWidgets('turning the reward off restores the Grand Total', (
      tester,
    ) async {
      usePhoneViewport(tester);
      final container = await seedCartAndRewards(tester);

      await pumpCheckout(tester, container);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await settleAsync(tester);
      await tester.tap(find.byType(Switch));
      await settleAsync(tester);

      expect(find.text('Store Reward Discount'), findsNothing);
      expect(find.text('−₹10.00'), findsNothing);
      expect(find.text('₹119.00'), findsNothing);
      expect(find.text('₹129.00'), findsOneWidget);
      expect(find.text('100 SmartCoins — balance: 129'), findsOneWidget);
    });

    testWidgets('renders the checked-out-as identity and order summary', (
      tester,
    ) async {
      usePhoneViewport(tester);
      final container = await seedCartAndRewards(tester);

      await pumpCheckout(tester, container);
      await tester.pumpAndSettle();

      expect(find.text('Checked out as'), findsOneWidget);
      expect(find.text('+91 9876543210'), findsOneWidget);
      expect(find.text('Order Summary'), findsOneWidget);
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Rice'), findsOneWidget);
      expect(find.text('Products'), findsOneWidget);
      expect(find.text('Items'), findsOneWidget);
    });
  });

  group('Checkout Store Reward flow', () {
    Future<ProviderContainer> pumpAppWithLiveCart(WidgetTester tester) async {
      usePhoneViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              _FakeAuthRepository(_user),
            ),
            cartRepositoryProvider.overrideWithValue(MockCartRepository()),
          ],
          child: const SmartKartApp(),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SmartKartApp)),
      );
      await tester.runAsync(() async {
        final rewards = container.read(rewardsControllerProvider.notifier);
        await rewards.awardCoinsForOrder(_seedOrder());
        final cart = container.read(cartControllerProvider.notifier);
        await cart.linkCart('CART-1');
        await cart.openLiveCart();
        await cart.simulateAdd('milk');
        await cart.simulateAdd('rice');
      });
      return container;
    }

    testWidgets('placing an order with the reward presents a discounted '
        'receipt and returns home', (tester) async {
      final container = await pumpAppWithLiveCart(tester);

      container.read(appRouterProvider).go('/checkout');
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await settleAsync(tester);
      expect(find.text('−₹10.00'), findsOneWidget);

      await payThroughPayment(tester, '119.00');

      expect(find.text('Order placed!'), findsOneWidget);
      expect(find.text('Store Reward Discount'), findsOneWidget);
      expect(find.text('−₹10.00'), findsOneWidget);
      expect(find.text('₹119.00'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await settleAsync(tester);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('SmartKart'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('placing an order without the reward shows a full-price '
        'receipt', (tester) async {
      final container = await pumpAppWithLiveCart(tester);

      container.read(appRouterProvider).go('/checkout');
      await tester.pumpAndSettle();

      await payThroughPayment(tester, '129.00');

      expect(find.text('Order placed!'), findsOneWidget);
      expect(find.text('Store Reward Discount'), findsNothing);
      expect(find.text('−₹10.00'), findsNothing);
      expect(find.text('₹129.00'), findsOneWidget);
    });

    testWidgets(
      'Order Details shows the reward discount for discounted orders',
      (tester) async {
        final container = await pumpAppWithLiveCart(tester);

        container.read(appRouterProvider).go('/checkout');
        await tester.pumpAndSettle();
        await tester.tap(find.byType(Switch));
        await settleAsync(tester);
        await payThroughPayment(tester, '119.00');

        container.read(appRouterProvider).go('/history/SM-0001');
        await tester.pumpAndSettle();

        expect(find.text('Order Details'), findsOneWidget);
        expect(find.text('Store Reward Discount'), findsOneWidget);
        expect(find.text('−₹10.00'), findsOneWidget);
        expect(find.text('₹119.00'), findsOneWidget);
      },
    );

    testWidgets(
      'Order Details hides the reward discount for full-price orders',
      (tester) async {
        final container = await pumpAppWithLiveCart(tester);

        container.read(appRouterProvider).go('/checkout');
        await tester.pumpAndSettle();
        await payThroughPayment(tester, '129.00');

        container.read(appRouterProvider).go('/history/SM-0001');
        await tester.pumpAndSettle();

        expect(find.text('Order Details'), findsOneWidget);
        expect(find.text('Store Reward Discount'), findsNothing);
        expect(find.text('−₹10.00'), findsNothing);
        expect(find.text('₹129.00'), findsOneWidget);
      },
    );

    testWidgets('a pre-redeemed reward applies at checkout without a second '
        'deduction', (tester) async {
      final container = await pumpAppWithLiveCart(tester);
      await tester.runAsync(() async {
        await container
            .read(rewardsControllerProvider.notifier)
            .redeemStoreReward();
      });

      container.read(appRouterProvider).go('/checkout');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await settleAsync(tester);
      await payThroughPayment(tester, '119.00');

      expect(find.text('Order placed!'), findsOneWidget);
      expect(find.text('₹119.00'), findsOneWidget);

      final loaded = container.read(rewardsControllerProvider) as RewardsLoaded;
      expect(loaded.balance, 158);
      expect(loaded.transactions, hasLength(3));
    });

    testWidgets('Purchase History shows the discounted amount for rewarded '
        'orders', (tester) async {
      final container = await pumpAppWithLiveCart(tester);

      container.read(appRouterProvider).go('/checkout');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await settleAsync(tester);
      await payThroughPayment(tester, '119.00');

      container.read(appRouterProvider).go('/history');
      await tester.pumpAndSettle();

      expect(find.textContaining('₹119.00'), findsOneWidget);
      expect(find.textContaining('−₹10.00 reward'), findsOneWidget);
    });

    testWidgets('Profile Total Spent reflects the discounted total', (
      tester,
    ) async {
      final container = await pumpAppWithLiveCart(tester);

      container.read(appRouterProvider).go('/checkout');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await settleAsync(tester);
      await payThroughPayment(tester, '119.00');

      container.read(appRouterProvider).go('/profile');
      await tester.pumpAndSettle();

      expect(find.text('Total Spent'), findsOneWidget);
      expect(find.text('₹119.00'), findsOneWidget);
    });
  });
}
