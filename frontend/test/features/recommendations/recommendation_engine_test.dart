// Focused unit tests for the deterministic RecommendationEngine.
import 'package:flutter_test/flutter_test.dart';

import 'package:smartkart/features/cart/domain/models/cart.dart';
import 'package:smartkart/features/cart/domain/models/order.dart';
import 'package:smartkart/features/recommendations/domain/models/recommended_item.dart';
import 'package:smartkart/features/recommendations/domain/recommendation_engine.dart';

const milk = Product(id: 'milk', name: 'Milk', price: 30, category: 'Dairy');
const bread = Product(
  id: 'bread',
  name: 'Bread',
  price: 40,
  category: 'Bakery',
);
const rice = Product(id: 'rice', name: 'Rice', price: 99, category: 'Staples');
const biscuits = Product(
  id: 'biscuits',
  name: 'Biscuits',
  price: 25,
  category: 'Snacks',
);
const eggs = Product(id: 'eggs', name: 'Eggs', price: 60, category: 'Dairy');
const cheese = Product(
  id: 'cheese',
  name: 'Cheese',
  price: 120,
  category: 'Dairy',
);

const catalog = [milk, bread, rice, biscuits, eggs, cheese];

const juice = Product(
  id: 'juice',
  name: 'Orange Juice',
  price: 70,
  category: 'Beverages',
);

Order order(String id, List<CartItem> items) {
  return Order(
    orderId: id,
    createdAt: DateTime(2026, 1, 1),
    items: items,
    total: items.fold(0.0, (sum, item) => sum + item.lineTotal),
  );
}

