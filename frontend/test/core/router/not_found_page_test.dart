// Widget tests for the resilient routing behaviours introduced for unknown
// or invalid routes and router errors.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:smartkart/core/pages/not_found_page.dart';

void main() {
  group('NotFoundPage', () {
    testWidgets('renders a friendly message and a home action', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: NotFoundPage()));

      expect(find.text('Page not found'), findsOneWidget);
      expect(find.text('Go to Home'), findsOneWidget);
    });

    testWidgets('is shown for an unmatched route via errorBuilder', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/',
        errorBuilder: (context, state) => const NotFoundPage(),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const Scaffold()),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      // Navigate to a route that does not exist; the error builder renders
      // the friendly fallback instead of throwing.
      router.go('/does-not-exist');
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundPage), findsOneWidget);
      expect(find.text('Page not found'), findsOneWidget);
    });
  });
}
