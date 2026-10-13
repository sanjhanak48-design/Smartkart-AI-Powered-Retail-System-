// Widget tests covering the auth-guarding router redirects.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/app.dart';
import 'package:smartkart/core/router/app_router.dart';
import 'package:smartkart/features/auth/data/repositories/auth_repository.dart';
import 'package:smartkart/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:smartkart/features/auth/domain/models/auth_user.dart';
import 'package:smartkart/features/auth/presentation/controllers/auth_controller.dart';
import 'package:smartkart/features/cart/presentation/pages/qr_scanner_page.dart';
import 'package:smartkart/features/catalog/presentation/pages/catalog_page.dart';
import 'package:smartkart/features/home/presentation/pages/home_page.dart';

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

void main() {
  Future<ProviderContainer> pumpApp(
    WidgetTester tester,
    _FakeAuthRepository fake,
  ) async {
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SmartKartApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('Auth router', () {
    testWidgets('redirects an unauthenticated user to login', (tester) async {
      await pumpApp(tester, _FakeAuthRepository(currentUser: null));

      expect(find.text('Sign in to start shopping'), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    });

    testWidgets('shows home for an authenticated user', (tester) async {
      await pumpApp(tester, _FakeAuthRepository(currentUser: _user));

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Sign in to start shopping'), findsNothing);
    });

    testWidgets('blocks protected routes when unauthenticated', (tester) async {
      final container = await pumpApp(tester, _FakeAuthRepository());
      final router = container.read(appRouterProvider);

      for (final path in [
        '/profile',
        '/catalog',
        '/history',
        '/history/SM-0001',
        '/checkout',
        '/payment',
        '/smartcoins',
        '/recommendations',
        '/link-cart',
        '/live-cart',
        '/scan-cart',
        '/receipt',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();

        expect(
          find.text('Sign in to start shopping'),
          findsOneWidget,
          reason: '$path should redirect to login',
        );
        expect(find.byType(HomePage), findsNothing, reason: '$path guarded');
      }
    });

    testWidgets('lets an authenticated user open the product catalog', (
      tester,
    ) async {
      await pumpApp(tester, _FakeAuthRepository(currentUser: _user));
      expect(find.byType(HomePage), findsOneWidget);

      await tester.ensureVisible(find.text('Browse Products'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Browse Products'));
      await tester.pumpAndSettle();

      expect(find.byType(CatalogPage), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Shop Products'), findsOneWidget);
    });

    testWidgets('lets an authenticated user open the QR scanner', (
      tester,
    ) async {
      final fake = _FakeAuthRepository(currentUser: _user);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fake),
          qrScannerBuilderProvider.overrideWithValue(
            (context, onDetect) => const SizedBox.shrink(),
          ),
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
      expect(find.byType(HomePage), findsOneWidget);

      await tester.tap(find.byTooltip('Link Cart'));
      await tester.pumpAndSettle();

      expect(find.byType(QrScannerPage), findsOneWidget);
      expect(find.text('Scan Cart'), findsOneWidget);
    });

    testWidgets('keeps the OTP screen open during the OTP flow', (
      tester,
    ) async {
      final container = await pumpApp(tester, _FakeAuthRepository());
      expect(find.text('Sign in to start shopping'), findsOneWidget);

      await container
          .read(authControllerProvider.notifier)
          .sendOtp('+919876543210');
      container.read(appRouterProvider).go('/otp');
      await tester.pumpAndSettle();

      expect(find.text('Enter the code'), findsOneWidget);
      expect(find.text('Sign in to start shopping'), findsNothing);
    });

    testWidgets('redirects an authenticated user out of login', (tester) async {
      final container = await pumpApp(
        tester,
        _FakeAuthRepository(currentUser: _user),
      );
      expect(find.byType(HomePage), findsOneWidget);

      container.read(appRouterProvider).go('/login');
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Sign in to start shopping'), findsNothing);
    });

    testWidgets('returns to login after signing out', (tester) async {
      final container = await pumpApp(
        tester,
        _FakeAuthRepository(currentUser: _user),
      );
      expect(find.byType(HomePage), findsOneWidget);

      await container.read(authControllerProvider.notifier).signOut();
      await tester.pumpAndSettle();

      expect(find.text('Sign in to start shopping'), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    });
  });
}
