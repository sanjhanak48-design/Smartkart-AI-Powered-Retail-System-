import 'package:flutter/material.dart';

import '../../../features/cart/domain/models/cart.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import 'app_card.dart';

/// A polished, consistent product card with an emoji image area, name, price,
/// an optional tag chip and an Add button. Reused by the Catalog and Smart
/// Picks screens and as the visual basis for cart rows.
class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.product,
    this.tag,
    this.trailing,
    this.onAdd,
    this.isBusy = false,
    this.compact = false,
  });

  final Product product;
  final String? tag;
  final Widget? trailing;
  final VoidCallback? onAdd;
  final bool isBusy;
  final bool compact;

  String get _fallbackGlyph =>
      product.name.isEmpty ? '?' : product.name[0].toUpperCase();

  @override
  Widget build(BuildContext context) {
    final emoji = product.emojiIcon;

    final Row content = Row(
      children: [
        _ImageArea(emoji: emoji, glyph: _fallbackGlyph, compact: compact),
        SizedBox(width: compact ? AppSpacing.sm : AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 3),
              Text(
                '₹${product.price.toStringAsFixed(2)}',
                style: compact
                    ? AppTextStyles.price
                    : AppTextStyles.subheading.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
              ),
              if (tag != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _TagChip(label: tag!),
              ],
            ],
          ),
        ),
        if (trailing != null)
          trailing!
        else if (onAdd != null) ...[
          const SizedBox(width: AppSpacing.xs),
          FilledButton.tonal(
            onPressed: isBusy ? null : onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primarySoft,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              minimumSize: const Size(0, 40),
            ),
            child: const Text('+ Add'),
          ),
        ],
      ],
    );

    return AppCard(
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
      child: content,
    );
  }
}

class _ImageArea extends StatelessWidget {
  const _ImageArea({
    required this.emoji,
    required this.glyph,
    this.compact = false,
  });

  final String? emoji;
  final String glyph;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 48.0 : AppSpacing.productImage;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: emoji != null
          ? Text(emoji!, style: TextStyle(fontSize: size * 0.5))
          : Text(
              glyph,
              style: TextStyle(
                fontSize: size * 0.42,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
      ),
      child: Text(label, style: AppTextStyles.label),
    );
  }
}
