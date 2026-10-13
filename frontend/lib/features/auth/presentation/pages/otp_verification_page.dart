import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/auth_controller.dart';

class OtpVerificationPage extends ConsumerStatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  ConsumerState<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  final _otpController = TextEditingController();
  String? _validationError;

  ({String verificationId, String phone})? get _challenge {
    final authState = ref.read(authControllerProvider);
    if (authState is AuthOtpSent) {
      return (verificationId: authState.verificationId, phone: authState.phone);
    }
    final extra = GoRouterState.of(context).extra;
    if (extra is ({String verificationId, String phone})) {
      return extra;
    }
    return null;
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verify() {
    setState(() => _validationError = null);
    final challenge = _challenge;
    if (challenge == null) {
      return;
    }
    final smsCode = _otpController.text.trim();
    if (smsCode.length != 6) {
      setState(() => _validationError = 'Enter the 6-digit code.');
      return;
    }
    ref
        .read(authControllerProvider.notifier)
        .verifyOtp(challenge.verificationId, smsCode);
  }

  void _resend() {
    final challenge = _challenge;
    if (challenge == null) {
      return;
    }
    ref.read(authControllerProvider.notifier).resendOtp(challenge.phone);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final busy = authState is AuthSendingOtp || authState is AuthVerifyingOtp;
    final authError = authState is AuthError ? authState.message : null;
    final errorMessage = _validationError ?? authError;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.premiumDark,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sms_outlined,
                    size: 44,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Enter the code',
                style: AppTextStyles.heading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Enter the 6-digit code sent to your phone.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _otpController,
                enabled: !busy,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 12,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '------',
                ),
                onChanged: (_) {
                  if (_validationError != null) {
                    setState(() => _validationError = null);
                  }
                },
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Text(
                    errorMessage,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: busy ? null : _verify,
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Verify OTP'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: busy ? null : _resend,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                ),
                child: const Text('Resend OTP'),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: busy
                    ? null
                    : () {
                        context.go('/login');
                      },
                child: const Text('Wrong number? Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