void main() {
  group('RecommendationEngine', () {
    test('excludes products already in the active cart', () {
      final engine = RecommendationEngine();
      final history = [
        order('SM-0001', const [
          CartItem(product: milk, quantity: 1),
          CartItem(product: bread, quantity: 1),
        ]),
      ];

      final result = engine.recommend(
        catalog: catalog,
        history: history,
        cartItems: const [CartItem(product: milk, quantity: 1)],
      );

      expect(result.map((item) => item.product.id), isNot(contains('milk')));
      expect(result.map((item) => item.product.id), contains('bread'));
    });

    test(
      'purchase-history category affinity ranks the stronger category first',
      () {
        final engine = RecommendationEngine();
        final history = [
          order('SM-0001', const [CartItem(product: milk, quantity: 2)]),
          order('SM-0002', const [CartItem(product: milk, quantity: 2)]),
          order('SM-0003', const [
            CartItem(product: milk, quantity: 1),
            CartItem(product: bread, quantity: 1),
          ]),
        ];

        final result = engine.recommend(
          catalog: catalog,
          history: history,
          cartItems: const [],
        );

        expect(result[0].product.id, 'milk');
        expect(result[0].score, 10);
        expect(result[0].source, RecommendationSource.purchaseHistory);
        expect(result[0].reason, 'Because you often buy Dairy products');
        expect(result[1].product.id, 'eggs');
        expect(result[2].product.id, 'cheese');
        expect(result[3].product.id, 'bread');
      },
    );

    test('cart affinity boosts products in the same category as the cart', () {
      final engine = RecommendationEngine();

      final result = engine.recommend(
        catalog: catalog,
        history: const [],
        cartItems: const [CartItem(product: milk, quantity: 1)],
      );

      expect(result.first.product.id, 'eggs');
      expect(result.first.score, 3);
      expect(result.first.source, RecommendationSource.cartAffinity);
      expect(result.first.reason, 'Pairs well with items in your cart');
      expect(result.map((item) => item.product.id), isNot(contains('milk')));
    });

    test('co-purchase contributes scoring above a comparable candidate', () {
      final engine = RecommendationEngine();
      final history = [
        order('SM-0001', const [
          CartItem(product: milk, quantity: 1),
          CartItem(product: cheese, quantity: 1),
        ]),
        order('SM-0002', const [
          CartItem(product: milk, quantity: 1),
          CartItem(product: cheese, quantity: 1),
        ]),
      ];

      final result = engine.recommend(
        catalog: catalog,
        history: history,
        cartItems: const [CartItem(product: milk, quantity: 1)],
      );

      expect(result[0].product.id, 'cheese');
      expect(result[0].score, 13);
      expect(result[1].product.id, 'eggs');
      expect(result[1].score, 11);
    });

    test('source precedence handles ties: cart > co-purchase > history', () {
      final engine = RecommendationEngine();

      expect(
        engine.dominantSource(h: 0, c: 1, t: 1),
        RecommendationSource.cartAffinity,
      );
      expect(
        engine.dominantSource(h: 2, c: 0, t: 4),
        RecommendationSource.coPurchase,
      );
      expect(
        engine.dominantSource(h: 3, c: 2, t: 0),
        RecommendationSource.cartAffinity,
      );
      expect(
        engine.dominantSource(h: 1, c: 0, t: 0),
        RecommendationSource.purchaseHistory,
      );
      expect(
        engine.dominantSource(h: 0, c: 0, t: 1),
        RecommendationSource.coPurchase,
      );
      expect(
        engine.dominantSource(h: 0, c: 0, t: 0),
        RecommendationSource.fallback,
      );
    });

    test('reasonFor produces the expected wording for every source', () {
      final engine = RecommendationEngine();

      expect(
        engine.reasonFor(RecommendationSource.cartAffinity, category: 'Bakery'),
        'Pairs well with items in your cart',
      );
      expect(
        engine.reasonFor(
          RecommendationSource.coPurchase,
          category: 'Bakery',
          companionName: 'Milk',
        ),
        'Often bought with Milk',
      );
      expect(
        engine.reasonFor(
          RecommendationSource.purchaseHistory,
          category: 'Dairy',
        ),
        'Because you often buy Dairy products',
      );
      expect(
        engine.reasonFor(RecommendationSource.purchaseHistory, category: ''),
        'Because you often buy similar products',
      );
      expect(
        engine.reasonFor(RecommendationSource.fallback, category: 'Dairy'),
        'Recommended for you',
      );
    });

    test('equal scores tie-break by catalog position, then name', () {
      final engine = RecommendationEngine();
      final history = [
        order('SM-0001', const [
          CartItem(product: milk, quantity: 1),
          CartItem(product: eggs, quantity: 1),
        ]),
      ];

      final result = engine.recommend(
        catalog: catalog,
        history: history,
        cartItems: const [],
      );

      expect(result[0].product.id, 'milk');
      expect(result[1].product.id, 'eggs');
      expect(result[0].score, result[1].score);
    });

    test('cold start returns one product per category in catalog order', () {
      const coldCatalog = [milk, bread, rice, biscuits];

      final result = RecommendationEngine().recommend(
        catalog: coldCatalog,
        history: const [],
        cartItems: const [],
      );

      expect(result.map((item) => item.product.name), [
        'Milk',
        'Bread',
        'Rice',
        'Biscuits',
      ]);
      expect(
        result.every((item) => item.reason == 'Recommended for you'),
        isTrue,
      );
      expect(
        result.every((item) => item.source == RecommendationSource.fallback),
        isTrue,
      );
      expect(result.every((item) => item.score == 0), isTrue);
    });

    test('cold start with the real catalog is category-balanced', () {
      const fullCatalog = [
        milk,
        bread,
        rice,
        biscuits,
        eggs,
        cheese,
        Product(id: 'atta', name: 'Wheat Atta', price: 55, category: 'Staples'),
        Product(
          id: 'oil',
          name: 'Cooking Oil',
          price: 110,
          category: 'Staples',
        ),
        Product(
          id: 'chips',
          name: 'Potato Chips',
          price: 30,
          category: 'Snacks',
        ),
        Product(
          id: 'chocolate',
          name: 'Chocolate',
          price: 45,
          category: 'Snacks',
        ),
        juice,
        Product(id: 'tea', name: 'Tea', price: 50, category: 'Beverages'),
        Product(id: 'soap', name: 'Soap', price: 35, category: 'Personal Care'),
        Product(
          id: 'shampoo',
          name: 'Shampoo',
          price: 85,
          category: 'Personal Care',
        ),
      ];

      final result = RecommendationEngine().recommend(
        catalog: fullCatalog,
        history: const [],
        cartItems: const [],
      );

      expect(result.map((item) => item.product.name), [
        'Milk',
        'Bread',
        'Rice',
        'Biscuits',
        'Orange Juice',
      ]);
    });

    test('empty category uses the generic purchase-history reason', () {
      const plainMilk = Product(id: 'milk', name: 'Milk', price: 30);
      const plainBread = Product(id: 'bread', name: 'Bread', price: 40);
      final engine = RecommendationEngine();

      final result = engine.recommend(
        catalog: const [plainMilk, plainBread],
        history: [
          order('SM-0001', const [CartItem(product: plainMilk, quantity: 2)]),
        ],
        cartItems: const [],
      );

      final breadResult = result.firstWhere(
        (item) => item.product.id == 'bread',
      );
      expect(breadResult.source, RecommendationSource.purchaseHistory);
      expect(breadResult.reason, 'Because you often buy similar products');
      expect(breadResult.score, 4);
    });

    test('same inputs always produce the same ordering', () {
      final engine = RecommendationEngine();
      final history = [
        order('SM-0001', const [
          CartItem(product: milk, quantity: 3),
          CartItem(product: bread, quantity: 1),
        ]),
      ];

      final first = engine.recommend(
        catalog: catalog,
        history: history,
        cartItems: const [CartItem(product: milk, quantity: 1)],
      );
      final second = engine.recommend(
        catalog: catalog,
        history: history,
        cartItems: const [CartItem(product: milk, quantity: 1)],
      );

      expect(
        first.map((item) => item.product.id),
        second.map((item) => item.product.id),
      );
      expect(first.map((item) => item.score), second.map((item) => item.score));
    });

    test('topN is respected', () {
      final engine = RecommendationEngine();
      final history = [
        order('SM-0001', const [
          CartItem(product: milk, quantity: 5),
          CartItem(product: bread, quantity: 3),
          CartItem(product: rice, quantity: 1),
          CartItem(product: biscuits, quantity: 1),
        ]),
      ];

      final result = engine.recommend(
        catalog: catalog,
        history: history,
        cartItems: const [],
        topN: 2,
      );

      expect(result, hasLength(2));
      expect(result.first.product.id, 'milk');
      expect(result[1].product.id, 'eggs');
    });
  });
}
