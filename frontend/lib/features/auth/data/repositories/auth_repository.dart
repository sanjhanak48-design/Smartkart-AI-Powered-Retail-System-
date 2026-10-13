import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/models/auth_user.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  String? _verificationId;
  int? _resendingToken;

  String? get verificationId => _verificationId;

  Future<void> sendOtp(String phone) async {
    final completer = Completer<void>();

    _verificationId = null;
    _resendingToken = null;

    _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 120),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _firebaseAuth.signInWithCredential(credential);
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      verificationFailed: (FirebaseAuthException error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      codeSent: (String verificationId, int? forceResendingToken) {
        _verificationId = verificationId;
        _resendingToken = forceResendingToken;
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );

    await completer.future;
  }

  /// Re-sends the OTP for [phone] using the latest force-resending token.
  Future<void> resendOtp(String phone) async {
    final completer = Completer<void>();

    _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 120),
      forceResendingToken: _resendingToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _firebaseAuth.signInWithCredential(credential);
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      verificationFailed: (FirebaseAuthException error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      codeSent: (String verificationId, int? forceResendingToken) {
        _verificationId = verificationId;
        _resendingToken = forceResendingToken;
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );

    await completer.future;
  }

  /// Exposes a short-lived Firebase ID token for future backend integration.
  /// Returns null when no user is signed in. Tokens are never persisted.
  Future<String?> getIdToken() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return null;
    }
    return user.getIdToken();
  }

  Future<AuthUser> verifyOtp(String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw StateError('Signed in but no user was returned');
    }
    return _toAuthUser(user)!;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Stream<AuthUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(_toAuthUser);
  }

  AuthUser? getUser() {
    return _toAuthUser(_firebaseAuth.currentUser);
  }

  AuthUser? _toAuthUser(User? user) {
    if (user == null) {
      return null;
    }
    return AuthUser(
      uid: user.uid,
      phone: user.phoneNumber ?? '',
      displayName: user.displayName,
    );
  }
}
