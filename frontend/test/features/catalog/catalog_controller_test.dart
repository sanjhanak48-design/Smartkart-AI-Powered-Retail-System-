// Focused unit tests for the CatalogController search/filter state machine.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/features/cart/domain/models/cart.dart';
import 'package:smartkart/features/catalog/data/repositories/catalog_repository.dart';
import 'package:smartkart/features/catalog/presentation/controllers/catalog_controller.dart';

const _milk = Product(
  id: 'milk',
  name: 'Milk',
  price: 30,
  category: 'Dairy',
  emojiIcon: '🥛',
);
const _bread = Product(
  id: 'bread',
  name: 'Bread',
  price: 40,
  category: 'Bakery',
  emojiIcon: '🍞',
);
const _tea = Product(
  id: 'tea',
  name: 'Tea',
  price: 50,
  category: 'Beverages',
  emojiIcon: '🍵',
);
const _chocolate = Product(
  id: 'chocolate',
  name: 'Chocolate',
  price: 45,
  category: 'Snacks',
  emojiIcon: '🍫',
);
const _chips = Product(
  id: 'chips',
  name: 'Potato Chips',
  price: 30,
  category: 'Snacks',
  emojiIcon: '🍟',
);

const _catalog = [_milk, _bread, _tea, _chocolate, _chips];

class _FakeCatalogRepository implements CatalogRepository {
  _FakeCatalogRepository(this.products);

  final List<Product> products;
  bool fail = false;
  Completer<void>? gate;
  int fetchCalls = 0;

  @override
  Future<List<Product>> fetchCatalog() async {
    fetchCalls++;
    final g = gate;
    if (g != null) {
      await g.future;
    }
    if (fail) {
      throw StateError('unavailable');
    }
    return List.unmodifiable(products);
  }

  @override
  Future<List<String>> fetchCategories() async {
    final categories =
        products
            .map((product) => product.category)
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return List.unmodifiable(categories);
  }
}

void main() {
  ProviderContainer containerWith(CatalogRepository repository) {
    final container = ProviderContainer(
      overrides: [catalogRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('initial state is CatalogInitial', () {
    final container = containerWith(_FakeCatalogRepository(_catalog));
    expect(container.read(catalogControllerProvider), isA<CatalogInitial>());
  });

  test(
    'loadCatalog emits CatalogLoaded with products and derived categories',
    () async {
      final container = containerWith(_FakeCatalogRepository(_catalog));

      await container.read(catalogControllerProvider.notifier).loadCatalog();

      final state = container.read(catalogControllerProvider);
      expect(state, isA<CatalogLoaded>());
      final loaded = state as CatalogLoaded;
      expect(loaded.products, hasLength(5));
      expect(loaded.categories, ['Bakery', 'Beverages', 'Dairy', 'Snacks']);
      expect(loaded.query, isEmpty);
      expect(loaded.category, isNull);
    },
  );

  test('state is CatalogLoading while the catalog is being fetched', () async {
    final repo = _FakeCatalogRepository(_catalog)..gate = Completer<void>();
    final container = containerWith(repo);

    final future = container
        .read(catalogControllerProvider.notifier)
        .loadCatalog();
    expect(container.read(catalogControllerProvider), isA<CatalogLoading>());

    repo.gate!.complete();
    await future;
    expect(container.read(catalogControllerProvider), isA<CatalogLoaded>());
  });

  test('searching does not refetch the cached catalog', () async {
    final repo = _FakeCatalogRepository(_catalog);
    final container = containerWith(repo);

    await container.read(catalogControllerProvider.notifier).loadCatalog();
    expect(repo.fetchCalls, 1);

    container.read(catalogControllerProvider.notifier).search('mil');
    expect(repo.fetchCalls, 1);
  });

  test('search is case-insensitive and trims whitespace', () async {
    final container = containerWith(_FakeCatalogRepository(_catalog));
    await container.read(catalogControllerProvider.notifier).loadCatalog();

    container.read(catalogControllerProvider.notifier).search(' MIL ');
    var state = container.read(catalogControllerProvider) as CatalogLoaded;
    expect(state.products.map((p) => p.id), ['milk']);
    expect(state.query, 'MIL');

    container.read(catalogControllerProvider.notifier).search('tea');
    state = container.read(catalogControllerProvider) as CatalogLoaded;
    expect(state.products.map((p) => p.id), ['tea']);
  });

  test('category filtering matches the category exactly', () async {
    final container = containerWith(_FakeCatalogRepository(_catalog));
    await container.read(catalogControllerProvider.notifier).loadCatalog();

    container.read(catalogControllerProvider.notifier).setCategory('Snacks');
    final state = container.read(catalogControllerProvider) as CatalogLoaded;
    expect(state.products.map((p) => p.id), ['chocolate', 'chips']);

    container.read(catalogControllerProvider.notifier).setCategory('Dairy');
    final dairy = container.read(catalogControllerProvider) as CatalogLoaded;
    expect(dairy.products.map((p) => p.id), ['milk']);
  });

  test('combined search and category filters both apply', () async {
    final container = containerWith(_FakeCatalogRepository(_catalog));
    await container.read(catalogControllerProvider.notifier).loadCatalog();

    container.read(catalogControllerProvider.notifier).search('cho');
    container.read(catalogControllerProvider.notifier).setCategory('Snacks');
    final state = container.read(catalogControllerProvider) as CatalogLoaded;
    expect(state.products.map((p) => p.id), ['chocolate']);
  });

  test(
    'no matches emit CatalogEmpty and clearFilters restores the catalog',
    () async {
      final container = containerWith(_FakeCatalogRepository(_catalog));
      await container.read(catalogControllerProvider.notifier).loadCatalog();

      container.read(catalogControllerProvider.notifier).search('zzz');
      final emptyState = container.read(catalogControllerProvider);
      expect(emptyState, isA<CatalogEmpty>());
      final empty = emptyState as CatalogEmpty;
      expect(empty.categories, ['Bakery', 'Beverages', 'Dairy', 'Snacks']);
      expect(empty.query, 'zzz');

      container.read(catalogControllerProvider.notifier).clearFilters();
      final clearedState = container.read(catalogControllerProvider);
      expect(clearedState, isA<CatalogLoaded>());
      expect((clearedState as CatalogLoaded).products, hasLength(5));
    },
  );

  test('a failed load emits CatalogError and retry recovers', () async {
    final repo = _FakeCatalogRepository(_catalog)..fail = true;
    final container = containerWith(repo);

    await container.read(catalogControllerProvider.notifier).loadCatalog();
    final failedState = container.read(catalogControllerProvider);
    expect(failedState, isA<CatalogError>());
    expect((failedState as CatalogError).message, contains('Unable to load'));

    repo.fail = false;
    await container.read(catalogControllerProvider.notifier).loadCatalog();
    expect(container.read(catalogControllerProvider), isA<CatalogLoaded>());
  });

  test('search before loading is a no-op', () {
    final container = containerWith(_FakeCatalogRepository(_catalog));

    container.read(catalogControllerProvider.notifier).search('milk');
    expect(container.read(catalogControllerProvider), isA<CatalogInitial>());
  });
}
