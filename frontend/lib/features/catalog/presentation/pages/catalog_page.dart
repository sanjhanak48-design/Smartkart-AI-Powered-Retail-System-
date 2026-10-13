import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/link_cart_banner.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../cart/domain/models/cart.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../controllers/catalog_controller.dart';

class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key});

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(catalogControllerProvider.notifier).loadCatalog();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addToCart(Product product) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(cartControllerProvider.notifier).simulateAdd(product.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${product.name} added to your cart')),
        );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _clearAll() {
    _searchController.clear();
    ref.read(catalogControllerProvider.notifier).clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogControllerProvider);
    final cartState = ref.watch(cartControllerProvider);
    final showLinkBanner = cartState is CartInitial;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Products'),
        actions: [
          if (catalogState is CatalogLoaded)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: Text(
                  catalogState.products.length == 1
                      ? '1 product'
                      : '${catalogState.products.length} products',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: showLinkBanner
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinkCartBanner(
                    message: 'Link a cart to add products from the catalog.',
                    onLinkCart: () => context.push('/link-cart'),
                  ),
                  Expanded(child: _buildState(context, catalogState)),
                ],
              )
            : _buildState(context, catalogState),
      ),
    );
  }

  Widget _buildState(BuildContext context, CatalogState state) {
    if (state is CatalogInitial || state is CatalogLoading) {
      return const LoadingIndicator();
    }

    if (state is CatalogError) {
      return ErrorView(
        message: state.message,
        onAction: () =>
            ref.read(catalogControllerProvider.notifier).loadCatalog(),
      );
    }

    if (state is CatalogLoaded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FilterBar(
            categories: state.categories,
            selectedCategory: state.category,
            searchController: _searchController,
            onSearch: (value) =>
                ref.read(catalogControllerProvider.notifier).search(value),
            onCategorySelected: (category) => ref
                .read(catalogControllerProvider.notifier)
                .setCategory(category),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              itemCount: state.products.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final product = state.products[index];
                return _ProductCard(
                  product: product,
                  isBusy: _busy,
                  onAdd: () => _addToCart(product),
                );
              },
            ),
          ),
        ],
      );
    }

    if (state is CatalogEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FilterBar(
            categories: state.categories,
            selectedCategory: state.category,
            searchController: _searchController,
            onSearch: (value) =>
                ref.read(catalogControllerProvider.notifier).search(value),
            onCategorySelected: (category) => ref
                .read(catalogControllerProvider.notifier)
                .setCategory(category),
          ),
          Expanded(
            child: EmptyStateView(
              icon: Icons.search_off,
              title: state.query.isNotEmpty || state.category != null
                  ? 'No products match'
                  : 'No products available',
              message: state.query.isNotEmpty || state.category != null
                  ? 'Try a different search term or category.'
                  : 'Check back soon for new products.',
              action: FilledButton(
                onPressed: state.query.isNotEmpty || state.category != null
                    ? _clearAll
                    : () => ref
                          .read(catalogControllerProvider.notifier)
                          .loadCatalog(),
                child: Text(
                  state.query.isNotEmpty || state.category != null
                      ? 'Clear Filters'
                      : 'Refresh',
                ),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.categories,
    required this.selectedCategory,
    required this.searchController,
    required this.onSearch,
    required this.onCategorySelected,
  });

  final List<String> categories;
  final String? selectedCategory;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xxs,
        AppSpacing.md,
        AppSpacing.xxs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearch,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search products',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Clear search',
                      onPressed: () {
                        searchController.clear();
                        onSearch('');
                      },
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  visualDensity: VisualDensity.compact,
                  label: const Text('All'),
                  selected: selectedCategory == null,
                  onSelected: (_) => onCategorySelected(null),
                ),
                for (final category in categories) ...[
                  const SizedBox(width: AppSpacing.xs),
                  ChoiceChip(
                    visualDensity: VisualDensity.compact,
                    label: Text(category),
                    selected: selectedCategory == category,
                    onSelected: (_) => onCategorySelected(category),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isBusy,
    required this.onAdd,
  });

  final Product product;
  final bool isBusy;
  final VoidCallback onAdd;

  String get _fallbackGlyph =>
      product.name.isEmpty ? '?' : product.name[0].toUpperCase();

  @override
  Widget build(BuildContext context) {
    final emoji = product.emojiIcon;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: emoji != null
                  ? Text(emoji, style: const TextStyle(fontSize: 24))
                  : Text(
                      _fallbackGlyph,
                      style: AppTextStyles.subheading.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.price.toStringAsFixed(2)}',
                    style: AppTextStyles.price,
                  ),
                  if (product.category.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _CategoryChip(category: product.category),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton.tonal(
              onPressed: isBusy ? null : onAdd,
              child: const Text('+ Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(category, style: AppTextStyles.label),
    );
  }
}
