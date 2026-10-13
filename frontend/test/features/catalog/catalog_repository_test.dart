// Focused unit tests for MockCatalogRepository.
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/features/cart/data/repositories/cart_repository.dart';
import 'package:smartkart/features/cart/domain/models/cart.dart';
import 'package:smartkart/features/catalog/data/repositories/catalog_repository.dart';

class _FailingCartRepository extends MockCartRepository {
  @override
  Future<List<Product>> getCatalog() async {
    throw StateError('unavailable');
  }
}

void main() {
  final repo = MockCatalogRepository(cartRepository: MockCartRepository());

  group('MockCatalogRepository', () {
    test(
      'fetchCatalog returns the expanded catalog with the original ids',
      () async {
        final catalog = await repo.fetchCatalog();

        expect(catalog, hasLength(14));
        expect(catalog.length, greaterThanOrEqualTo(12));

        final ids = catalog.map((product) => product.id).toSet();
        expect(
          {'milk', 'bread', 'rice', 'biscuits'}.difference(ids),
          isEmpty,
          reason: 'original four catalog ids must remain present',
        );

        for (final product in catalog) {
          expect(product.name, isNotEmpty);
          expect(product.price, greaterThan(0));
          expect(product.category, isNotEmpty);
          expect(product.emojiIcon, isNotNull);
        }
      },
    );

    test('fetchCatalog returns an unmodifiable list', () async {
      final catalog = await repo.fetchCatalog();

      expect(
        () => catalog.add(const Product(id: 'x', name: 'X', price: 1)),
        throwsUnsupportedError,
      );
    });

    test(
      'fetchCategories derives, deduplicates and sorts categories',
      () async {
        final categories = await repo.fetchCategories();

        expect(
          categories,
          containsAll([
            'Bakery',
            'Beverages',
            'Dairy',
            'Personal Care',
            'Snacks',
            'Staples',
          ]),
        );
        expect(categories.length, greaterThanOrEqualTo(6));
        expect(categories, unorderedEquals(categories.toSet()));
        expect(categories.sublist(1), isNot(orderedEquals(categories)));
      },
    );

    test(
      'fetchCategories returns the same result as the catalog-derived set',
      () async {
        final catalog = await repo.fetchCatalog();
        final categories = await repo.fetchCategories();

        final expected =
            catalog
                .map((product) => product.category)
                .where((category) => category.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
        expect(categories, expected);
      },
    );

    test('propagates failures from the underlying cart repository', () async {
      final failing = MockCatalogRepository(
        cartRepository: _FailingCartRepository(),
      );

      expect(failing.fetchCatalog(), throwsStateError);
      expect(failing.fetchCategories(), throwsStateError);
    });
  });
}
