// Widget tests for the payment page and the full checkout -> payment ->
// receipt journey with the mock payment repository.
import 'dart:async';

import 'dart:ui' as ui;

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
import 'package:smartkart/features/cart/domain/models/order.dart';
import 'package:smartkart/features/cart/presentation/controllers/cart_controller.dart';
import 'package:smartkart/features/payment/data/repositories/payment_repository.dart';
import 'package:smartkart/features/payment/domain/models/payment_method.dart';
import 'package:smartkart/features/payment/domain/models/payment_result.dart';
import 'package:smartkart/features/payment/presentation/pages/payment_page.dart';
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

class _FakePaymentRepository implements PaymentRepository {
  _FakePaymentRepository({this.shouldFail = false});

  final bool shouldFail;
  int callCount = 0;

  @override
  Future<PaymentResult> pay({
    required double amount,
    required PaymentMethod method,
  }) async {
    callCount += 1;
    if (shouldFail) {
      throw StateError('payment declined');
    }
    return PaymentResult.success(referenceId: 'MOCK-PAY-$callCount');
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

/// Advances the fake clock past the mock payment (400ms) plus the checkout
/// order placement and reward reload chain (~700ms).
Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 1200));
  await tester.pumpAndSettle();
}

Future<ProviderContainer> seedCartAndRewards(
  WidgetTester tester, {
  double seedTotal = 129,
  bool applyReward = false,
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
    final cart = container.read(cartControllerProvider.notifier);
    await cart.linkCart('CART-1');
    await cart.openLiveCart();
    await cart.simulateAdd('milk');
    await cart.simulateAdd('rice');
    if (applyReward) {
      await cart.applyStoreReward();
    }
  });
  return container;
}

Future<void> pumpPaymentPage(WidgetTester tester, ProviderContainer container) {
  return tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: PaymentPage()),
    ),
  );
}

void _expectSelectedTile(WidgetTester tester, String label, bool selected) {
  final tile = find
      .ancestor(of: find.text(label), matching: find.byType(InkWell))
      .first;
  expect(
    find.descendant(
      of: tile,
      matching: find.byIcon(
        selected ? Icons.check_circle : Icons.radio_button_unchecked,
      ),
    ),
    findsOneWidget,
    reason: '$label tile should be ${selected ? 'selected' : 'unselected'}',
  );
}

Future<(ProviderContainer, MockCartRepository)> pumpApp(
  WidgetTester tester, {
  PaymentRepository? paymentRepository,
}) async {
  usePhoneViewport(tester);
  final cartRepository = MockCartRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository(_user)),
        cartRepositoryProvider.overrideWithValue(cartRepository),
        if (paymentRepository != null)
          paymentRepositoryProvider.overrideWithValue(paymentRepository),
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
  return (container, cartRepository);
}

Future<void> openPayment(
  WidgetTester tester,
  ProviderContainer container,
  String amount,
) async {
  container.read(appRouterProvider).go('/checkout');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Pay ₹$amount'));
  await tester.pumpAndSettle();
}

Future<void> applyRewardAtCheckout(WidgetTester tester) async {
  await tester.tap(find.byType(Switch));
  await settle(tester);
}

