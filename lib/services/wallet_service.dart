import 'package:flutter/foundation.dart';
import '../app/app.locator.dart';
import '../core/data/models/api_models.dart';
import '../core/data/repositories/repository.dart';

class WalletService {
  final _repository = locator<Repository>();

  BitSaveWallet? _wallet;
  BitSaveWallet? get wallet => _wallet;

  List<BitSaveTransaction> _transactions = [];
  List<BitSaveTransaction> get transactions => _transactions;

  // ── Fetch wallet (mocked server-side — just reads what's there) ────────────
  Future<BitSaveWallet?> fetchWallet() async {
    try {
      final resp = await _repository.getWallets();
      if (resp.isSuccess && resp.data != null) {
        final raw = resp.data;
        // Server may return a list or a single object
        if (raw is List && raw.isNotEmpty) {
          _wallet = BitSaveWallet.fromJson(raw.first as Map<String, dynamic>);
        } else if (raw is Map<String, dynamic>) {
          // Could be { wallets: [...] } or the wallet object directly
          if (raw['wallets'] is List && (raw['wallets'] as List).isNotEmpty) {
            _wallet = BitSaveWallet.fromJson((raw['wallets'] as List).first);
          } else if (raw['id'] != null) {
            _wallet = BitSaveWallet.fromJson(raw);
          }
        }
      }
    } catch (e) {
      debugPrint('WalletService.fetchWallet error: $e');
    }
    return _wallet;
  }

  // ── Fetch transactions ─────────────────────────────────────────────────────
  Future<List<BitSaveTransaction>> fetchTransactions() async {
    try {
      final resp = await _repository.getTransactions();
      if (resp.isSuccess && resp.data != null) {
        final raw = resp.data;
        List<dynamic> list = [];
        if (raw is List) {
          list = raw;
        } else if (raw is Map && raw['transactions'] is List) {
          list = raw['transactions'];
        } else if (raw is Map && raw['data'] is List) {
          list = raw['data'];
        }
        _transactions = list
            .map((e) => BitSaveTransaction.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => (b.createdAt ?? DateTime(0))
              .compareTo(a.createdAt ?? DateTime(0)));
      }
    } catch (e) {
      debugPrint('WalletService.fetchTransactions error: $e');
    }
    return _transactions;
  }

  // ── Get a conversion quote ─────────────────────────────────────────────────
  /// [amountNgn] — the NGN amount as a decimal string e.g. "50000.00"
  /// [goalId]    — optional: link this deposit to a savings goal
  Future<BitSaveQuote?> getQuote({
    required double amountNgn,
    String? quoteId,
  }) async {
    try {
      final body = <String, dynamic>{
        'amount_ngn': amountNgn.toStringAsFixed(2),
        if (quoteId != null) 'quote_id': quoteId,
      };
      final resp = await _repository.createQuote(body);
      if (resp.isSuccess && resp.data != null) {
        final data = resp.data;
        if (data is Map<String, dynamic>) {
          return BitSaveQuote.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('WalletService.getQuote error: $e');
    }
    return null;
  }

  // ── Initiate a deposit (mocked) ────────────────────────────────────────────
  /// Call after the user confirms the quote. Returns the pending Transaction.
  Future<BitSaveTransaction?> initiateDeposit({
    required double amountNgn,
    String? quoteId,
    String? goalId,
  }) async {
    try {
      final body = <String, dynamic>{
        'amount_ngn': amountNgn.toStringAsFixed(2),
        if (quoteId != null) 'quote_id': quoteId,
        if (goalId != null) 'goal_id': goalId,
      };
      final idempotencyKey =
          'bitsave_${DateTime.now().millisecondsSinceEpoch}_${amountNgn.toStringAsFixed(0)}';
      final resp = await _repository.initiateDeposit(
        body,
        idempotencyKey: idempotencyKey,
      );
      if (resp.isSuccess && resp.data != null) {
        final data = resp.data as Map<String, dynamic>?;
        if (data != null) {
          final tx = BitSaveTransaction.fromJson(data);
          _transactions.insert(0, tx);
          return tx;
        }
      }
    } catch (e) {
      debugPrint('WalletService.initiateDeposit error: $e');
    }
    return null;
  }

  void clear() {
    _wallet = null;
    _transactions = [];
  }
}