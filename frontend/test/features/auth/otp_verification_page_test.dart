// Focused widget tests for the OTP verification screen.
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/app.dart';
import 'package:smartkart/core/router/app_router.dart';
import 'package:smartkart/features/auth/data/repositories/auth_repository.dart';
import 'package:smartkart/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:smartkart/features/auth/domain/models/auth_user.dart';
import 'package:smartkart/features/auth/presentation/controllers/auth_controller.dart';
import 'package:smartkart/features/home/presentation/pages/home_page.dart';

const _user = AuthUser(uid: 'uid-123', phone: '+919876543210');

class _FakeAuthRepository implements AuthRepository {
  AuthUser? currentUser;
  String? verificationIdValue = 'VID-1';
  String? lastVerifyVerificationId;
  String? lastVerifyCode;
  String? lastResendPhone;
  int verifyOtpCalls = 0;
  int resendOtpCalls = 0;
  Completer<void>? verifyGate;
  Object? verifyError;

  @override
  String? get verificationId => verificationIdValue;

  @override
  Stream<AuthUser?> authStateChanges() => Stream.value(currentUser);

  @override
  AuthUser? getUser() => currentUser;

  @override
  Future<String?> getIdToken() async => null;

  @override
  Future<void> sendOtp(String phone) async {}

  @override
  Future<void> resendOtp(String phone) async {
    resendOtpCalls++;
    lastResendPhone = phone;
    verificationIdValue = 'RESEND-$resendOtpCalls';
  }

  @override
  Future<AuthUser> verifyOtp(String verificationId, String smsCode) async {
    verifyOtpCalls++;
    lastVerifyVerificationId = verificationId;
    lastVerifyCode = smsCode;
    final gate = verifyGate;
    if (gate != null) {
      await gate.future;
    }
    if (verifyError != null) {
      throw verifyError!;
    }
    return _user;
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  Future<ProviderContainer> pumpOtpScreen(
    WidgetTester tester,
    _FakeAuthRepository fake,
  ) async {
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    await container
        .read(authControllerProvider.notifier)
        .sendOtp('+919876543210');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SmartKartApp(),
      ),
    );
    await tester.pump();
    container.read(appRouterProvider).go('/otp');
    await tester.pumpAndSettle();
    return container;
  }

  group('OTP page', () {
    testWidgets('renders the verification screen', (tester) async {
      await pumpOtpScreen(tester, _FakeAuthRepository());

      expect(find.text('Enter the code'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Verify OTP'), findsOneWidget);
      expect(find.text('Resend OTP'), findsOneWidget);
      expect(find.text('Wrong number? Go back'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('rejects a code that is not 6 digits', (tester) async {
      final fake = _FakeAuthRepository();
      await pumpOtpScreen(tester, fake);

      await tester.enterText(find.byType(TextField), '12345');
      await tester.tap(find.widgetWithText(FilledButton, 'Verify OTP'));
      await tester.pump();

      expect(find.text('Enter the 6-digit code.'), findsOneWidget);
      expect(fake.verifyOtpCalls, 0);
    });

    testWidgets('verifies a valid code and navigates home', (tester) async {
      final fake = _FakeAuthRepository();
      final container = await pumpOtpScreen(tester, fake);

      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.widgetWithText(FilledButton, 'Verify OTP'));
      await tester.pumpAndSettle();

      expect(fake.verifyOtpCalls, 1);
      expect(fake.lastVerifyVerificationId, 'VID-1');
      expect(fake.lastVerifyCode, '123456');
      expect(container.read(authControllerProvider), isA<AuthAuthenticated>());
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('shows a spinner and ignores taps while verifying', (
      tester,
    ) async {
      final fake = _FakeAuthRepository()..verifyGate = Completer<void>();
      final container = await pumpOtpScreen(tester, fake);

      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.widgetWithText(FilledButton, 'Verify OTP'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();
      expect(fake.verifyOtpCalls, 1);

      fake.verifyGate!.complete();
      await tester.pumpAndSettle();

      expect(container.read(authControllerProvider), isA<AuthAuthenticated>());
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('shows a friendly error when the code is wrong', (
      tester,
    ) async {
      final fake = _FakeAuthRepository()
        ..verifyError = FirebaseAuthException(
          code: 'invalid-verification-code',
        );
      await pumpOtpScreen(tester, fake);

      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.widgetWithText(FilledButton, 'Verify OTP'));
      await tester.pumpAndSettle();

      expect(
        find.text('The code is incorrect. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Enter the code'), findsOneWidget);
      expect(fake.verifyOtpCalls, 1);
    });

    testWidgets('resends the OTP and verifies with the new id', (tester) async {
      final fake = _FakeAuthRepository();
      final container = await pumpOtpScreen(tester, fake);

      await tester.tap(find.text('Resend OTP'));
      await tester.pumpAndSettle();

      expect(fake.resendOtpCalls, 1);
      expect(fake.lastResendPhone, '+919876543210');
      final state = container.read(authControllerProvider);
      expect(state, isA<AuthOtpSent>());
      expect((state as AuthOtpSent).verificationId, 'RESEND-1');

      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.widgetWithText(FilledButton, 'Verify OTP'));
      await tester.pumpAndSettle();

      expect(fake.lastVerifyVerificationId, 'RESEND-1');
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('navigates back to login via Wrong number', (tester) async {
      await pumpOtpScreen(tester, _FakeAuthRepository());

      await tester.tap(find.text('Wrong number? Go back'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to start shopping'), findsOneWidget);
      expect(find.text('Enter the code'), findsNothing);
    });
  });
}