void main() {
  group('Payment Page', () {
    testWidgets('shows the payable amount for a seeded ₹129 cart', (
      tester,
    ) async {
      final container = await seedCartAndRewards(tester);

      await pumpPaymentPage(tester, container);
      await tester.pumpAndSettle();

      expect(find.text('Amount Payable'), findsOneWidget);
      expect(find.text('₹129.00'), findsOneWidget);
      expect(find.text('Pay ₹129.00'), findsOneWidget);
      expect(find.text('Cancel Payment'), findsOneWidget);
      expect(
        find.text('Simulated payment — no real money will be charged.'),
        findsOneWidget,
      );
    });

    testWidgets('applying a Store Reward shows a payable of ₹119', (
      tester,
    ) async {
      final container = await seedCartAndRewards(tester, applyReward: true);

      await pumpPaymentPage(tester, container);
      await tester.pumpAndSettle();

      expect(find.text('Amount Payable'), findsOneWidget);
      expect(find.text('₹119.00'), findsOneWidget);
      expect(find.text('Pay ₹119.00'), findsOneWidget);
      expect(find.text('₹129.00'), findsNothing);
    });

    testWidgets('UPI is selected by default', (tester) async {
      final container = await seedCartAndRewards(tester);

      await pumpPaymentPage(tester, container);
      await tester.pumpAndSettle();

      _expectSelectedTile(tester, 'UPI', true);
      _expectSelectedTile(tester, 'Card', false);
    });

    testWidgets('Card can be selected', (tester) async {
      final container = await seedCartAndRewards(tester);

      await pumpPaymentPage(tester, container);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Card'));
      await tester.pumpAndSettle();

      _expectSelectedTile(tester, 'Card', true);
      _expectSelectedTile(tester, 'UPI', false);
    });

    testWidgets('payment method tiles expose button + selected semantics', (
      tester,
    ) async {
      final semanticsHandle = tester.ensureSemantics();

      final container = await seedCartAndRewards(tester);

      await pumpPaymentPage(tester, container);
      await tester.pumpAndSettle();

      final upiData = tester
          .getSemantics(
            find.byWidgetPredicate(
              (w) => w is Semantics && w.properties.label == 'UPI',
            ),
          )
          .getSemanticsData();
      expect(upiData.flagsCollection.isButton, isTrue);
      expect(upiData.flagsCollection.isSelected, ui.Tristate.isTrue);

      final cardData = tester
          .getSemantics(
            find.byWidgetPredicate(
              (w) => w is Semantics && w.properties.label == 'Card',
            ),
          )
          .getSemanticsData();
      expect(cardData.flagsCollection.isButton, isTrue);
      expect(cardData.flagsCollection.isSelected, ui.Tristate.isFalse);

      semanticsHandle.dispose();
    });

    testWidgets('payment error box is styled with the error token', (
      tester,
    ) async {
      final (container, _) = await pumpApp(
        tester,
        paymentRepository: _FakePaymentRepository(shouldFail: true),
      );
      await openPayment(tester, container, '129.00');

      await tester.tap(find.text('Pay ₹129.00'));
      await settle(tester);

      final errorText = tester.widget<Text>(
        find.text('We could not process the payment. Please try again.'),
      );
      expect(errorText.style?.color, AppColors.error);
    });
  });

  group('Payment flow', () {
    testWidgets('processing disables duplicate submission and creates ONE '
        'order', (tester) async {
      final (container, cartRepository) = await pumpApp(tester);
      await openPayment(tester, container, '129.00');

      await tester.tap(find.text('Pay ₹129.00'));
      await tester.pump();

      final payButton = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(payButton.onPressed, isNull);
      expect(find.text('Processing payment...'), findsOneWidget);

      // A duplicate attempt while processing must be ignored.
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();

      await settle(tester);

      expect(find.text('Order placed!'), findsOneWidget);
      final orders = (await tester.runAsync(() => cartRepository.getOrders()))!;
      expect(orders, hasLength(1));
    });

    testWidgets('a successful payment reaches the receipt and creates exactly '
        'one order', (tester) async {
      final (container, cartRepository) = await pumpApp(tester);
      await openPayment(tester, container, '129.00');

      await tester.tap(find.text('Pay ₹129.00'));
      await settle(tester);

      expect(find.text('Order placed!'), findsOneWidget);
      final orders = (await tester.runAsync(() => cartRepository.getOrders()))!;
      expect(orders, hasLength(1));
      expect(orders.first.totalAfterDiscount, 129);
    });

    testWidgets('receipt shows the discounted amount, chosen method and mock '
        'payment details', (tester) async {
      final (container, cartRepository) = await pumpApp(tester);

      container.read(appRouterProvider).go('/checkout');
      await tester.pumpAndSettle();
      await applyRewardAtCheckout(tester);
      expect(find.text('−₹10.00'), findsOneWidget);

      await tester.tap(find.text('Pay ₹119.00'));
      await tester.pumpAndSettle();

      expect(find.text('Amount Payable'), findsOneWidget);
      expect(find.text('₹119.00'), findsOneWidget);

      await tester.tap(find.text('Card'));
      await tester.pump();
      await tester.tap(find.text('Pay ₹119.00'));
      await settle(tester);

      expect(find.text('Order placed!'), findsOneWidget);
      expect(find.text('Store Reward Discount'), findsOneWidget);
      expect(find.text('−₹10.00'), findsOneWidget);
      expect(find.text('₹119.00'), findsOneWidget);
      expect(find.text('Payment Status: Paid (Mock)'), findsOneWidget);
      expect(find.text('Method: Card'), findsOneWidget);
      expect(find.text('Amount Paid: ₹119.00'), findsOneWidget);
      expect(find.text('Reference: MOCK-PAY-0001'), findsOneWidget);
      expect(
        find.text('Mock payment — no real charge was made.'),
        findsOneWidget,
      );

      final orders = (await tester.runAsync(() => cartRepository.getOrders()))!;
      expect(orders, hasLength(1));
      expect(orders.first.discount, 10);
      expect(orders.first.totalAfterDiscount, 119);
    });

    testWidgets('a failed payment stays on the Payment page and creates NO '
        'order', (tester) async {
      final (container, cartRepository) = await pumpApp(
        tester,
        paymentRepository: _FakePaymentRepository(shouldFail: true),
      );
      await openPayment(tester, container, '129.00');

      await tester.tap(find.text('Pay ₹129.00'));
      await settle(tester);

      expect(find.text('Amount Payable'), findsOneWidget);
      expect(
        find.text('We could not process the payment. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Order placed!'), findsNothing);

      final orders = (await tester.runAsync(() => cartRepository.getOrders()))!;
      expect(orders, isEmpty);
      expect(container.read(cartControllerProvider), isA<CartLoaded>());
    });

    testWidgets('cancellation returns to Checkout, preserves the cart and '
        'creates NO order', (tester) async {
      final (container, cartRepository) = await pumpApp(tester);
      await openPayment(tester, container, '129.00');

      await tester.tap(find.text('Cancel Payment'));
      await tester.pumpAndSettle();

      expect(find.text('Order Summary'), findsOneWidget);
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('₹129.00'), findsOneWidget);
      expect(find.text('Order placed!'), findsNothing);

      final orders = (await tester.runAsync(() => cartRepository.getOrders()))!;
      expect(orders, isEmpty);
      expect(container.read(cartControllerProvider), isA<CartLoaded>());
    });

    testWidgets(
      'cancellation preserves an applied Store Reward with no order',
      (tester) async {
        final (container, cartRepository) = await pumpApp(tester);

        container.read(appRouterProvider).go('/checkout');
        await tester.pumpAndSettle();
        await applyRewardAtCheckout(tester);
        expect(find.text('−₹10.00'), findsOneWidget);

        await tester.tap(find.text('Pay ₹119.00'));
        await tester.pumpAndSettle();
        expect(find.text('Amount Payable'), findsOneWidget);
        expect(find.text('₹119.00'), findsOneWidget);
        expect(find.text('₹129.00'), findsNothing);

        await tester.tap(find.text('Cancel Payment'));
        await tester.pumpAndSettle();

        expect(find.text('Order Summary'), findsOneWidget);
        expect(find.text('−₹10.00'), findsOneWidget);
        expect(find.text('₹119.00'), findsOneWidget);

        final orders = (await tester.runAsync(
          () => cartRepository.getOrders(),
        ))!;
        expect(orders, isEmpty);
        expect(container.read(cartControllerProvider), isA<CartLoaded>());
        final rewards =
            container.read(rewardsControllerProvider) as RewardsLoaded;
        expect(rewards.balance, 29);
        expect(
          container
              .read(rewardsControllerProvider.notifier)
              .pendingStoreRewards,
          1,
        );
      },
    );

    testWidgets('a failed payment keeps the applied Store Reward consistent '
        'and creates NO order', (tester) async {
      final (container, cartRepository) = await pumpApp(
        tester,
        paymentRepository: _FakePaymentRepository(shouldFail: true),
      );

      container.read(appRouterProvider).go('/checkout');
      await tester.pumpAndSettle();
      await applyRewardAtCheckout(tester);
      expect(find.text('−₹10.00'), findsOneWidget);

      await tester.tap(find.text('Pay ₹119.00'));
      await tester.pumpAndSettle();
      expect(find.text('Amount Payable'), findsOneWidget);

      await tester.tap(find.text('Pay ₹119.00'));
      await settle(tester);

      expect(
        find.text('We could not process the payment. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Order placed!'), findsNothing);

      await tester.tap(find.text('Cancel Payment'));
      await tester.pumpAndSettle();

      expect(find.text('Order Summary'), findsOneWidget);
      expect(find.text('−₹10.00'), findsOneWidget);
      expect(find.text('₹119.00'), findsOneWidget);

      final orders = (await tester.runAsync(() => cartRepository.getOrders()))!;
      expect(orders, isEmpty);
      expect(container.read(cartControllerProvider), isA<CartLoaded>());
      final rewards =
          container.read(rewardsControllerProvider) as RewardsLoaded;
      expect(rewards.balance, 29);
      expect(
        container.read(rewardsControllerProvider.notifier).pendingStoreRewards,
        1,
      );
    });
  });
}
