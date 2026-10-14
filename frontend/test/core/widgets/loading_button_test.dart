// Widget tests for the shared full-width loading button.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/core/widgets/loading_button.dart';

void main() {
  testWidgets('renders its child when not loading', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoadingButton(
            isLoading: false,
            onPressed: () {},
            child: const Text('Pay ₹50.00'),
          ),
        ),
      ),
    );

    expect(find.text('Pay ₹50.00'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows a spinner and disables taps while loading', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoadingButton(
            isLoading: true,
            onPressed: () => pressed = true,
            child: const Text('Pay ₹50.00'),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    expect(pressed, isFalse);
  });
}
