// Focused unit tests for the QrScannerController state machine.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/features/cart/data/repositories/cart_repository.dart';
import 'package:smartkart/features/cart/data/repositories/qr_cart_link_repository.dart';
import 'package:smartkart/features/cart/domain/models/cart.dart';
import 'package:smartkart/features/cart/presentation/controllers/cart_controller.dart';
import 'package:smartkart/features/cart/presentation/controllers/qr_scanner_controller.dart';

class _FakeQrCartLinkRepository implements QrCartLinkRepository {
  final _delegate = MockQrCartLinkRepository();
  Completer<bool>? knownGate;
  bool knownResult = true;
  int isKnownCalls = 0;

  @override
  String? parseCartId(String raw) => _delegate.parseCartId(raw);

  @override
  Future<bool> isKnownCart(String cartId) async {
    isKnownCalls++;
    final gate = knownGate;
    if (gate != null) {
      await gate.future;
    }
    return knownResult;
  }
}

class _FailingCartRepository extends MockCartRepository {
  @override
  Future<Cart> linkCart(String cartId) async {
    throw StateError('unavailable');
  }
}

void main() {
  ProviderContainer containerWith({
    QrCartLinkRepository? qrRepository,
    CartRepository? cartRepository,
  }) {
    final container = ProviderContainer(
      overrides: [
        if (qrRepository != null)
          qrCartLinkRepositoryProvider.overrideWithValue(qrRepository),
        if (cartRepository != null)
          cartRepositoryProvider.overrideWithValue(cartRepository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('initial state is idle', () {
    final container = containerWith();
    expect(container.read(qrScannerControllerProvider), isA<QrIdle>());
  });

  test('a valid scan flows idle → validating → linking → linked', () async {
    final qrRepo = _FakeQrCartLinkRepository()..knownGate = Completer<bool>();
    final container = containerWith(qrRepository: qrRepo);
    final controller = container.read(qrScannerControllerProvider.notifier);

    final future = controller.onQrDetected('smartkart://cart/CART-1');
    expect(container.read(qrScannerControllerProvider), isA<QrValidating>());

    qrRepo.knownGate!.complete(true);

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(container.read(qrScannerControllerProvider), isA<QrLinking>());

    await future;
    final state = container.read(qrScannerControllerProvider);
    expect(state, isA<QrLinked>());
    expect((state as QrLinked).cartId, 'CART-1');
  });

  test('an invalid payload becomes QrInvalid without linking', () async {
    final qrRepo = _FakeQrCartLinkRepository();
    final container = containerWith(qrRepository: qrRepo);

    await container
        .read(qrScannerControllerProvider.notifier)
        .onQrDetected('garbage');

    final state = container.read(qrScannerControllerProvider);
    expect(state, isA<QrInvalid>());
    expect((state as QrInvalid).message, contains('does not look like'));
    expect(qrRepo.isKnownCalls, 0);
    expect(container.read(cartControllerProvider), isA<CartInitial>());
  });

  test('an unknown cart becomes QrInvalid with a friendly message', () async {
    final qrRepo = _FakeQrCartLinkRepository()..knownResult = false;
    final container = containerWith(qrRepository: qrRepo);

    await container
        .read(qrScannerControllerProvider.notifier)
        .onQrDetected('smartkart://cart/CART-9');

    final state = container.read(qrScannerControllerProvider);
    expect(state, isA<QrInvalid>());
    expect((state as QrInvalid).message, contains('could not be found'));
    expect(container.read(cartControllerProvider), isA<CartInitial>());
  });

  test('a cart-linking failure becomes QrError', () async {
    final container = containerWith(cartRepository: _FailingCartRepository());

    await container
        .read(qrScannerControllerProvider.notifier)
        .onQrDetected('smartkart://cart/CART-1');

    expect(container.read(qrScannerControllerProvider), isA<QrError>());
    expect(container.read(cartControllerProvider), isA<CartError>());
  });

  test('in-flight scans are ignored while processing', () async {
    final qrRepo = _FakeQrCartLinkRepository()..knownGate = Completer<bool>();
    final container = containerWith(qrRepository: qrRepo);
    final controller = container.read(qrScannerControllerProvider.notifier);

    final first = controller.onQrDetected('smartkart://cart/CART-1');
    expect(container.read(qrScannerControllerProvider), isA<QrValidating>());

    await controller.onQrDetected('smartkart://cart/CART-2');
    expect(qrRepo.isKnownCalls, 1);

    qrRepo.knownGate!.complete(true);
    await first;
    expect(container.read(qrScannerControllerProvider), isA<QrLinked>());
    expect(qrRepo.isKnownCalls, 1);
  });

  test('repeated identical successful scans are ignored', () async {
    final qrRepo = _FakeQrCartLinkRepository();
    final container = containerWith(qrRepository: qrRepo);
    final controller = container.read(qrScannerControllerProvider.notifier);

    await controller.onQrDetected('smartkart://cart/CART-1');
    expect(container.read(qrScannerControllerProvider), isA<QrLinked>());

    await controller.onQrDetected('smartkart://cart/CART-1');
    final state = container.read(qrScannerControllerProvider);
    expect(state, isA<QrLinked>());
    expect((state as QrLinked).cartId, 'CART-1');
    expect(qrRepo.isKnownCalls, 1);
  });

  test('reset returns the controller to idle', () async {
    final qrRepo = _FakeQrCartLinkRepository();
    final container = containerWith(qrRepository: qrRepo);
    final controller = container.read(qrScannerControllerProvider.notifier);

    await controller.onQrDetected('smartkart://cart/CART-1');
    expect(container.read(qrScannerControllerProvider), isA<QrLinked>());

    controller.reset();
    expect(container.read(qrScannerControllerProvider), isA<QrIdle>());
  });

  test('a different cart can link after a successful scan', () async {
    final qrRepo = _FakeQrCartLinkRepository();
    final container = containerWith(qrRepository: qrRepo);
    final controller = container.read(qrScannerControllerProvider.notifier);

    await controller.onQrDetected('smartkart://cart/CART-1');
    expect(container.read(qrScannerControllerProvider), isA<QrLinked>());

    await controller.onQrDetected('smartkart://cart/CART-2');
    final state = container.read(qrScannerControllerProvider);
    expect(state, isA<QrLinked>());
    expect((state as QrLinked).cartId, 'CART-2');
    expect(qrRepo.isKnownCalls, 2);

    controller.reset();
    await controller.onQrDetected('smartkart://cart/CART-3');
    final resetState = container.read(qrScannerControllerProvider);
    expect(resetState, isA<QrLinked>());
    expect((resetState as QrLinked).cartId, 'CART-3');
  });
}
