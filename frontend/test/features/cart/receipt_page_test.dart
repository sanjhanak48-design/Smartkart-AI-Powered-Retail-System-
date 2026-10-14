// Focused widget tests for the ReceiptPage, covering the success payment
// card, the non-success fallback banner, and the empty state.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/features/cart/presentation/controllers/cart_controller.dart';
import 'package:smartkart/features/cart/presentation/pages/receipt_page.dart';
import 'package:smartkart/features/payment/data/repositories/payment_repository.dart';
import 'package:smartkart/features/payment/domain/models/payment_method.dart';
import 'package:smartkart/features/payment/domain/models/payment_result.dart';
import 'package:smartkart/features/payment/presentation/controllers/payment_controller.dart';

class _SucceedingPaymentRepository implements PaymentRepository {
  @override
  Future<PaymentResult> pay({
    required double amount,
    required PaymentMethod method,
  }) async {
    return PaymentResult.success(referenceId: 'MOCK-PAY-0001');
  }
}

/// Seeds a linked, loaded cart with Milk (30) + Rice (99) = ₹129, without
/// placing an order. Optionally places the order and/or records a payment.
Future<ProviderContainer> _buildContainer(
  WidgetTester tester, {
  bool checkout = false,
  bool pay = false,
}) async {
  final container = ProviderContainer(
    overrides: [
      paymentRepositoryProvider.overrideWithValue(
        _SucceedingPaymentRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.runAsync(() async {
    final cart = container.read(cartControllerProvider.notifier);
    await cart.linkCart('CART-1');
    await cart.openLiveCart();
    await cart.simulateAdd('milk');
    await cart.simulateAdd('rice');
    if (checkout) {
      await cart.checkout();
    }
    if (pay) {
      await container
          .read(paymentControllerProvider.notifier)
          .pay(amount: 129, method: PaymentMethod.upi);
    }
  });
  return container;
}

Future<void> _pumpReceipt(WidgetTester tester, ProviderContainer container) {
  return tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ReceiptPage()),
    ),
  );
}

void main() {
  testWidgets('receipt shows order details and the success payment card', (
    tester,
  ) async {
    final container = await _buildContainer(tester, checkout: true, pay: true);
    await _pumpReceipt(tester, container);
    await tester.pumpAndSettle();

    expect(find.text('Order placed!'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Payment Status: Paid (Mock)'), findsOneWidget);
    expect(find.text('Method: UPI'), findsOneWidget);
    expect(find.text('Amount Paid: ₹129.00'), findsOneWidget);
    expect(find.text('Reference: MOCK-PAY-0001'), findsOneWidget);
    expect(
      find.text('Mock payment — no real charge was made.'),
      findsOneWidget,
    );
  });

  testWidgets('receipt shows a fallback note when payment info is missing', (
    tester,
  ) async {
    final container = await _buildContainer(tester, checkout: true, pay: false);
    await _pumpReceipt(tester, container);
    await tester.pumpAndSettle();

    expect(find.text('Order placed!'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
    expect(
      find.text('Payment details are not available for this receipt.'),
      findsOneWidget,
    );
    expect(find.text('Payment Status: Paid (Mock)'), findsNothing);
  });

  testWidgets('receipt shows an empty state when no order was placed', (
    tester,
  ) async {
    final container = await _buildContainer(tester);
    await _pumpReceipt(tester, container);
    await tester.pumpAndSettle();

    expect(find.text('No receipt available'), findsOneWidget);
    expect(find.text('Place an order to generate a receipt.'), findsOneWidget);
  });
}
