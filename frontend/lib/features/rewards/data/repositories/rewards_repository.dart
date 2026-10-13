import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/smart_coin_transaction.dart';

abstract class RewardsRepository {
  Future<int> getBalance();

  Future<List<SmartCoinTransaction>> getTransactions();

  Future<SmartCoinTransaction> addCoins({
    required int coins,
    required String description,
  });

  Future<SmartCoinTransaction> redeemCoins({
    required int coins,
    required String description,
  });
}

class MockRewardsRepository implements RewardsRepository {
  MockRewardsRepository() : _transactions = <SmartCoinTransaction>[];

  final List<SmartCoinTransaction> _transactions;
  int _balance = 0;
  int _sequence = 0;

  @override
  Future<int> getBalance() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _balance;
  }

  @override
  Future<List<SmartCoinTransaction>> getTransactions() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_transactions);
  }

  @override
  Future<SmartCoinTransaction> addCoins({
    required int coins,
    required String description,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _balance += coins;
    return _record(
      type: SmartCoinTransactionType.earned,
      coins: coins,
      description: description,
    );
  }

  @override
  Future<SmartCoinTransaction> redeemCoins({
    required int coins,
    required String description,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (coins > _balance) {
      throw StateError('Insufficient SmartCoins balance');
    }
    _balance -= coins;
    return _record(
      type: SmartCoinTransactionType.redeemed,
      coins: coins,
      description: description,
    );
  }

  SmartCoinTransaction _record({
    required SmartCoinTransactionType type,
    required int coins,
    required String description,
  }) {
    _sequence += 1;
    final transaction = SmartCoinTransaction(
      id: 'SC-${_sequence.toString().padLeft(4, '0')}',
      type: type,
      coins: coins,
      description: description,
      createdAt: DateTime.now(),
    );
    _transactions.insert(0, transaction);
    return transaction;
  }
}

final rewardsRepositoryProvider = Provider<RewardsRepository>(
  (ref) => MockRewardsRepository(),
);
