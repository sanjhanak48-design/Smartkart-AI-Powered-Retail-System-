import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:smartkart/features/auth/presentation/pages/loading_page.dart';

void main() {
  group('Loading page', () {
    testWidgets('shows the branding and a spinner', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoadingPage()));

      expect(find.text('SmartKart'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('falls back to login when initialization cannot resolve', (
      tester,
    ) async {
      // A minimal router where the splash is the initial location. No auth
      // state ever resolves, so the splash must time out and fall back.
      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => const LoadingPage(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) =>
                const Scaffold(body: Text('Sign in to start shopping')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      // Initially still on the splash.
      expect(find.text('SmartKart'), findsOneWidget);
      expect(find.text('Sign in to start shopping'), findsNothing);

      // Elapse the timeout so the escape hatch fires.
      await tester.pump(LoadingPage.timeout + const Duration(seconds: 1));

      expect(find.text('Sign in to start shopping'), findsOneWidget);
      expect(find.text('SmartKart'), findsNothing);
    });

    testWidgets('cancels the fallback when disposed before the timeout', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => const LoadingPage(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) =>
                const Scaffold(body: Text('Sign in to start shopping')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      // Navigate away before the timeout elapses.
      router.go('/login');
      await tester.pump();

      // Advancing past the timeout must not throw (timer was cancelled).
      await tester.pump(LoadingPage.timeout + const Duration(seconds: 1));
      expect(find.text('Sign in to start shopping'), findsOneWidget);
    });
  });
}
