// Controller tests using deterministic fakes so processing, failure and
// re-entrancy behaviour are verified without touching repository delays.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/features/payment/data/repositories/payment_repository.dart';
import 'package:smartkart/features/payment/domain/models/payment_method.dart';
import 'package:smartkart/features/payment/domain/models/payment_result.dart';
import 'package:smartkart/features/payment/presentation/controllers/payment_controller.dart';

void main() {
  group('PaymentController', () {
    test('starts in the idle state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(paymentControllerProvider), isA<PaymentIdle>());
    });

    test(
      'transitions through processing into success and retains details',
      () async {
        final completer = Completer<PaymentResult>();
        final repository = _DeferredPaymentRepository(completer);
        final container = ProviderContainer(
          overrides: [paymentRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        final controller = container.read(paymentControllerProvider.notifier);
        final payment = controller.pay(amount: 119, method: PaymentMethod.card);

        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(paymentControllerProvider),
          isA<PaymentProcessing>(),
        );

        completer.complete(PaymentResult.success(referenceId: 'MOCK-PAY-0001'));
        expect(await payment, isTrue);

        final success =
            container.read(paymentControllerProvider) as PaymentSuccess;
        expect(success.amount, 119);
        expect(success.method, PaymentMethod.card);
        expect(success.referenceId, 'MOCK-PAY-0001');
      },
    );

    test(
      'converts a repository failure into a friendly PaymentFailure',
      () async {
        final repository = _FakePaymentRepository(shouldFail: true);
        final container = ProviderContainer(
          overrides: [paymentRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        final paid = await container
            .read(paymentControllerProvider.notifier)
            .pay(amount: 100, method: PaymentMethod.upi);

        expect(paid, isFalse);
        final failure =
            container.read(paymentControllerProvider) as PaymentFailure;
        expect(failure.message, contains('could not process'));
        expect(repository.callCount, 1);
      },
    );

    test('ignores duplicate pay calls while a payment is processing', () async {
      final completer = Completer<PaymentResult>();
      final repository = _DeferredPaymentRepository(completer);
      final container = ProviderContainer(
        overrides: [paymentRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final controller = container.read(paymentControllerProvider.notifier);
      final first = controller.pay(amount: 129, method: PaymentMethod.upi);
      final second = controller.pay(amount: 129, method: PaymentMethod.upi);

      expect(repository.callCount, 1);

      completer.complete(PaymentResult.success(referenceId: 'MOCK-PAY-0001'));
      expect(await first, isTrue);
      expect(await second, isFalse);
      expect(repository.callCount, 1);
      expect(container.read(paymentControllerProvider), isA<PaymentSuccess>());
    });

    test('reset returns to the idle state', () async {
      final container = ProviderContainer(
        overrides: [
          paymentRepositoryProvider.overrideWithValue(_FakePaymentRepository()),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(paymentControllerProvider.notifier);
      await controller.pay(amount: 100, method: PaymentMethod.upi);
      controller.reset();

      expect(container.read(paymentControllerProvider), isA<PaymentIdle>());
    });
  });
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

class _DeferredPaymentRepository implements PaymentRepository {
  _DeferredPaymentRepository(this._completer);

  final Completer<PaymentResult> _completer;
  int callCount = 0;

  @override
  Future<PaymentResult> pay({
    required double amount,
    required PaymentMethod method,
  }) {
    callCount += 1;
    return _completer.future;
  }
}
