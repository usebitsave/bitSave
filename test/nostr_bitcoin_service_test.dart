import 'package:flutter_test/flutter_test.dart';
import 'package:bitSave/app/app.locator.dart';
import 'package:bitSave/services/nostr_bitcoin_service.dart';
import 'package:bitSave/services/bitcoin_price_service.dart';
import 'package:bitSave/services/wallet_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NostrBitcoinService Unit Tests', () {
    late NostrBitcoinService nostrService;

    setUp(() async {
      await setupLocator();
      nostrService = locator<NostrBitcoinService>();
      locator<BitcoinPriceService>().btcPriceNgn.value = 150000000.0;
    });

    tearDown(() {
      locator.reset();
    });

    test('Detects On-Chain Bitcoin addresses correctly', () {
      // Native SegWit (Bech32)
      expect(
        nostrService.detectAddressType('bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4'),
        BitcoinAddressType.onChainBtc,
      );

      // Legacy
      expect(
        nostrService.detectAddressType('1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'),
        BitcoinAddressType.onChainBtc,
      );

      // SegWit P2SH
      expect(
        nostrService.detectAddressType('3J98t1WpEZ73CNmQviecrnyiWrnqRhWNLy'),
        BitcoinAddressType.onChainBtc,
      );
    });

    test('Detects Lightning addresses and invoices correctly', () {
      expect(
        nostrService.detectAddressType('satoshi@getalby.com'),
        BitcoinAddressType.lightningAddress,
      );

      expect(
        nostrService.detectAddressType('lnbc2500u1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpu5qcqzpux8m4x'),
        BitcoinAddressType.lightningInvoice,
      );
    });

    test('Detects Nostr npub addresses correctly', () {
      expect(
        nostrService.detectAddressType('npub180cvv07tjdrrgpa0j7j7tmn09ddjhg979vgjhfhsqhdw9dn758qs22qm49'),
        BitcoinAddressType.nostrNpub,
      );
    });

    test('Returns unknown for invalid addresses', () {
      expect(nostrService.detectAddressType('invalid_wallet_xyz'), BitcoinAddressType.unknown);
      expect(nostrService.detectAddressType(''), BitcoinAddressType.unknown);
    });

    test('Decodes npub to hex public key correctly', () {
      const npub = 'npub180cvv07tjdrrgpa0j7j7tmn09ddjhg979vgjhfhsqhdw9dn758qs22qm49';
      final hex = nostrService.decodeNpubToHex(npub);
      expect(hex.length, 64);
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hex), isTrue);
    });

    test('Executes Bitcoin transfer and appends to transaction ledger', () async {
      final initialTxCount = locator<WalletService>().transactions.length;

      final result = await nostrService.sendBitcoin(
        destinationAddress: 'bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4',
        satsAmount: 10000,
        memo: 'Payment for services',
      );

      expect(result.isSuccess, isTrue);
      expect(result.satsSent, 10000);
      expect(result.txId, isNotNull);
      expect(result.explorerUrl, contains('https://mempool.space/tx/'));
      expect(locator<WalletService>().transactions.length, initialTxCount + 1);

      final recordedTx = locator<WalletService>().transactions.first;
      expect(recordedTx.btcAmountSats, 10000);
      expect(recordedTx.type, 'WITHDRAWAL');
      expect(recordedTx.status, 'COMPLETED');
    });
  });
}
