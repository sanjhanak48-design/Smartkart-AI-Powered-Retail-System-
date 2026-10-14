import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_provider.dart';
import '../../domain/models/auth_user.dart';

sealed class AuthState {
  const AuthState();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthSendingOtp extends AuthState {
  const AuthSendingOtp();
}

class AuthOtpSent extends AuthState {
  const AuthOtpSent(this.verificationId, this.phone);

  final String verificationId;
  final String phone;
}

class AuthVerifyingOtp extends AuthState {
  const AuthVerifyingOtp();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final AuthUser user;
}

class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;
}

class AuthController extends Notifier<AuthState> {
  late final AuthRepository _authRepository;
  StreamSubscription<AuthUser?>? _authSubscription;
  bool _submitting = false;

  @override
  AuthState build() {
    _authRepository = ref.watch(authRepositoryProvider);

    final currentUser = _authRepository.getUser();
    if (currentUser != null) {
      state = AuthAuthenticated(currentUser);
    } else {
      state = const AuthUnauthenticated();
    }

    _authSubscription?.cancel();
    _authSubscription = _authRepository.authStateChanges().listen((
      AuthUser? user,
    ) {
      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = const AuthUnauthenticated();
      }
    });

    ref.onDispose(() {
      _authSubscription?.cancel();
    });

    return state;
  }

  Future<void> sendOtp(String phone) async {
    if (_submitting) {
      return;
    }
    _submitting = true;
    state = const AuthSendingOtp();
    try {
      await _authRepository.sendOtp(phone);
      final verificationId = _authRepository.verificationId;
      if (verificationId == null) {
        state = const AuthError('Unable to send the code. Please try again.');
        return;
      }
      state = AuthOtpSent(verificationId, phone);
    } on FirebaseAuthException catch (error) {
      state = AuthError(_friendlyMessage(error));
    } catch (_) {
      state = const AuthError('Something went wrong. Please try again.');
    } finally {
      _submitting = false;
    }
  }

  Future<void> resendOtp(String phone) async {
    if (_submitting) {
      return;
    }
    _submitting = true;
    state = const AuthSendingOtp();
    try {
      await _authRepository.resendOtp(phone);
      final verificationId = _authRepository.verificationId;
      if (verificationId == null) {
        state = const AuthError('Unable to send the code. Please try again.');
        return;
      }
      state = AuthOtpSent(verificationId, phone);
    } on FirebaseAuthException catch (error) {
      state = AuthError(_friendlyMessage(error));
    } catch (_) {
      state = const AuthError('Something went wrong. Please try again.');
    } finally {
      _submitting = false;
    }
  }

  Future<void> verifyOtp(String verificationId, String smsCode) async {
    if (_submitting) {
      return;
    }
    _submitting = true;
    state = const AuthVerifyingOtp();
    try {
      final user = await _authRepository.verifyOtp(verificationId, smsCode);
      state = AuthAuthenticated(user);
    } on FirebaseAuthException catch (error) {
      state = AuthError(_friendlyMessage(error));
    } catch (_) {
      state = const AuthError('Something went wrong. Please try again.');
    } finally {
      _submitting = false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
    } on FirebaseAuthException {
      state = const AuthError('Unable to sign out. Please try again.');
    } catch (_) {
      state = const AuthError('Unable to sign out. Please try again.');
    }
  }

  String _friendlyMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'The phone number is invalid. Please check and try again.';
      case 'invalid-verification-code':
        return 'The code is incorrect. Please try again.';
      case 'invalid-verification-id':
        return 'The code has expired. Please request a new one.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
