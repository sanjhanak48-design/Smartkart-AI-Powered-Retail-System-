import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/domain/models/cart.dart';
import '../../data/repositories/catalog_repository.dart';

sealed class CatalogState {
  const CatalogState();
}

class CatalogInitial extends CatalogState {
  const CatalogInitial();
}

class CatalogLoading extends CatalogState {
  const CatalogLoading();
}

class CatalogLoaded extends CatalogState {
  const CatalogLoaded({
    required this.products,
    required this.categories,
    required this.query,
    this.category,
  });

  final List<Product> products;
  final List<String> categories;
  final String query;
  final String? category;
}

class CatalogEmpty extends CatalogState {
  const CatalogEmpty({
    required this.categories,
    required this.query,
    this.category,
  });

  final List<String> categories;
  final String query;
  final String? category;
}

class CatalogError extends CatalogState {
  const CatalogError(this.message);

  final String message;
}

/// Owns the product catalog and its search/filter state. The full catalog is
/// fetched once; search and category filtering run locally over the cached
/// list so the repository is not refetched for every query change.
class CatalogController extends Notifier<CatalogState> {
  late final CatalogRepository _repository;
  List<Product> _catalog = const [];
  List<String> _categories = const [];
  String _query = '';
  String? _category;
  bool _loaded = false;

  @override
  CatalogState build() {
    _repository = ref.watch(catalogRepositoryProvider);
    return const CatalogInitial();
  }

  Future<void> loadCatalog() async {
    state = const CatalogLoading();
    try {
      _catalog = await _repository.fetchCatalog();
      _categories =
          _catalog
              .map((product) => product.category)
              .where((category) => category.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      _loaded = true;
      _emit();
    } catch (_) {
      _loaded = false;
      _catalog = const [];
      _categories = const [];
      _query = '';
      _category = null;
      state = const CatalogError('Unable to load products. Please try again.');
    }
  }

  /// Filters by product-name substring. Case-insensitive; whitespace trimmed.
  void search(String query) {
    _query = query.trim();
    _emit();
  }

  /// Filters by an exact category. A null category clears the filter.
  void setCategory(String? category) {
    _category = category;
    _emit();
  }

  void clearFilters() {
    _query = '';
    _category = null;
    _emit();
  }

  void _emit() {
    if (!_loaded) {
      return;
    }

    final normalizedQuery = _query.toLowerCase();
    final filtered = _catalog.where((product) {
      final matchesQuery =
          normalizedQuery.isEmpty ||
          product.name.toLowerCase().contains(normalizedQuery);
      final matchesCategory =
          _category == null || product.category == _category;
      return matchesQuery && matchesCategory;
    }).toList();

    if (filtered.isEmpty) {
      state = CatalogEmpty(
        categories: _categories,
        query: _query,
        category: _category,
      );
      return;
    }

    state = CatalogLoaded(
      products: filtered,
      categories: _categories,
      query: _query,
      category: _category,
    );
  }
}

final catalogControllerProvider =
    NotifierProvider<CatalogController, CatalogState>(CatalogController.new);
