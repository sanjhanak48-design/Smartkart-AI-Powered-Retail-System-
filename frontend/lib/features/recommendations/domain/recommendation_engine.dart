import '../../cart/domain/models/cart.dart';
import '../../cart/domain/models/order.dart';
import 'models/recommended_item.dart';

class RecommendationEngine {
  const RecommendationEngine();

  static const int defaultTopN = 5;

  static const int _historyWeight = 2;
  static const int _cartWeight = 3;
  static const int _coPurchaseWeight = 1;

  List<RecommendedItem> recommend({
    required List<Product> catalog,
    required List<Order> history,
    required List<CartItem> cartItems,
    int topN = defaultTopN,
  }) {
    if (history.isEmpty && cartItems.isEmpty) {
      return _coldStart(catalog, topN);
    }

    final inCartIds = cartItems.map((item) => item.product.id).toSet();
    final candidates = catalog
        .where((product) => !inCartIds.contains(product.id))
        .toList();

    final historyByCategory = <String, int>{};
    for (final order in history) {
      for (final item in order.items) {
        final seed = historyByCategory[item.product.category] ?? 0;
        historyByCategory[item.product.category] = seed + item.quantity;
      }
    }

    final cartByCategory = <String, int>{};
    for (final item in cartItems) {
      final seed = cartByCategory[item.product.category] ?? 0;
      cartByCategory[item.product.category] = seed + item.quantity;
    }

    final cartProductIds = cartItems.map((item) => item.product.id).toSet();

    final items = <RecommendedItem>[];
    for (final candidate in candidates) {
      final h = historyByCategory[candidate.category] ?? 0;
      final c = cartByCategory[candidate.category] ?? 0;
      final coPurchases = _coPurchasesWithCart(
        orderHistory: history,
        candidate: candidate,
        cartProductIds: cartProductIds,
      );
      final t = coPurchases.orders;

      final source = dominantSource(h: h, c: c, t: t);
      final reason = reasonFor(
        source,
        category: candidate.category,
        companionName: coPurchases.companionName,
      );

      final score =
          (h * _historyWeight) + (c * _cartWeight) + (t * _coPurchaseWeight);

      items.add(
        RecommendedItem(
          product: candidate,
          reason: reason,
          score: score.toDouble(),
          source: source,
        ),
      );
    }

    final catalogPositions = <String, int>{
      for (var i = 0; i < catalog.length; i++) catalog[i].id: i,
    };

    items.sort((a, b) {
      final scoreComparison = b.score.compareTo(a.score);
      if (scoreComparison != 0) {
        return scoreComparison;
      }
      final positionComparison =
          (catalogPositions[a.product.id] ?? catalog.length).compareTo(
            catalogPositions[b.product.id] ?? catalog.length,
          );
      if (positionComparison != 0) {
        return positionComparison;
      }
      return a.product.name.compareTo(b.product.name);
    });

    return items.take(topN).toList();
  }

  RecommendationSource dominantSource({
    required int h,
    required int c,
    required int t,
  }) {
    final historyScore = h * _historyWeight;
    final cartScore = c * _cartWeight;
    final coScore = t * _coPurchaseWeight;

    if (cartScore > 0 && cartScore >= coScore && cartScore >= historyScore) {
      return RecommendationSource.cartAffinity;
    }
    if (coScore > 0 && coScore >= historyScore) {
      return RecommendationSource.coPurchase;
    }
    if (historyScore > 0) {
      return RecommendationSource.purchaseHistory;
    }
    return RecommendationSource.fallback;
  }

  String reasonFor(
    RecommendationSource source, {
    required String category,
    String? companionName,
  }) {
    switch (source) {
      case RecommendationSource.cartAffinity:
        return 'Pairs well with items in your cart';
      case RecommendationSource.coPurchase:
        return 'Often bought with $companionName';
      case RecommendationSource.purchaseHistory:
        return category.isEmpty
            ? 'Because you often buy similar products'
            : 'Because you often buy $category products';
      case RecommendationSource.fallback:
        return 'Recommended for you';
    }
  }

  List<RecommendedItem> _coldStart(List<Product> catalog, int topN) {
    final categories = <String>[];
    for (final product in catalog) {
      if (!categories.contains(product.category)) {
        categories.add(product.category);
      }
    }

    final items = <RecommendedItem>[];
    final pickedIds = <String>{};
    while (items.length < topN) {
      var addedThisPass = false;
      for (final category in categories) {
        if (items.length >= topN) {
          break;
        }
        for (final product in catalog) {
          if (product.category != category || pickedIds.contains(product.id)) {
            continue;
          }
          items.add(
            RecommendedItem(
              product: product,
              reason: reasonFor(
                RecommendationSource.fallback,
                category: category,
              ),
              score: 0,
              source: RecommendationSource.fallback,
            ),
          );
          pickedIds.add(product.id);
          addedThisPass = true;
          break;
        }
      }
      if (!addedThisPass) {
        break;
      }
    }

    return items;
  }

  _CoPurchases _coPurchasesWithCart({
    required List<Order> orderHistory,
    required Product candidate,
    required Set<String> cartProductIds,
  }) {
    var orders = 0;
    String? companionName;
    for (final order in orderHistory) {
      final orderProductIds = order.items.map((item) => item.product.id);
      if (!orderProductIds.contains(candidate.id)) {
        continue;
      }
      if (!orderProductIds.any(cartProductIds.contains)) {
        continue;
      }
      orders += 1;
      companionName ??= order.items
          .firstWhere(
            (item) => cartProductIds.contains(item.product.id),
            orElse: () => order.items.first,
          )
          .product
          .name;
    }
    return _CoPurchases(orders: orders, companionName: companionName);
  }
}

class _CoPurchases {
  const _CoPurchases({required this.orders, required this.companionName});

  final int orders;
  final String? companionName;
}
