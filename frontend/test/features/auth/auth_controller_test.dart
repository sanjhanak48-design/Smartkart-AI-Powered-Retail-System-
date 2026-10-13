// Focused unit tests for the AuthController state machine and flows.
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/features/auth/data/repositories/auth_repository.dart';
import 'package:smartkart/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:smartkart/features/auth/domain/models/auth_user.dart';
import 'package:smartkart/features/auth/presentation/controllers/auth_controller.dart';

const _user = AuthUser(
  uid: 'uid-123',
  phone: '+919876543210',
  displayName: 'Asha',
);

class _FakeAuthRepository implements AuthRepository {
  AuthUser? currentUser;
  String? verificationIdValue = 'VID-1';
  String? lastSendPhone;
  String? lastResendPhone;
  String? lastVerifyVerificationId;
  String? lastVerifyCode;
  int sendOtpCalls = 0;
  int resendOtpCalls = 0;
  int verifyOtpCalls = 0;
  int signOutCalls = 0;
  Completer<void>? sendGate;
  Completer<void>? resendGate;
  Completer<void>? verifyGate;
  Object? sendError;
  Object? resendError;
  Object? verifyError;
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  @override
  String? get verificationId => verificationIdValue;

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  @override
  AuthUser? getUser() => currentUser;

  @override
  Future<String?> getIdToken() async => 'id-token-for-uid';

