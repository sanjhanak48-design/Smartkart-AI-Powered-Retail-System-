// Widget tests for the shared read-only cart item row.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/core/widgets/cart_item_row.dart';
import 'package:smartkart/features/cart/domain/models/cart.dart';

void main() {
  testWidgets('renders name, price x qty and line total', (tester) async {
    const item = CartItem(
      product: Product(id: 'milk', name: 'Milk', price: 40.0),
      quantity: 2,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CartItemRow(item: item)),
      ),
    );

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('₹40.00 × 2'), findsOneWidget);
    expect(find.text('₹80.00'), findsOneWidget);
  });
}
