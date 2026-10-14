import '../../../cart/domain/models/cart.dart';

enum RecommendationSource {
  purchaseHistory,
  cartAffinity,
  coPurchase,
  fallback,
}

class RecommendedItem {
  const RecommendedItem({
    required this.product,
    required this.reason,
    required this.score,
    this.source = RecommendationSource.fallback,
  });

  final Product product;
  final String reason;
  final double score;
  final RecommendationSource source;
}
