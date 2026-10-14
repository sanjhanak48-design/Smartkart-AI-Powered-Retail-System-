import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/payment_method.dart';
import '../../domain/models/payment_result.dart';

/// Payment seam. The UI only ever consumes [PaymentResult]s, so a future
/// Razorpay/backend implementation can replace [MockPaymentRepository] without
/// any PaymentPage redesign.
abstract class PaymentRepository {
  Future<PaymentResult> pay({
    required double amount,
    required PaymentMethod method,
  });
}

/// Deterministic simulated payment used by the app. No real transaction ever
/// happens; it only exists to exercise the full checkout-to-receipt journey.
class MockPaymentRepository implements PaymentRepository {
  int _sequence = 0;

  @override
  Future<PaymentResult> pay({
    required double amount,
    required PaymentMethod method,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _sequence += 1;
    return PaymentResult.success(
      referenceId: 'MOCK-PAY-${_sequence.toString().padLeft(4, '0')}',
    );
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => MockPaymentRepository(),
);
