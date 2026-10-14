// Tests for the mock payment repository and the repository contract.
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/features/payment/data/repositories/payment_repository.dart';
import 'package:smartkart/features/payment/domain/models/payment_method.dart';
import 'package:smartkart/features/payment/domain/models/payment_result.dart';

void main() {
  group('MockPaymentRepository', () {
    test(
      'returns a successful mock payment with a MOCK-PAY reference',
      () async {
        final repository = MockPaymentRepository();

        final result = await repository.pay(
          amount: 129,
          method: PaymentMethod.upi,
        );

        expect(result.succeeded, isTrue);
        expect(result.referenceId, startsWith('MOCK-PAY-'));
        expect(result.referenceId, isNotEmpty);
        expect(result.message, isNull);
      },
    );

    test('issues a unique reference for every payment', () async {
      final repository = MockPaymentRepository();

      final first = await repository.pay(
        amount: 129,
        method: PaymentMethod.upi,
      );
      final second = await repository.pay(
        amount: 119,
        method: PaymentMethod.card,
      );

      expect(first.referenceId, isNot(second.referenceId));
      expect(first.referenceId, 'MOCK-PAY-0001');
      expect(second.referenceId, 'MOCK-PAY-0002');
    });
  });

  group('PaymentRepository contract', () {
    test('forwards the amount and method to the repository', () async {
      final delegate = MockPaymentRepository();
      final recording = _RecordingRepository(delegate);

      final result = await recording.pay(
        amount: 119,
        method: PaymentMethod.card,
      );

      expect(result.succeeded, isTrue);
      expect(recording.amount, 119);
      expect(recording.method, PaymentMethod.card);
    });
  });
}

class _RecordingRepository implements PaymentRepository {
  _RecordingRepository(this.delegate);

  final PaymentRepository delegate;
  double? amount;
  PaymentMethod? method;

  @override
  Future<PaymentResult> pay({
    required double amount,
    required PaymentMethod method,
  }) async {
    this.amount = amount;
    this.method = method;
    return delegate.pay(amount: amount, method: method);
  }
}
