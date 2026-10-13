// Widget tests for real-time streamed updates rendered on the Live Cart page.
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
import 'package:smartkart/features/cart/presentation/controllers/cart_controller.dart';
import 'package:smartkart/features/cart/presentation/pages/live_cart_page.dart';

void main() {
  const milk = Product(id: 'milk', name: 'Milk', price: 30);
  const rice = Product(id: 'rice', name: 'Rice', price: 99);

  void usePhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
  }

  Future<ProviderContainer> openCartBeforePump(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      final controller = container.read(cartControllerProvider.notifier);
      await controller.linkCart('CART-1');
      await controller.openLiveCart();
    });
    return container;
  }

  MockCartRepository repositoryOf(ProviderContainer container) =>
      container.read(cartRepositoryProvider) as MockCartRepository;

  testWidgets('streamed item addition appears in the Live Cart', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final container = await openCartBeforePump(tester);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LiveCartPage()),
      ),
    );
    await tester.pumpAndSettle();

    repositoryOf(container).emitCartEvent(
      const CartEvent(
        type: CartEventType.itemAdded,
        product: milk,
        quantity: 2,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.text('₹60.00'), findsWidgets);
    expect(find.text('Your cart is empty'), findsNothing);
  });

  testWidgets('streamed removal updates the quantity', (tester) async {
    usePhoneViewport(tester);
    final container = await openCartBeforePump(tester);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LiveCartPage()),
      ),
    );
    await tester.pumpAndSettle();

    final repository = repositoryOf(container);
    repository.emitCartEvent(
      const CartEvent(
        type: CartEventType.itemAdded,
        product: milk,
        quantity: 2,
      ),
    );
    await tester.pumpAndSettle();
    repository.emitCartEvent(
      const CartEvent(type: CartEventType.itemRemoved, product: milk),
    );
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('₹30.00'), findsWidgets);
  });

  testWidgets('streamed clear produces an empty cart state', (tester) async {
    usePhoneViewport(tester);
    final container = await openCartBeforePump(tester);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LiveCartPage()),
      ),
    );
    await tester.pumpAndSettle();

    final repository = repositoryOf(container);
    repository.emitCartEvent(
      const CartEvent(
        type: CartEventType.itemAdded,
        product: milk,
        quantity: 2,
      ),
    );
    await tester.pumpAndSettle();

    repository.emitCartEvent(const CartEvent(type: CartEventType.cartCleared));
    await tester.pumpAndSettle();

    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(find.text('Cart Summary'), findsNothing);
  });

  testWidgets('repeated streamed additions merge into a single row', (
    tester,
  ) async {
    usePhoneViewport(tester);
    final container = await openCartBeforePump(tester);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LiveCartPage()),
      ),
    );
    await tester.pumpAndSettle();

    final repository = repositoryOf(container);
    repository.emitCartEvent(
      const CartEvent(type: CartEventType.itemAdded, product: milk),
    );
    await tester.pumpAndSettle();
    repository.emitCartEvent(
      const CartEvent(type: CartEventType.itemAdded, product: milk),
    );
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.text('₹60.00'), findsWidgets);
  });

  testWidgets('total updates after streamed changes', (tester) async {
    usePhoneViewport(tester);
    final container = await openCartBeforePump(tester);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LiveCartPage()),
      ),
    );
    await tester.pumpAndSettle();

    final repository = repositoryOf(container);
    repository.emitCartEvent(
      const CartEvent(
        type: CartEventType.itemAdded,
        product: milk,
        quantity: 2,
      ),
    );
    repository.emitCartEvent(
      const CartEvent(type: CartEventType.itemAdded, product: rice),
    );
    await tester.pumpAndSettle();

    expect(find.text('₹159.00'), findsWidgets);
    expect(find.text('2'), findsWidgets);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets(
    'manual add and Checkout lead to the Checkout page with the stream',
    (tester) async {
      usePhoneViewport(tester);
      final repository = MockCartRepository();
      const user = AuthUser(
        uid: 'uid-123',
        phone: '+91 9876543210',
        displayName: 'Asha',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository(user)),
            cartRepositoryProvider.overrideWithValue(repository),
          ],
          child: const SmartKartApp(),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SmartKartApp)),
      );
      await tester.runAsync(() async {
        final controller = container.read(cartControllerProvider.notifier);
        await controller.linkCart('CART-1');
        await controller.openLiveCart();
      });

      final router = container.read(appRouterProvider);
      router.go('/live-cart');
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ Add Milk'));
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('₹30.00'), findsWidgets);

      await tester.tap(find.text('Checkout'));
      await tester.pumpAndSettle();

      expect(find.text('Order Summary'), findsOneWidget);
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Pay ₹30.00'), findsOneWidget);

      // Let CheckoutPage's rewards preload finish so no repository timers are
      // left pending at the end of the test.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
    },
  );
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._user);

  final AuthUser? _user;

  @override
  String? get verificationId => null;

  @override
  Stream<AuthUser?> authStateChanges() => const Stream<AuthUser?>.empty();

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
