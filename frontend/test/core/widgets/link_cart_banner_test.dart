// Widget tests for the shared link-cart banner.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/core/widgets/link_cart_banner.dart';

void main() {
  testWidgets('renders the message and a Link Cart button', (tester) async {
    var linked = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LinkCartBanner(
            message: 'Link a cart to add products.',
            onLinkCart: () => linked = true,
          ),
        ),
      ),
    );

    expect(find.text('Link a cart to add products.'), findsOneWidget);
    expect(find.text('Link Cart'), findsOneWidget);

    await tester.tap(find.text('Link Cart'));
    expect(linked, isTrue);
  });
}
