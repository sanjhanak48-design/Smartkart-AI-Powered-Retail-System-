import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/link_cart_banner.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../domain/models/recommended_item.dart';
import '../controllers/recommendations_controller.dart';

class SmartPicksPage extends ConsumerStatefulWidget {
  const SmartPicksPage({super.key});

  @override
  ConsumerState<SmartPicksPage> createState() => _SmartPicksPageState();
}

class _SmartPicksPageState extends ConsumerState<SmartPicksPage> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(recommendationsControllerProvider.notifier)
          .fetchRecommendations();
    });
  }

  Future<void> _addToCart(RecommendedItem item) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(cartControllerProvider.notifier)
          .simulateAdd(item.product.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('${item.product.name} added to your cart')),
        );
      await ref
          .read(recommendationsControllerProvider.notifier)
          .fetchRecommendations();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendationsState = ref.watch(recommendationsControllerProvider);
    final cartState = ref.watch(cartControllerProvider);
    final showLinkBanner = cartState is CartInitial;

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Picks')),
      body: SafeArea(
        child: showLinkBanner
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinkCartBanner(
                    message: 'Link a cart to add recommended items.',
                    onLinkCart: () => context.push('/link-cart'),
                  ),
                  Expanded(child: _buildState(context, recommendationsState)),
                ],
              )
            : _buildState(context, recommendationsState),
      ),
    );
  }

  Widget _buildState(BuildContext context, RecommendationsState state) {
    if (state is RecommendationsInitial || state is RecommendationsLoading) {
      return const LoadingIndicator();
    }

    if (state is RecommendationsError) {
      return ErrorView(
        message: state.message,
        onAction: () => ref
            .read(recommendationsControllerProvider.notifier)
            .fetchRecommendations(),
      );
    }

    if (state is RecommendationsEmpty) {
      return EmptyStateView(
        icon: Icons.auto_awesome_outlined,
        title: 'No recommendations right now',
        message: 'Try linking a cart and adding a few products.',
        action: FilledButton(
          onPressed: () => context.go('/'),
          child: const Text('Go Home'),
        ),
      );
    }

    if (state is RecommendationsLoaded) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        itemCount: state.items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const _AiIntroCard();
          }
          final item = state.items[index - 1];
          return _RecommendationCard(
            item: item,
            isBusy: _busy,
            onAdd: () => _addToCart(item),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}

/// Branded intro strip explaining the AI-powered nature of the page.
class _AiIntroCard extends StatelessWidget {
  const _AiIntroCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: AppSpacing.iconBox,
            height: AppSpacing.iconBox,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.accentGradient,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Text(
              'AI analyzes your cart & purchase history to surface the '
              'best picks for you.',
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.item,
    required this.isBusy,
    required this.onAdd,
  });

  final RecommendedItem item;
  final bool isBusy;
  final VoidCallback onAdd;

  String get _glyph =>
      item.product.name.isEmpty ? '?' : item.product.name[0].toUpperCase();

  @override
  Widget build(BuildContext context) {
    final emoji = item.product.emojiIcon;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: AppColors.badgeAmber.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.badgeAmber, width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: AppSpacing.productImage,
                height: AppSpacing.productImage,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: emoji != null
                    ? Text(emoji, style: const TextStyle(fontSize: 28))
                    : Text(
                        _glyph,
                        style: AppTextStyles.subheading.copyWith(
                          color: AppColors.badgeAmber,
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 13,
                          color: AppColors.badgeAmber,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: Text(
                            item.reason,
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.badgeAmber,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.product.name,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${item.product.price.toStringAsFixed(2)}',
                      style: AppTextStyles.price,
                    ),
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
      ),
    );
  }
}
