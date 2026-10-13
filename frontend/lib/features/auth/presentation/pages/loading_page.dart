import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/brand_logo_mark.dart';

/// Splash screen shown while the app determines the authentication state.
///
/// In normal operation the router's guard redirects away from this screen as
/// soon as auth resolves. As a safety net, an internal timer falls back to
/// `/login` if the screen is still showing after [_timeout] — so startup can
/// never leave the user trapped on an unresolved spinner.
class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  /// Duration after which the splash falls back to `/login` if still shown.
  static const Duration timeout = Duration(seconds: 10);

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(LoadingPage.timeout, _fallbackToLogin);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Escape hatch: if initialization has not resolved by the timeout, route
  /// to `/login`. The router guard then redirects authenticated users to home
  /// and unauthenticated users to the sign-in screen, so this is safe in all
  /// auth states.
  void _fallbackToLogin() {
    if (!mounted) {
      return;
    }
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.background),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandLogoMark(
                size: 96,
                iconSize: 48,
                background: AppColors.premiumDark,
                iconColor: Colors.white,
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('SmartKart', style: AppTextStyles.headingLarge),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'AI-Powered Retail Billing',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const CircularProgressIndicator(color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
