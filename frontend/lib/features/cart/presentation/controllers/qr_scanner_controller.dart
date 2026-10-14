import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/qr_cart_link_repository.dart';
import '../controllers/cart_controller.dart';

sealed class QrScanState {
  const QrScanState();
}

class QrIdle extends QrScanState {
  const QrIdle();
}

class QrValidating extends QrScanState {
  const QrValidating(this.payload);

  final String payload;
}

class QrLinking extends QrScanState {
  const QrLinking(this.payload);

  final String payload;
}

class QrLinked extends QrScanState {
  const QrLinked(this.cartId);

  final String cartId;
}

class QrInvalid extends QrScanState {
  const QrInvalid(this.message);

  final String message;
}

class QrError extends QrScanState {
  const QrError(this.message);

  final String message;
}

/// Coordinates the QR cart-linking flow.
///
/// The controller validates the scanned payload and delegates the actual cart
/// linking to the existing [CartController] so the app keeps a single
/// cart-session architecture.
class QrScannerController extends Notifier<QrScanState> {
  late final QrCartLinkRepository _repository;
  bool _processing = false;

  @override
  QrScanState build() {
    _repository = ref.watch(qrCartLinkRepositoryProvider);
    return const QrIdle();
  }

  /// Handles a freshly detected QR payload.
  Future<void> onQrDetected(String raw) async {
    if (_processing) {
      return;
    }

    final current = state;
    if (current is QrLinked) {
      final sameCart = _repository.parseCartId(raw);
      if (sameCart == null || sameCart == current.cartId) {
        return;
      }
    }

    _processing = true;
    try {
      final cartId = _repository.parseCartId(raw);
      if (cartId == null) {
        state = const QrInvalid(
          'That does not look like a SmartKart cart QR. Please try again.',
        );
        return;
      }

      state = QrValidating(raw);
      if (!await _repository.isKnownCart(cartId)) {
        state = const QrInvalid(
          'This cart could not be found. Please scan a supported cart.',
        );
        return;
      }

      state = QrLinking(raw);
      await ref.read(cartControllerProvider.notifier).linkCart(cartId);
      if (ref.read(cartControllerProvider) is CartError) {
        state = const QrError('Unable to link the cart. Please try again.');
        return;
      }

      state = QrLinked(cartId);
    } finally {
      _processing = false;
    }
  }

  /// Clears the current scan outcome so the user can retry or rescan.
  void reset() {
    state = const QrIdle();
  }
}

final qrScannerControllerProvider =
    NotifierProvider<QrScannerController, QrScanState>(QrScannerController.new);