  @override
  Future<void> sendOtp(String phone) async {
    sendOtpCalls++;
    lastSendPhone = phone;
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
  Future<void> resendOtp(String phone) async {
    resendOtpCalls++;
    lastResendPhone = phone;
    final gate = resendGate;
    if (gate != null) {
      await gate.future;
    }
    if (resendError != null) {
      throw resendError!;
    }
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
  Future<void> signOut() async {
    signOutCalls++;
    _controller.add(null);
  }
}

void main() {
  Future<void> flushMicrotasks() async {
    // Allows broadcast stream events to reach the controller listener.
    await Future<void>.delayed(Duration.zero);
  }

  ProviderContainer containerWith(AuthRepository repository) {
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('initial state', () {
    test('is unauthenticated when no user is signed in', () {
      final container = containerWith(_FakeAuthRepository());
      expect(
        container.read(authControllerProvider),
        isA<AuthUnauthenticated>(),
      );
    });

    test('is authenticated when a user is already signed in', () {
      final fake = _FakeAuthRepository()..currentUser = _user;
      final container = containerWith(fake);
      final state = container.read(authControllerProvider);
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).user.uid, 'uid-123');
    });
  });

  group('auth state stream', () {
    test('emitting a user transitions to authenticated', () async {
      final fake = _FakeAuthRepository();
      final container = containerWith(fake);
      container.read(authControllerProvider);

      fake._controller.add(_user);
      await flushMicrotasks();

      expect(container.read(authControllerProvider), isA<AuthAuthenticated>());
    });

    test('emitting null transitions to unauthenticated', () async {
      final fake = _FakeAuthRepository()..currentUser = _user;
      final container = containerWith(fake);
      container.read(authControllerProvider);
      expect(container.read(authControllerProvider), isA<AuthAuthenticated>());

      fake._controller.add(null);
      await flushMicrotasks();

      expect(
        container.read(authControllerProvider),
        isA<AuthUnauthenticated>(),
      );
    });
  });

  group('sendOtp', () {
    test('succeeds and exposes the verification id and phone', () async {
      final fake = _FakeAuthRepository();
      final container = containerWith(fake);

      await container
          .read(authControllerProvider.notifier)
          .sendOtp('+919876543210');

      expect(fake.sendOtpCalls, 1);
      expect(fake.lastSendPhone, '+919876543210');
      final state = container.read(authControllerProvider);
      expect(state, isA<AuthOtpSent>());
      expect((state as AuthOtpSent).verificationId, 'VID-1');
      expect(state.phone, '+919876543210');
    });

    test('maps invalid-phone-number to a friendly message', () async {
      final fake = _FakeAuthRepository()
        ..sendError = FirebaseAuthException(code: 'invalid-phone-number');
      final container = containerWith(fake);

      await container.read(authControllerProvider.notifier).sendOtp('bad');

      final state = container.read(authControllerProvider);
      expect(state, isA<AuthError>());
      expect(
        (state as AuthError).message,
        'The phone number is invalid. Please check and try again.',
      );
    });

    test('maps a generic failure to a friendly message', () async {
      final fake = _FakeAuthRepository()..sendError = StateError('boom');
      final container = containerWith(fake);

      await container
          .read(authControllerProvider.notifier)
          .sendOtp('+919876543210');

      final state = container.read(authControllerProvider);
      expect(state, isA<AuthError>());
      expect(
        (state as AuthError).message,
        'Something went wrong. Please try again.',
      );
    });

    test('ignores duplicate submissions while sending', () async {
      final fake = _FakeAuthRepository()..sendGate = Completer<void>();
      final container = containerWith(fake);
      final controller = container.read(authControllerProvider.notifier);

      final first = controller.sendOtp('+919876543210');
      expect(container.read(authControllerProvider), isA<AuthSendingOtp>());

      await controller.sendOtp('+919876543219');
      expect(fake.sendOtpCalls, 1);

      fake.sendGate!.complete();
      await first;
      expect(container.read(authControllerProvider), isA<AuthOtpSent>());
    });
  });

  group('verifyOtp', () {
    test('succeeds and transitions to authenticated', () async {
      final fake = _FakeAuthRepository();
      final container = containerWith(fake);
      container.read(authControllerProvider);

      await container
          .read(authControllerProvider.notifier)
          .verifyOtp('VID-1', '123456');

      expect(fake.verifyOtpCalls, 1);
      expect(fake.lastVerifyVerificationId, 'VID-1');
      expect(fake.lastVerifyCode, '123456');
      final state = container.read(authControllerProvider);
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).user.phone, '+919876543210');
    });

    test('maps an invalid OTP to a friendly message', () async {
      final fake = _FakeAuthRepository()
        ..verifyError = FirebaseAuthException(
          code: 'invalid-verification-code',
        );
      final container = containerWith(fake);

      await container
          .read(authControllerProvider.notifier)
          .verifyOtp('VID-1', '000000');

      final state = container.read(authControllerProvider);
      expect(state, isA<AuthError>());
      expect(
        (state as AuthError).message,
        'The code is incorrect. Please try again.',
      );
    });

    test('maps a stale verification id to a friendly message', () async {
      final fake = _FakeAuthRepository()
        ..verifyError = FirebaseAuthException(code: 'invalid-verification-id');
      final container = containerWith(fake);

      await container
          .read(authControllerProvider.notifier)
          .verifyOtp('STALE-1', '123456');

      final state = container.read(authControllerProvider);
      expect(state, isA<AuthError>());
      expect(
        (state as AuthError).message,
        'The code has expired. Please request a new one.',
      );
    });

    test('ignores duplicate submissions while verifying', () async {
      final fake = _FakeAuthRepository()..verifyGate = Completer<void>();
      final container = containerWith(fake);
      final controller = container.read(authControllerProvider.notifier);

      final first = controller.verifyOtp('VID-1', '123456');
      expect(container.read(authControllerProvider), isA<AuthVerifyingOtp>());

      await controller.verifyOtp('VID-1', '654321');
      expect(fake.verifyOtpCalls, 1);

      fake.verifyGate!.complete();
      await first;
      expect(container.read(authControllerProvider), isA<AuthAuthenticated>());
    });
  });

  group('signOut', () {
    test('proxies to the repository and reflects the auth stream', () async {
      final fake = _FakeAuthRepository()..currentUser = _user;
      final container = containerWith(fake);
      container.read(authControllerProvider);
      expect(container.read(authControllerProvider), isA<AuthAuthenticated>());

      await container.read(authControllerProvider.notifier).signOut();
      await flushMicrotasks();

      expect(fake.signOutCalls, 1);
      expect(
        container.read(authControllerProvider),
        isA<AuthUnauthenticated>(),
      );
    });
  });

  group('resendOtp', () {
    test('succeeds and replaces the verification id', () async {
      final fake = _FakeAuthRepository();
      final container = containerWith(fake);

      await container
          .read(authControllerProvider.notifier)
          .resendOtp('+919876543210');

      expect(fake.resendOtpCalls, 1);
      expect(fake.lastResendPhone, '+919876543210');
      final state = container.read(authControllerProvider);
      expect(state, isA<AuthOtpSent>());
      expect((state as AuthOtpSent).verificationId, 'RESEND-1');
      expect(state.phone, '+919876543210');
    });

    test('ignores duplicate submissions while sending', () async {
      final fake = _FakeAuthRepository()..resendGate = Completer<void>();
      final container = containerWith(fake);
      final controller = container.read(authControllerProvider.notifier);

      final first = controller.resendOtp('+919876543210');
      expect(container.read(authControllerProvider), isA<AuthSendingOtp>());

      await controller.resendOtp('+919876543210');
      expect(fake.resendOtpCalls, 1);

      fake.resendGate!.complete();
      await first;
      final state = container.read(authControllerProvider);
      expect(state, isA<AuthOtpSent>());
      expect((state as AuthOtpSent).verificationId, 'RESEND-1');
    });
  });
}
