import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/loading_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/cart/presentation/pages/checkout_page.dart';
import '../../features/catalog/presentation/pages/catalog_page.dart';
import '../../features/cart/presentation/pages/link_cart_page.dart';
import '../../features/cart/presentation/pages/live_cart_page.dart';
import '../../features/cart/presentation/pages/order_details_page.dart';
import '../../features/cart/presentation/pages/purchase_history_page.dart';
import '../../features/cart/presentation/pages/qr_scanner_page.dart';
import '../../features/cart/presentation/pages/receipt_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/payment/presentation/pages/payment_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/recommendations/presentation/pages/smart_picks_page.dart';
import '../../features/rewards/presentation/pages/smart_coins_page.dart';
import '../pages/not_found_page.dart';
import '../widgets/main_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen<AuthState>(authControllerProvider, (_, _) {
    refresh.value++;
  });

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    errorBuilder: (context, state) => NotFoundPage(error: state.error),
    redirect: (context, state) {
      final location = state.matchedLocation;
      final authState = ref.read(authControllerProvider);

      return switch (authState) {
        AuthAuthenticated() =>
          (location == '/' ||
                  location == '/profile' ||
                  location == '/catalog' ||
                  location == '/recommendations' ||
                  location == '/smartcoins' ||
                  location == '/link-cart' ||
                  location == '/live-cart' ||
                  location == '/scan-cart' ||
                  location == '/checkout' ||
                  location == '/payment' ||
                  location == '/receipt' ||
                  location.startsWith('/history'))
              ? null
              : '/',
        AuthUnauthenticated() => location == '/login' ? null : '/login',
        AuthSendingOtp() ||
        AuthOtpSent() ||
        AuthVerifyingOtp() ||
        AuthError() => null,
      };
    },
    routes: [
      // Non-tab routes (pushed on top — no bottom nav)
      GoRoute(
        path: '/splash',
        builder: (context, state) => const LoadingPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/otp',
        builder: (context, state) => const OtpVerificationPage(),
      ),
      GoRoute(
        path: '/link-cart',
        builder: (context, state) => const LinkCartPage(),
      ),
      GoRoute(
        path: '/scan-cart',
        builder: (context, state) => const QrScannerPage(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutPage(),
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) => const PaymentPage(),
      ),
      GoRoute(
        path: '/receipt',
        builder: (context, state) => const ReceiptPage(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const PurchaseHistoryPage(),
      ),
      GoRoute(
        path: '/history/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'];
          if (orderId == null || orderId.isEmpty) {
            return const NotFoundPage();
          }
          return OrderDetailsPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/recommendations',
        builder: (context, state) => const SmartPicksPage(),
      ),

      // Tab routes (inside shell — bottom nav visible)
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(
            currentRoute: state.matchedLocation,
            child: child,
          );
        },
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomePage()),
          GoRoute(
            path: '/catalog',
            builder: (context, state) => const CatalogPage(),
          ),
          GoRoute(
            path: '/live-cart',
            builder: (context, state) => const LiveCartPage(),
          ),
          GoRoute(
            path: '/smartcoins',
            builder: (context, state) => const SmartCoinsPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],
  );
});
