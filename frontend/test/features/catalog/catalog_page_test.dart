// Widget tests for the Product Catalog page.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/app.dart';
import 'package:smartkart/features/auth/data/repositories/auth_repository.dart';
import 'package:smartkart/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:smartkart/features/auth/domain/models/auth_user.dart';
import 'package:smartkart/features/cart/domain/models/cart.dart';
import 'package:smartkart/features/cart/presentation/controllers/cart_controller.dart';
import 'package:smartkart/features/cart/presentation/pages/link_cart_page.dart';
import 'package:smartkart/features/catalog/data/repositories/catalog_repository.dart';

const _user = AuthUser(uid: 'uid-123', phone: '+919876543210');

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.currentUser});

  AuthUser? currentUser;
  String? verificationIdValue = 'VID-1';
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  @override
  String? get verificationId => verificationIdValue;

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  @override
  AuthUser? getUser() => currentUser;

  @override
  Future<String?> getIdToken() async => null;

  @override
  Future<void> sendOtp(String phone) async {}

  @override
  Future<void> resendOtp(String phone) async {
    verificationIdValue = 'RESEND-2';
  }

  @override
  Future<AuthUser> verifyOtp(String verificationId, String smsCode) async {
    return _user;
  }

  @override
  Future<void> signOut() async {
    currentUser = null;
    _controller.add(null);
  }
}

class _FakeCatalogRepository implements CatalogRepository {
  _FakeCatalogRepository(this.products);

  final List<Product> products;
  bool fail = false;
  Completer<void>? gate;
  int fetchCalls = 0;

  @override
  Future<List<Product>> fetchCatalog() async {
    fetchCalls++;
    final g = gate;
    if (g != null) {
      await g.future;
    }
    if (fail) {
      throw StateError('unavailable');
    }
    return List.unmodifiable(products);
  }

  @override
  Future<List<String>> fetchCategories() async {
    final categories =
        products
            .map((product) => product.category)
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return List.unmodifiable(categories);
  }
}

const _catalog = [
  Product(
    id: 'milk',
    name: 'Milk',
    price: 30,
    category: 'Dairy',
    emojiIcon: '🥛',
  ),
  Product(
    id: 'bread',
    name: 'Bread',
    price: 40,
    category: 'Bakery',
    emojiIcon: '🍞',
  ),
  Product(
    id: 'tea',
    name: 'Tea',
    price: 50,
    category: 'Beverages',
    emojiIcon: '🍵',
  ),
  Product(
    id: 'chocolate',
    name: 'Chocolate',
    price: 45,
    category: 'Snacks',
    emojiIcon: '🍫',
  ),
  Product(
    id: 'chips',
    name: 'Potato Chips',
    price: 30,
    category: 'Snacks',
    emojiIcon: '🍟',
  ),
];

void main() {
  late _FakeCatalogRepository repo;

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _FakeAuthRepository(currentUser: _user),
        ),
        catalogRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SmartKartApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> openCatalog(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Browse Products'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Browse Products'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    repo = _FakeCatalogRepository(_catalog);
  });

  testWidgets('renders the search field, category chips and product cards', (
    tester,
  ) async {
    await pumpApp(tester);
    await openCatalog(tester);

    expect(find.widgetWithText(AppBar, 'Shop Products'), findsOneWidget);
    expect(find.text('Search products'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Tea'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Dairy'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Snacks'), findsOneWidget);
  });

  testWidgets('searching by name filters the product list', (tester) async {
    await pumpApp(tester);
    await openCatalog(tester);

    await tester.enterText(find.byType(TextField), 'mil');
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Tea'), findsNothing);
  });

  testWidgets('category chips filter and the All chip restores the list', (
    tester,
  ) async {
    await pumpApp(tester);
    await openCatalog(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Snacks'));
    await tester.pumpAndSettle();

    expect(find.text('Chocolate'), findsOneWidget);
    expect(find.text('Milk'), findsNothing);
    expect(find.text('Tea'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('Tea'), findsOneWidget);
  });

  testWidgets('combined search and category filters both apply', (
    tester,
  ) async {
    await pumpApp(tester);
    await openCatalog(tester);

    await tester.enterText(find.byType(TextField), 'cho');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Snacks'));
    await tester.pumpAndSettle();

    expect(find.text('Chocolate'), findsOneWidget);
    expect(find.text('Potato Chips'), findsNothing);
    expect(find.text('Milk'), findsNothing);
  });

  testWidgets('adding a product uses the existing cart controller', (
    tester,
  ) async {
    final container = await pumpApp(tester);

    final cartNotifier = container.read(cartControllerProvider.notifier);
    cartNotifier.linkCart('CART-1');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    await openCatalog(tester);

    final milkCard = find.ancestor(
      of: find.text('Milk'),
      matching: find.byType(Card),
    );
    await tester.tap(
      find.descendant(
        of: milkCard,
        matching: find.widgetWithText(FilledButton, '+ Add'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Milk added to your cart'), findsOneWidget);
    final cartState = container.read(cartControllerProvider);
    expect(cartState, isA<CartLoaded>());
    final item = (cartState as CartLoaded).cart.items.single;
    expect(item.product.id, 'milk');
    expect(item.quantity, 1);
  });

  testWidgets('shows a clear link-cart banner when no cart is linked', (
    tester,
  ) async {
    await pumpApp(tester);
    await openCatalog(tester);

    expect(
      find.text('Link a cart to add products from the catalog.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Link Cart'));
    await tester.pumpAndSettle();

    expect(find.byType(LinkCartPage), findsOneWidget);
  });

  testWidgets('shows an error state with working retry', (tester) async {
    repo.fail = true;
    await pumpApp(tester);
    await openCatalog(tester);

    expect(
      find.text('Unable to load products. Please try again.'),
      findsOneWidget,
    );

    repo.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
  });

  testWidgets('shows an empty-results state with Clear Filters', (
    tester,
  ) async {
    await pumpApp(tester);
    await openCatalog(tester);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('No products match'), findsOneWidget);

    await tester.tap(find.text('Clear Filters'));
    await tester.pumpAndSettle();

    expect(find.text('Milk'), findsOneWidget);
  });
}
