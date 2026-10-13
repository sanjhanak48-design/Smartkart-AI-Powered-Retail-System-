// Focused unit tests for QR payload parsing and the mock cart registry.
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/features/cart/data/repositories/qr_cart_link_repository.dart';

void main() {
  final repository = MockQrCartLinkRepository();

  group('parseCartId', () {
    test('accepts a valid SmartKart cart URI', () {
      expect(repository.parseCartId('smartkart://cart/CART-1'), 'CART-1');
      expect(repository.parseCartId('smartkart://cart/CART-2'), 'CART-2');
      expect(repository.parseCartId('smartkart://cart/CART-3'), 'CART-3');
    });

    test('matches the scheme and host case-insensitively', () {
      expect(repository.parseCartId('SMARTKART://CART/CART-1'), 'CART-1');
      expect(repository.parseCartId('Smartkart://Cart/cart-1'), 'cart-1');
    });

    test('accepts the ergonomic bare payload format', () {
      expect(repository.parseCartId('CART-1'), 'CART-1');
      expect(repository.parseCartId(' CART-2 '), 'CART-2');
    });

    test('rejects a malformed SmartKart URI', () {
      expect(repository.parseCartId('smartkart://cart/'), isNull);
      expect(repository.parseCartId('smartkart://cart'), isNull);
      expect(repository.parseCartId('smartkart://'), isNull);
    });

    test('rejects unsupported URLs and payloads', () {
      expect(repository.parseCartId('https://example.com/cart/CART-1'), isNull);
      expect(repository.parseCartId('http://smartkart.io/cart/CART-1'), isNull);
      expect(repository.parseCartId('random text'), isNull);
      expect(repository.parseCartId('cart-1'), isNull);
    });

    test('requires a full match and rejects extra path or query text', () {
      expect(repository.parseCartId('smartkart://cart/CART-1/abc'), isNull);
      expect(repository.parseCartId('smartkart://cart/CART-1?x=1'), isNull);
      expect(repository.parseCartId('scan smartkart://cart/CART-1'), isNull);
      expect(repository.parseCartId('smartkart://cart/CART-1 extra'), isNull);
    });

    test('rejects empty payloads', () {
      expect(repository.parseCartId(''), isNull);
      expect(repository.parseCartId('   '), isNull);
    });
  });

  group('isKnownCart', () {
    test('accepts the known mock cart IDs', () async {
      expect(await repository.isKnownCart('CART-1'), isTrue);
      expect(await repository.isKnownCart('CART-2'), isTrue);
      expect(await repository.isKnownCart('CART-3'), isTrue);
    });

    test('rejects an unknown cart ID', () async {
      expect(await repository.isKnownCart('CART-9'), isFalse);
      expect(await repository.isKnownCart('CART-999'), isFalse);
      expect(await repository.isKnownCart(''), isFalse);
    });

    test('an unknown ID still parses but is not a known cart', () {
      expect(repository.parseCartId('smartkart://cart/CART-9'), 'CART-9');
    });
  });
}
