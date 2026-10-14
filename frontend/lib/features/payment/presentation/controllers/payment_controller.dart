import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/payment_repository.dart';
import '../../domain/models/payment_method.dart';

sealed class PaymentState {
  const PaymentState();
}

class PaymentIdle extends PaymentState {
  const PaymentIdle();
}

class PaymentProcessing extends PaymentState {
  const PaymentProcessing();
}

class PaymentSuccess extends PaymentState {
  const PaymentSuccess({
    required this.amount,
    required this.method,
    required this.referenceId,
  });

  final double amount;
  final PaymentMethod method;
  final String referenceId;
}

class PaymentFailure extends PaymentState {
  const PaymentFailure(this.message);

  final String message;
}

class PaymentController extends Notifier<PaymentState> {
  late final PaymentRepository _repository;
  bool _busy = false;

  @override
  PaymentState build() {
    _repository = ref.watch(paymentRepositoryProvider);
    return const PaymentIdle();
  }

  /// Attempts a payment. Re-entrant calls while a payment is already in
  /// progress are ignored so no duplicate payment is ever issued.
  /// Returns true only when the repository reports success.
  Future<bool> pay({
    required double amount,
    required PaymentMethod method,
  }) async {
    if (_busy) {
      return false;
    }
    _busy = true;
    state = const PaymentProcessing();
    try {
      final result = await _repository.pay(amount: amount, method: method);
      if (result.succeeded) {
        state = PaymentSuccess(
          amount: amount,
          method: method,
          referenceId: result.referenceId ?? 'MOCK-PAY-0000',
        );
        return true;
      }
      state = PaymentFailure(
        result.message ?? 'Payment failed. Please try again.',
      );
      return false;
    } catch (_) {
      state = const PaymentFailure(
        'We could not process the payment. Please try again.',
      );
      return false;
    } finally {
      _busy = false;
    }
  }

  /// Returns the controller to the idle state, for example when the Payment
  /// page is revisited after a failure or cancellation.
  void reset() {
    if (_busy) {
      return;
    }
    state = const PaymentIdle();
  }
}

final paymentControllerProvider =
    NotifierProvider<PaymentController, PaymentState>(PaymentController.new);
