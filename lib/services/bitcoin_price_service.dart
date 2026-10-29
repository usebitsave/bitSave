import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class BitcoinPriceService {
  final Dio _dio = Dio();

  // Observable state
  final ValueNotifier<double> btcPriceNgn = ValueNotifier<double>(150000000.0);
  final ValueNotifier<double> btcPriceUsd = ValueNotifier<double>(95000.0);
  final ValueNotifier<double> change24h = ValueNotifier<double>(2.45);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<DateTime?> lastUpdated = ValueNotifier<DateTime?>(null);

  Timer? _timer;
  static const Duration _cacheDuration = Duration(minutes: 2);

  BitcoinPriceService() {
    fetchPrice();
    // Auto-refresh every 2 minutes
    _timer = Timer.periodic(_cacheDuration, (_) => fetchPrice());
  }

  void dispose() {
    _timer?.cancel();
  }

  /// Fetches live Bitcoin price with caching
  Future<void> fetchPrice({bool force = false}) async {
    if (!force &&
        lastUpdated.value != null &&
        DateTime.now().difference(lastUpdated.value!) < _cacheDuration) {
      return;
    }

    isLoading.value = true;
    try {
      // 1. Primary source: CoinGecko
      final response = await _dio.get(
        'https://api.coingecko.com/api/v3/simple/price',
        queryParameters: {
          'ids': 'bitcoin',
          'vs_currencies': 'ngn,usd',
          'include_24hr_change': 'true',
        },
        options: Options(
          receiveTimeout: 10000,
          sendTimeout: 10000,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final btc = response.data['bitcoin'];
        if (btc != null) {
          if (btc['ngn'] != null) {
            btcPriceNgn.value = (btc['ngn'] as num).toDouble();
          }
          if (btc['usd'] != null) {
            btcPriceUsd.value = (btc['usd'] as num).toDouble();
          }
          if (btc['ngn_24h_change'] != null) {
            change24h.value = (btc['ngn_24h_change'] as num).toDouble();
          } else if (btc['usd_24h_change'] != null) {
            change24h.value = (btc['usd_24h_change'] as num).toDouble();
          }
          lastUpdated.value = DateTime.now();
          return;
        }
      }
    } catch (e) {
      debugPrint('CoinGecko price fetch failed: $e. Trying fallback...');
    }

    // 2. Fallback: Binance Public API for BTC/USDT + fixed/estimated NGN rate
    try {
      final binanceResp = await _dio.get(
        'https://api.binance.com/api/v3/ticker/24hr?symbol=BTCUSDT',
        options: Options(
          receiveTimeout: 5000,
          sendTimeout: 5000,
        ),
      );
      if (binanceResp.statusCode == 200 && binanceResp.data != null) {
        final lastPrice = double.tryParse(binanceResp.data['lastPrice']?.toString() ?? '');
        final priceChangePercent = double.tryParse(binanceResp.data['priceChangePercent']?.toString() ?? '');
        if (lastPrice != null) {
          btcPriceUsd.value = lastPrice;
          // Approximate NGN at 1550 NGN/USD
          btcPriceNgn.value = lastPrice * 1550.0;
        }
        if (priceChangePercent != null) {
          change24h.value = priceChangePercent;
        }
        lastUpdated.value = DateTime.now();
      }
    } catch (e) {
      debugPrint('Binance fallback fetch failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Conversion Helpers ─────────────────────────────────────────────────────

  /// Convert NGN fiat to satoshis
  int ngnToSats(double ngnAmount) {
    if (btcPriceNgn.value <= 0 || ngnAmount <= 0) return 0;
    final btc = ngnAmount / btcPriceNgn.value;
    return (btc * 100000000).round();
  }

  /// Convert satoshis to NGN fiat
  double satsToNgn(int sats) {
    if (sats <= 0) return 0.0;
    final btc = sats / 100000000.0;
    return double.parse((btc * btcPriceNgn.value).toStringAsFixed(2));
  }

  /// Convert BTC to satoshis
  int btcToSats(double btc) {
    return (btc * 100000000).round();
  }

  /// Convert satoshis to BTC
  double satsToBtc(int sats) {
    return sats / 100000000.0;
  }
}
