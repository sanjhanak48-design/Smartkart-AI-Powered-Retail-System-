// Widget tests for the shared loading indicator.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/core/widgets/loading_indicator.dart';

void main() {
  testWidgets('renders a centered progress indicator', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LoadingIndicator())),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
