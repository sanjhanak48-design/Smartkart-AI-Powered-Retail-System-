import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/data/repositories/cart_repository.dart';
import '../../../cart/domain/models/cart.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../domain/models/recommended_item.dart';
import '../../domain/recommendation_engine.dart';

abstract class RecommendationRepository {
  Future<List<RecommendedItem>> fetchRecommendations({
    required List<CartItem> cartItems,
  });
}

class MockRecommendationRepository implements RecommendationRepository {
  MockRecommendationRepository({required this._cartRepository});

  final CartRepository _cartRepository;
  final RecommendationEngine _engine = RecommendationEngine();

  @override
  Future<List<RecommendedItem>> fetchRecommendations({
    required List<CartItem> cartItems,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final catalog = await _cartRepository.getCatalog();
    final history = await _cartRepository.getOrders();
    return _engine.recommend(
      catalog: catalog,
      history: history,
      cartItems: cartItems,
    );
  }
}

final recommendationRepositoryProvider = Provider<RecommendationRepository>(
  (ref) => MockRecommendationRepository(
    cartRepository: ref.watch(cartRepositoryProvider),
  ),
);
