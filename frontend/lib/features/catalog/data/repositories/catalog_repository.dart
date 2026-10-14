import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/data/repositories/cart_repository.dart';
import '../../../cart/domain/models/cart.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';

abstract class CatalogRepository {
  Future<List<Product>> fetchCatalog();

  Future<List<String>> fetchCategories();
}

/// Mock catalog backed by the single canonical mock cart catalog so product
/// ids stay consistent with the cart's add/remove lookup.
class MockCatalogRepository implements CatalogRepository {
  MockCatalogRepository({required this._cartRepository});

  final CartRepository _cartRepository;

  @override
  Future<List<Product>> fetchCatalog() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _cartRepository.getCatalog();
  }

  @override
  Future<List<String>> fetchCategories() async {
    final catalog = await fetchCatalog();
    final categories =
        catalog
            .map((product) => product.category)
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return List.unmodifiable(categories);
  }
}

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) =>
      MockCatalogRepository(cartRepository: ref.watch(cartRepositoryProvider)),
);
