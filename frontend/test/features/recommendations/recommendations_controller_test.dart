// Focused unit tests for the RecommendationsController.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/features/cart/domain/models/cart.dart';
import 'package:smartkart/features/cart/presentation/controllers/cart_controller.dart';
import 'package:smartkart/features/recommendations/data/repositories/recommendation_repository.dart';
import 'package:smartkart/features/recommendations/domain/models/recommended_item.dart';
import 'package:smartkart/features/recommendations/presentation/controllers/recommendations_controller.dart';

class _EmptyRecommendationRepository implements RecommendationRepository {
  @override
  Future<List<RecommendedItem>> fetchRecommendations({
    required List<CartItem> cartItems,
  }) async {
    return const [];
  }
}

class _ThrowingRecommendationRepository implements RecommendationRepository {
  @override
  Future<List<RecommendedItem>> fetchRecommendations({
    required List<CartItem> cartItems,
  }) async {
    throw StateError('recommendations unavailable');
  }
}

void main() {
  test(
    'seeded history returns RecommendationsLoaded with expected ranking',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repo = container.read(cartRepositoryProvider);
      await repo.addItem('cart-1', 'milk');
      await repo.addItem('cart-1', 'milk');
      await repo.addItem('cart-1', 'milk');
      final items = await repo.addItem('cart-1', 'bread');
      await repo.placeOrder('cart-1', items);

      final controller = container.read(
        recommendationsControllerProvider.notifier,
      );
      await controller.fetchRecommendations();

      final state = container.read(recommendationsControllerProvider);
      expect(state, isA<RecommendationsLoaded>());
      final loaded = state as RecommendationsLoaded;
      expect(loaded.items.first.product.id, 'milk');
      expect(loaded.items[1].product.id, 'eggs');
      expect(loaded.items[2].product.id, 'cheese');
      expect(loaded.items[3].product.id, 'bread');
    },
  );

  test('after linking cart and adding milk, fetch excludes milk', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final cartController = container.read(cartControllerProvider.notifier);
    await cartController.linkCart('CART-1');
    await cartController.openLiveCart();
    await cartController.simulateAdd('milk');

    final controller = container.read(
      recommendationsControllerProvider.notifier,
    );
    await controller.fetchRecommendations();

    final state = container.read(recommendationsControllerProvider);
    expect(state, isA<RecommendationsLoaded>());
    final loaded = state as RecommendationsLoaded;
    expect(
      loaded.items.map((item) => item.product.id),
      isNot(contains('milk')),
    );
  });

  test(
    'fake repository returning no candidates gives RecommendationsEmpty',
    () async {
      final container = ProviderContainer(
        overrides: [
          recommendationRepositoryProvider.overrideWithValue(
            _EmptyRecommendationRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        recommendationsControllerProvider.notifier,
      );
      await controller.fetchRecommendations();

      expect(
        container.read(recommendationsControllerProvider),
        isA<RecommendationsEmpty>(),
      );
    },
  );

  test('fake repository throwing gives RecommendationsError', () async {
    final container = ProviderContainer(
      overrides: [
        recommendationRepositoryProvider.overrideWithValue(
          _ThrowingRecommendationRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(
      recommendationsControllerProvider.notifier,
    );
    await controller.fetchRecommendations();

    final state = container.read(recommendationsControllerProvider);
    expect(state, isA<RecommendationsError>());
    expect(
      (state as RecommendationsError).message,
      'Unable to load recommendations. Please try again.',
    );
  });
}
