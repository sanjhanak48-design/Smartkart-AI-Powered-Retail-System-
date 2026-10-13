import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/brand_logo_mark.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final phone = '+91${_phoneController.text.trim()}';
    ref.read(authControllerProvider.notifier).sendOtp(phone);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is AuthOtpSent) {
        context.push(
          '/otp',
          extra: (verificationId: next.verificationId, phone: next.phone),
        );
      }
    });

    final sending = authState is AuthSendingOtp;
    final errorMessage = authState is AuthError ? authState.message : null;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxxl),
              Center(
                child: BrandLogoMark(
                  size: 88,
                  iconSize: 44,
                  background: AppColors.premiumDark,
                  iconColor: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'SmartKart',
                style: AppTextStyles.headingLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Sign in to start shopping',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Phone Number', style: AppTextStyles.label),
                        const SizedBox(height: AppSpacing.xs),
                        TextFormField(
                          controller: _phoneController,
                          enabled: !sending,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          decoration: const InputDecoration(
                            prefixText: '+91 ',
                            counterText: '',
                            hintText: '10-digit mobile number',
                          ),
                          validator: (value) {
                            final digits = (value ?? '').trim();
                            if (digits.length != 10) {
                              return 'Enter a valid 10-digit number';
                            }
                            return null;
                          },
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .errorContainer,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                            ),
                            child: Text(
                              errorMessage,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton(
                          onPressed: sending ? null : _sendOtp,
                          child: sending
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Send OTP'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'We will send a one-time password to this number.',
                          style: AppTextStyles.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
