import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/purchase_history_controller.dart';
import '../../domain/models/order.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/status_badge.dart';

class PurchaseHistoryPage extends ConsumerStatefulWidget {
  const PurchaseHistoryPage({super.key});

  @override
  ConsumerState<PurchaseHistoryPage> createState() =>
      _PurchaseHistoryPageState();
}

class _PurchaseHistoryPageState extends ConsumerState<PurchaseHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(purchaseHistoryControllerProvider.notifier).fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(purchaseHistoryControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase History')),
      body: SafeArea(child: _buildBody(historyState)),
    );
  }

  Widget _buildBody(HistoryState state) {
    if (state is HistoryInitial || state is HistoryLoading) {
      return const LoadingIndicator();
    }

    if (state is HistoryError) {
      return ErrorView(
        message: state.message,
        onAction: () =>
            ref.read(purchaseHistoryControllerProvider.notifier).fetchHistory(),
      );
    }

    if (state is HistoryEmpty) {
      return EmptyStateView(
        icon: Icons.receipt_long_outlined,
        title: 'No orders yet',
        message: 'Place an order to see it here.',
        action: FilledButton(
          onPressed: () => context.go('/'),
          child: const Text('Go Home'),
        ),
      );
    }

    if (state is HistoryLoaded) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        itemCount: state.orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final order = state.orders[index];
          return _OrderHistoryCard(order: order);
        },
      );
    }

    return const SizedBox.shrink();
  }
}

class _OrderHistoryCard extends StatelessWidget {
  const _OrderHistoryCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () => context.push('/history/${order.orderId}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 26,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.orderId,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusBadge(
                          label: 'Paid',
                          icon: Icons.check_circle,
                          color: AppColors.badgeGreen,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateTimeFormat.date(order.createdAt)}  '
                      '${DateTimeFormat.time(order.createdAt)}',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.totalQuantity} item${order.totalQuantity == 1 ? '' : 's'}  —  ₹${order.totalAfterDiscount.toStringAsFixed(2)}'
                      '${order.discount > 0 ? '  (−₹${order.discount.toStringAsFixed(2)} reward)' : ''}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
