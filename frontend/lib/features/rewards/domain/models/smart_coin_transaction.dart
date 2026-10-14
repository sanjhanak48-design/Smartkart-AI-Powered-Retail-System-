enum SmartCoinTransactionType { earned, redeemed }

class SmartCoinTransaction {
  const SmartCoinTransaction({
    required this.id,
    required this.type,
    required this.coins,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final SmartCoinTransactionType type;
  final int coins;
  final String description;
  final DateTime createdAt;
}
