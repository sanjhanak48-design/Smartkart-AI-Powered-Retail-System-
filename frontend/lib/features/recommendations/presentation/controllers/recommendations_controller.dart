import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/domain/models/cart.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../data/repositories/recommendation_repository.dart';
import '../../domain/models/recommended_item.dart';

sealed class RecommendationsState {
  const RecommendationsState();
}

class RecommendationsInitial extends RecommendationsState {
  const RecommendationsInitial();
}

class RecommendationsLoading extends RecommendationsState {
  const RecommendationsLoading();
}

class RecommendationsLoaded extends RecommendationsState {
  const RecommendationsLoaded(this.items);

  final List<RecommendedItem> items;
}

class RecommendationsEmpty extends RecommendationsState {
  const RecommendationsEmpty();
}

class RecommendationsError extends RecommendationsState {
  const RecommendationsError(this.message);

  final String message;
}

class RecommendationsController extends Notifier<RecommendationsState> {
  late final RecommendationRepository _recommendationRepository;

  @override
  RecommendationsState build() {
    _recommendationRepository = ref.watch(recommendationRepositoryProvider);
    return const RecommendationsInitial();
  }

  List<CartItem> _currentCartItems() {
    final cartState = ref.read(cartControllerProvider);
    if (cartState is CartLoaded) {
      return cartState.cart.items;
    }
    return const [];
  }

  Future<void> fetchRecommendations() async {
    state = const RecommendationsLoading();
    try {
      final items = await _recommendationRepository.fetchRecommendations(
        cartItems: _currentCartItems(),
      );
      if (items.isEmpty) {
        state = const RecommendationsEmpty();
      } else {
        state = RecommendationsLoaded(items);
      }
    } catch (_) {
      state = const RecommendationsError(
        'Unable to load recommendations. Please try again.',
      );
    }
  }
}

final recommendationsControllerProvider =
    NotifierProvider<RecommendationsController, RecommendationsState>(
      RecommendationsController.new,
    );
