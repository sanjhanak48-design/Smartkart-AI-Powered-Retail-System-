// Widget tests for the shared info banner.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/core/widgets/info_banner.dart';

void main() {
  testWidgets('renders the message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: InfoBanner(message: 'Mock payment only.')),
      ),
    );

    expect(find.text('Mock payment only.'), findsOneWidget);
  });
}
