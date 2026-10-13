import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/purchase_history_controller.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/order_summary_card.dart';

class OrderDetailsPage extends ConsumerStatefulWidget {
  const OrderDetailsPage({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends ConsumerState<OrderDetailsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(purchaseHistoryControllerProvider.notifier)
          .fetchOrderById(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(purchaseHistoryControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: SafeArea(child: _buildBody(historyState)),
    );
  }

  Widget _buildBody(HistoryState state) {
    if (state is OrderLoading ||
        state is HistoryInitial ||
        state is HistoryLoading) {
      return const LoadingIndicator();
    }

    if (state is HistoryError) {
      return ErrorView(
        message: state.message,
        actionLabel: 'Back',
        onAction: () => context.pop(),
      );
    }

    if (state is OrderNotFound) {
      return EmptyStateView(
        icon: Icons.receipt_long_outlined,
        title: 'Order not found',
        message: 'This order may have been removed or the ID is incorrect.',
        action: FilledButton(
          onPressed: () => context.go('/history'),
          child: const Text('Back to History'),
        ),
      );
    }

    if (state is OrderLoaded) {
      final order = state.order;
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [OrderSummaryCard(order: order)],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
