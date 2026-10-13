enum PaymentMethod { upi, card }

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.upi => 'UPI',
    PaymentMethod.card => 'Card',
  };
}
