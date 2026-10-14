// Widget tests for the shared error view.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/core/widgets/error_view.dart';

void main() {
  testWidgets('renders the message with a Retry action', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorView(
            message: 'Something went wrong',
            onAction: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('supports a custom action label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ErrorView(
            message: 'Order not found',
            actionLabel: 'Back',
            onAction: null,
          ),
        ),
      ),
    );

    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('can hide the action button entirely', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ErrorView(message: 'Oops', showAction: false)),
      ),
    );

    expect(find.text('Oops'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });
}
