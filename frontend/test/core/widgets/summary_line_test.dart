// Widget tests for the shared summary line.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/core/theme/app_colors.dart';
import 'package:smartkart/core/widgets/summary_line.dart';

void main() {
  testWidgets('renders label and value', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SummaryLine(label: 'Items', value: '3'),
        ),
      ),
    );

    expect(find.text('Items'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('emphasized line is styled with the primary color', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SummaryLine(label: 'Total', value: '₹120.00', emphasized: true),
        ),
      ),
    );

    final valueText = tester.widget<Text>(find.text('₹120.00'));
    expect(valueText.style?.color, AppColors.primary);
  });

  testWidgets('discount line is styled with the error color', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SummaryLine(
            label: 'Discount',
            value: '−₹10.00',
            isDiscount: true,
          ),
        ),
      ),
    );

    final valueText = tester.widget<Text>(find.text('−₹10.00'));
    expect(valueText.style?.color, AppColors.error);
  });
}
