import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/app.dart';
import 'package:smartkart/features/auth/data/repositories/auth_repository.dart';
import 'package:smartkart/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:smartkart/features/auth/domain/models/auth_user.dart';

const _user = AuthUser(
  uid: 'uid-123',
  phone: '+919876543210',
  displayName: 'Asha',
);

class _FakeAuthRepository implements AuthRepository {
  AuthUser? currentUser;
  String? verificationIdValue = 'VID-1';
  String? lastPhone;
  int sendOtpCalls = 0;
  Completer<void>? sendGate;
  Object? sendError;

  @override
  String? get verificationId => verificationIdValue;

  @override
  Stream<AuthUser?> authStateChanges() => Stream.value(currentUser);

  @override
  AuthUser? getUser() => currentUser;

  @override
  Future<String?> getIdToken() async => null;

  @override
  Future<void> sendOtp(String phone) async {
    sendOtpCalls++;
    lastPhone = phone;
    final gate = sendGate;
    if (gate != null) {
      await gate.future;
    }
    if (sendError != null) {
      throw sendError!;
    }
    verificationIdValue = 'VID-$sendOtpCalls';
  }

  @override
  Future<void> resendOtp(String phone) async {}

  @override
  Future<AuthUser> verifyOtp(String verificationId, String smsCode) async {
    return _user;
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  Future<void> pumpApp(WidgetTester tester, _FakeAuthRepository fake) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fake)],
        child: const SmartKartApp(),
      ),
    );
  }

  group('Login page', () {
    testWidgets('shows the SmartKart branding', (tester) async {
      await pumpApp(tester, _FakeAuthRepository());
      await tester.pumpAndSettle();

      expect(find.text('SmartKart'), findsOneWidget);
      expect(find.text('Sign in to start shopping'), findsOneWidget);
      expect(find.text('Send OTP'), findsOneWidget);
    });

    testWidgets('rejects a phone number that is not 10 digits', (tester) async {
      final fake = _FakeAuthRepository();
      await pumpApp(tester, fake);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '123');
      await tester.tap(find.text('Send OTP'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid 10-digit number'), findsOneWidget);
      expect(fake.sendOtpCalls, 0);
    });

    testWidgets('formats the number with +91 and navigates to OTP', (
      tester,
    ) async {
      final fake = _FakeAuthRepository();
      await pumpApp(tester, fake);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '9876543210');
      await tester.tap(find.text('Send OTP'));
      await tester.pumpAndSettle();

      expect(fake.sendOtpCalls, 1);
      expect(fake.lastPhone, '+919876543210');
      expect(find.text('Enter the code'), findsOneWidget);
    });

    testWidgets('shows a spinner and ignores taps while sending', (
      tester,
    ) async {
      final fake = _FakeAuthRepository()..sendGate = Completer<void>();
      await pumpApp(tester, fake);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '9876543210');
      await tester.tap(find.text('Send OTP'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();
      expect(fake.sendOtpCalls, 1);

      fake.sendGate!.complete();
      await tester.pumpAndSettle();

      expect(find.text('Enter the code'), findsOneWidget);
    });

    testWidgets('shows a friendly error when sending fails', (tester) async {
      final fake = _FakeAuthRepository()
        ..sendError = FirebaseAuthException(code: 'invalid-phone-number');
      await pumpApp(tester, fake);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '9876543210');
      await tester.tap(find.text('Send OTP'));
      await tester.pumpAndSettle();

      expect(
        find.text('The phone number is invalid. Please check and try again.'),
        findsOneWidget,
      );
    });
  });
}
