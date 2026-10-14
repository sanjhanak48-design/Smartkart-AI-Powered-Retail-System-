// Widget tests for the shared empty-state view.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/core/widgets/empty_state_view.dart';

void main() {
  testWidgets('renders title, message and a default icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyStateView(
            title: 'No orders yet',
            message: 'Place an order to see it here.',
          ),
        ),
      ),
    );

    expect(find.text('No orders yet'), findsOneWidget);
    expect(find.text('Place an order to see it here.'), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
  });

  testWidgets('uses the supplied icon and renders an action button', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyStateView(
            icon: Icons.search_off,
            title: 'No products',
            action: FilledButton(
              onPressed: () => pressed = true,
              child: const Text('Retry'),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.search_off), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(pressed, isTrue);
  });
}
