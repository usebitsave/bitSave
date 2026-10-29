import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bitSave/core/config/app_config.dart';
import 'package:bitSave/core/data/models/api_models.dart';
import 'package:bitSave/core/network/api_response.dart';

void main() {
  group('AppConfig Tests', () {
    test('Default environment is staging with correct Base URL', () {
      expect(AppConfig.environment, Environment.staging);
      expect(AppConfig.baseUrl, 'https://backend-gadt.onrender.com/api/v1');
    });

    test('Environment can be updated and respects custom base URL', () {
      AppConfig.setEnvironment(Environment.development);
      expect(AppConfig.baseUrl, 'http://10.0.2.2:8080/api/v1');

      AppConfig.setCustomBaseUrl('https://custom.api.bitsave.io/api/v1');
      expect(AppConfig.baseUrl, 'https://custom.api.bitsave.io/api/v1');

      // Reset
      AppConfig.setCustomBaseUrl(null);
      AppConfig.setEnvironment(Environment.staging);
      expect(AppConfig.baseUrl, 'https://backend-gadt.onrender.com/api/v1');
    });
  });

  group('BitSave API Models Parsing Tests', () {
    test('BitSaveAuthResponse deserialization', () {
      final json = {'token': 'jwt_mock_token_12345'};
      final auth = BitSaveAuthResponse.fromJson(json);
      expect(auth.token, 'jwt_mock_token_12345');
    });

    test('BitSaveUserProfile deserialization', () {
      final json = {
        'id': '6aa4067f-eb89-4fd4-9a7e-93e0d5c42e7a',
        'email': 'user@example.com',
        'created_at': '2026-10-21T10:28:11.463340Z',
        'updated_at': '2026-10-21T10:28:11.463340Z'
      };
      final user = BitSaveUserProfile.fromJson(json);
      expect(user.id, '6aa4067f-eb89-4fd4-9a7e-93e0d5c42e7a');
      expect(user.email, 'user@example.com');
      expect(user.createdAt, isNotNull);
    });

    test('BitSaveSavingsGoal deserialization', () {
      final json = {
        'id': 'goal-123',
        'user_id': 'user-456',
        'name': 'MacBook Pro',
        'target_amount_ngn': '1500000.00',
        'deadline': '2026-12-31T23:59:59Z',
        'created_at': '2026-10-21T10:00:00Z',
        'updated_at': '2026-10-21T10:00:00Z'
      };
      final goal = BitSaveSavingsGoal.fromJson(json);
      expect(goal.name, 'MacBook Pro');
      expect(goal.targetAmountDouble, 1500000.00);
      expect(goal.deadline, isNotNull);
    });

    test('BitSaveQuote deserialization', () {
      final json = {
        'id': 'quote-123',
        'user_id': 'user-456',
        'fiat_amount': '50000.0000',
        'fiat_currency': 'NGN',
        'btc_amount_sats': 49500,
        'exchange_rate': '100000000.00000000',
        'fee': '500.0000',
        'provider': 'mock_provider',
        'provider_quote_id': 'prov-123',
        'expires_at': '2026-10-21T10:45:00Z',
        'created_at': '2026-10-21T10:30:00Z'
      };
      final quote = BitSaveQuote.fromJson(json);
      expect(quote.btcAmountSats, 49500);
      expect(quote.fiatCurrency, 'NGN');
      expect(quote.provider, 'mock_provider');
    });

    test('BitSaveTransaction deserialization', () {
      final json = {
        'id': 'tx-123',
        'user_id': 'user-456',
        'goal_id': null,
        'quote_id': 'quote-123',
        'type': 'DEPOSIT',
        'status': 'PENDING',
        'fiat_amount': '50000.0000',
        'fiat_currency': 'NGN',
        'btc_amount_sats': 49500,
        'provider': 'mock_provider',
        'provider_transaction_id': 'tx-prov-123',
        'idempotency_key': 'key-123',
        'created_at': '2026-10-21T10:30:00Z',
        'updated_at': '2026-10-21T10:30:00Z'
      };
      final tx = BitSaveTransaction.fromJson(json);
      expect(tx.status, 'PENDING');
      expect(tx.type, 'DEPOSIT');
      expect(tx.idempotencyKey, 'key-123');
    });
  });

  group('ApiResponse Error Handling Tests', () {
    test('Parses error string correctly from backend error key', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/v1/auth/login'),
        statusCode: 401,
        data: {'error': 'Invalid credentials'},
      );
      final apiResponse = ApiResponse(response);
      expect(apiResponse.isSuccess, isFalse);
      expect(apiResponse.errorMessage, 'Invalid credentials');
    });

    test('Detects success on 200/201 response codes', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/v1/auth/register'),
        statusCode: 201,
        data: {'token': 'jwt_abc'},
      );
      final apiResponse = ApiResponse(response);
      expect(apiResponse.isSuccess, isTrue);
    });
  });
}
