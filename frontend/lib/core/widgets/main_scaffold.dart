import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Bottom navigation shell widget.
///
/// Renders a NavigationBar with 5 destinations.
/// Used by the ShellRoute to wrap tab pages.
class MainScaffold extends StatelessWidget {
  const MainScaffold({
    super.key,
    required this.currentRoute,
    required this.child,
  });

  final String currentRoute;
  final Widget child;

  int get _selectedIndex {
    return switch (currentRoute) {
      '/' => 0,
      '/catalog' => 1,
      '/live-cart' => 2,
      '/smartcoins' => 3,
      '/profile' => 4,
      _ => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              final path = switch (index) {
                0 => '/',
                1 => '/catalog',
                2 => '/live-cart',
                3 => '/smartcoins',
                4 => '/profile',
                _ => '/',
              };
              context.go(path);
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            height: AppSpacing.navBarHeight,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront),
                label: 'Shop',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_cart_outlined),
                selectedIcon: Icon(Icons.shopping_cart),
                label: 'Cart',
              ),
              NavigationDestination(
                icon: Icon(Icons.star_outline),
                selectedIcon: Icon(Icons.star),
                label: 'Coins',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
