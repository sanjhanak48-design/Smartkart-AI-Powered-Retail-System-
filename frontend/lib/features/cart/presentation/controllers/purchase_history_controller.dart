import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/cart_repository.dart';
import '../../domain/models/order.dart';
import 'cart_controller.dart';

sealed class HistoryState {
  const HistoryState();
}

class HistoryInitial extends HistoryState {
  const HistoryInitial();
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

class HistoryLoaded extends HistoryState {
  const HistoryLoaded(this.orders);

  final List<Order> orders;
}

class HistoryEmpty extends HistoryState {
  const HistoryEmpty();
}

class HistoryError extends HistoryState {
  const HistoryError(this.message);

  final String message;
}

class OrderLoading extends HistoryState {
  const OrderLoading();
}

class OrderLoaded extends HistoryState {
  const OrderLoaded(this.order);

  final Order order;
}

class OrderNotFound extends HistoryState {
  const OrderNotFound();
}

class PurchaseHistoryController extends Notifier<HistoryState> {
  late final CartRepository _repository;

  @override
  HistoryState build() {
    _repository = ref.watch(cartRepositoryProvider);
    return const HistoryInitial();
  }

  Future<void> fetchHistory() async {
    state = const HistoryLoading();
    try {
      final orders = await _repository.getOrders();
      if (orders.isEmpty) {
        state = const HistoryEmpty();
      } else {
        state = HistoryLoaded(orders);
      }
    } catch (_) {
      state = const HistoryError(
        'Unable to load order history. Please try again.',
      );
    }
  }

  Future<void> fetchOrderById(String orderId) async {
    state = const OrderLoading();
    try {
      final order = await _repository.getOrderById(orderId);
      if (order == null) {
        state = const OrderNotFound();
      } else {
        state = OrderLoaded(order);
      }
    } catch (_) {
      state = const HistoryError('Unable to load the order. Please try again.');
    }
  }
}

final purchaseHistoryControllerProvider =
    NotifierProvider<PurchaseHistoryController, HistoryState>(
      PurchaseHistoryController.new,
    );
