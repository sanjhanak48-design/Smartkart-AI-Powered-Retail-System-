/// Outcome of a payment attempt returned by a [PaymentRepository].
class PaymentResult {
  const PaymentResult.success({required this.referenceId})
    : succeeded = true,
      message = null;

  const PaymentResult.failure({required this.message})
    : succeeded = false,
      referenceId = null;

  final bool succeeded;
  final String? referenceId;
  final String? message;
}
