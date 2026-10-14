// Widget tests for the QR scanner page using the injected scanner seam
// (no physical camera or the mobile_scanner plugin is required).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/app.dart';
import 'package:smartkart/features/auth/data/repositories/auth_repository.dart';
import 'package:smartkart/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:smartkart/features/auth/domain/models/auth_user.dart';
import 'package:smartkart/features/cart/data/repositories/qr_cart_link_repository.dart';
import 'package:smartkart/features/cart/presentation/pages/qr_scanner_page.dart';

const _user = AuthUser(uid: 'uid-123', phone: '+919876543210');

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.currentUser});

  AuthUser? currentUser;
  String? verificationIdValue = 'VID-1';
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  @override
  String? get verificationId => verificationIdValue;

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  @override
  AuthUser? getUser() => currentUser;

  @override
  Future<String?> getIdToken() async => null;

  @override
  Future<void> sendOtp(String phone) async {}

  @override
  Future<void> resendOtp(String phone) async {
    verificationIdValue = 'RESEND-2';
  }

  @override
  Future<AuthUser> verifyOtp(String verificationId, String smsCode) async {
    return _user;
  }

  @override
  Future<void> signOut() async {
    currentUser = null;
    _controller.add(null);
  }
}

class _FakeQrCartLinkRepository implements QrCartLinkRepository {
  final _delegate = MockQrCartLinkRepository();
  Completer<bool>? knownGate;
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
    return _delegate.isKnownCart(cartId);
  }
}

void main() {
  late _FakeQrCartLinkRepository qrRepo;
  late String payload;

  Widget fakeScanner(BuildContext context, ValueChanged<String> onDetect) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: OutlinedButton(
        onPressed: () => onDetect(payload),
        child: const Text('Emit Scan'),
      ),
    );
  }

  Future<void> pumpScanner(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _FakeAuthRepository(currentUser: _user),
        ),
        qrCartLinkRepositoryProvider.overrideWithValue(qrRepo),
        qrScannerBuilderProvider.overrideWithValue(fakeScanner),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SmartKartApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Link Cart'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    qrRepo = _FakeQrCartLinkRepository();
    payload = 'smartkart://cart/CART-1';
  });

  testWidgets('shows the scanner UI with guidance and scan frame', (
    tester,
  ) async {
    await pumpScanner(tester);

    expect(find.text('Scan Cart'), findsOneWidget);
    expect(
      find.text('Point the camera at the QR code on the cart'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('scan_frame')), findsOneWidget);
    expect(find.text('Emit Scan'), findsOneWidget);
  });

  testWidgets('a valid scan links the cart and navigates to the Live Cart', (
    tester,
  ) async {
    await pumpScanner(tester);

    await tester.tap(find.text('Emit Scan'));
    await tester.pumpAndSettle();

    expect(find.text('Live Cart'), findsOneWidget);
    expect(find.text('Linked Cart ID: CART-1'), findsOneWidget);
    expect(find.text('Cart Connected'), findsOneWidget);
    expect(find.byType(QrScannerPage), findsNothing);
  });

  testWidgets('an invalid scan shows a friendly error that can be retried', (
    tester,
  ) async {
    payload = 'garbage';
    await pumpScanner(tester);

    await tester.tap(find.text('Emit Scan'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'That does not look like a SmartKart cart QR. Please try again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Scan Again'), findsOneWidget);
    expect(find.text('Scan Cart'), findsOneWidget);

    await tester.tap(find.text('Scan Again'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'That does not look like a SmartKart cart QR. Please try again.',
      ),
      findsNothing,
    );
  });

  testWidgets('an unknown cart shows the not-found error', (tester) async {
    payload = 'smartkart://cart/CART-9';
    await pumpScanner(tester);

    await tester.tap(find.text('Emit Scan'));
    await tester.pumpAndSettle();

    expect(
      find.text('This cart could not be found. Please scan a supported cart.'),
      findsOneWidget,
    );
    expect(find.text('Scan Again'), findsOneWidget);
  });

  testWidgets('duplicate scans are ignored while a scan is processing', (
    tester,
  ) async {
    qrRepo.knownGate = Completer<bool>();
    await pumpScanner(tester);

    await tester.tap(find.text('Emit Scan'));
    await tester.pump();
    expect(find.text('Checking cart…'), findsOneWidget);

    await tester.tap(find.text('Emit Scan'));
    await tester.pump();
    expect(qrRepo.isKnownCalls, 1);

    qrRepo.knownGate!.complete(true);
    await tester.pumpAndSettle();

    expect(find.text('Live Cart'), findsOneWidget);
    expect(find.text('Linked Cart ID: CART-1'), findsOneWidget);
  });

  testWidgets('back navigation returns to the Home page', (tester) async {
    await pumpScanner(tester);

    expect(find.text('Scan Cart'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Scan Cart'), findsNothing);
    expect(find.text('Welcome!'), findsOneWidget);
  });
}
