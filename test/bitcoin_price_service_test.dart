import 'package:flutter_test/flutter_test.dart';
import 'package:bitSave/services/bitcoin_price_service.dart';
import 'package:bitSave/core/data/models/api_models.dart';

void main() {
  group('BitcoinPriceService Unit Tests', () {
    late BitcoinPriceService priceService;

    setUp(() {
      priceService = BitcoinPriceService();
      // Set test price: 1 BTC = 150,000,000 NGN
      priceService.btcPriceNgn.value = 150000000.0;
      priceService.btcPriceUsd.value = 95000.0;
    });

    tearDown(() {
      priceService.dispose();
    });

    test('Converts NGN to Satoshis correctly', () {
      // 150,000,000 NGN = 1 BTC = 100,000,000 sats
      // 150,000 NGN = 0.001 BTC = 100,000 sats
      // 1,500 NGN = 0.00001 BTC = 1,000 sats
      final sats = priceService.ngnToSats(150000.0);
      expect(sats, 100000);

      final smallSats = priceService.ngnToSats(1500.0);
      expect(smallSats, 1000);
    });

    test('Converts Satoshis to NGN correctly', () {
      final ngn = priceService.satsToNgn(100000);
      expect(ngn, 150000.0);

      final smallNgn = priceService.satsToNgn(1000);
      expect(smallNgn, 1500.0);
    });

    test('Converts BTC to Satoshis and vice versa', () {
      expect(priceService.btcToSats(1.0), 100000000);
      expect(priceService.btcToSats(0.5), 50000000);
      expect(priceService.satsToBtc(100000000), 1.0);
      expect(priceService.satsToBtc(50000000), 0.5);
    });
  });

  group('Enhanced Model Fields Tests', () {
    test('BitSaveSavingsGoal category and progress calculation', () {
      final goal = BitSaveSavingsGoal(
        id: 'goal-99',
        userId: 'u-1',
        name: 'Emergency Fund',
        targetAmountNgn: '100000.00',
        savedAmountNgn: '25000.00',
        category: 'Emergency',
        contributionFrequency: 'Weekly',
      );

      expect(goal.category, 'Emergency');
      expect(goal.contributionFrequency, 'Weekly');
      expect(goal.savedAmountDouble, 25000.0);
      expect(goal.targetAmountDouble, 100000.0);
      expect(goal.progressPercent, 0.25);
    });

    test('BitSaveTransaction paymentMethod and explorerUrl', () {
      final tx = BitSaveTransaction.fromJson({
        'id': 'tx-123',
        'user_id': 'u-1',
        'type': 'DEPOSIT',
        'status': 'COMPLETED',
        'fiat_amount': '50000.00',
        'fiat_currency': 'NGN',
        'btc_amount_sats': 33333,
        'provider': 'MavaPay',
        'provider_transaction_id': 'mav_tx_88',
        'payment_method': 'Lightning',
        'blockchain_tx_id': 'abcdef1234567890',
      });

      expect(tx.paymentMethod, 'Lightning');
      expect(tx.blockchainTxId, 'abcdef1234567890');
      expect(tx.explorerUrl, 'https://mempool.space/tx/abcdef1234567890');
    });
  });
}
