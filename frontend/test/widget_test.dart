// Basic widget test to verify the SmartKart app builds and renders.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/app.dart';
import 'package:smartkart/features/auth/data/repositories/auth_repository.dart';
import 'package:smartkart/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:smartkart/features/auth/domain/models/auth_user.dart';

// Tests-only fake so the app can build without a configured Firebase instance.
class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._user);

  final AuthUser? _user;

  @override
  String? get verificationId => null;

  @override
  Stream<AuthUser?> authStateChanges() => Stream.value(_user);

  @override
  AuthUser? getUser() => _user;

  @override
  Future<String?> getIdToken() async => null;

  @override
  Future<void> sendOtp(String phone) async {}

  @override
  Future<void> resendOtp(String phone) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthUser> verifyOtp(String verificationId, String smsCode) async {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('SmartKart app routes unauthenticated users to login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository(null)),
        ],
        child: const SmartKartApp(),
      ),
    );

    expect(find.text('Sign in to start shopping'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
  });
}
