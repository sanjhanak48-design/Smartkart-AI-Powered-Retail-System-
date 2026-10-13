import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Known mock cart IDs recognized by the mock cart-link repository.
const mockKnownCartIds = {'CART-1', 'CART-2', 'CART-3'};

final RegExp _smartkartUri = RegExp(
  r'^smartkart://cart/([A-Za-z0-9_-]+)$',
  caseSensitive: false,
);
final RegExp _bareCartPattern = RegExp(r'^CART-[0-9]+$');

/// Contract for reading SmartKart cart QR payloads.
///
/// Backend validation will replace the mock in the future; the QR format and
/// cart-linking layers stay separate.
abstract class QrCartLinkRepository {
  /// Parses a raw scanned payload into a cart ID, or returns null when the
  /// payload is not a supported SmartKart cart QR.
  ///
  /// A SmartKart URI must be a full match: extra path or trailing text after
  /// the cart ID is rejected.
  String? parseCartId(String raw);

  /// Whether [cartId] belongs to a known mock cart.
  Future<bool> isKnownCart(String cartId);
}

/// Mock implementation. Only `smartkart://cart/<cartId>` (full match) or the
/// ergonomic bare `CART-<digits>` payloads are accepted.
class MockQrCartLinkRepository implements QrCartLinkRepository {
  @override
  String? parseCartId(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return null;
    }
    final uriMatch = _smartkartUri.firstMatch(value);
    if (uriMatch != null) {
      return uriMatch.group(1);
    }
    if (_bareCartPattern.hasMatch(value)) {
      return value;
    }
    return null;
  }

  @override
  Future<bool> isKnownCart(String cartId) async {
    return mockKnownCartIds.contains(cartId);
  }
}

final qrCartLinkRepositoryProvider = Provider<QrCartLinkRepository>(
  (ref) => MockQrCartLinkRepository(),
);
