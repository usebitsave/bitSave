import 'package:dio/dio.dart';

class PaystackService {
  static const String _baseUrl = 'https://api.paystack.co';

  final Dio _dio;

  PaystackService() : _dio = Dio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
    };
  }

  /// Fetches the Paystack secret key (configure via backend or env)
  Future<String?> _getSecretKey() async {
    // TODO: Fetch secret key from your secure backend or environment
    const envKey = String.fromEnvironment('PAYSTACK_SECRET_KEY');
    if (envKey.isNotEmpty) return envKey;
    return 'sk_test_placeholder';
  }

  /// Initializes a transaction and returns the authorization URL and reference
  Future<Map<String, dynamic>?> initializeTransaction({
    required String email,
    required double amount,
  }) async {
    try {
      final secretKey = await _getSecretKey();
      if (secretKey == null || secretKey.isEmpty) {
        print('Paystack secret key is missing in Firestore config.');
        return null;
      }

      final response = await _dio.post(
        '/transaction/initialize',
        data: {
          'email': email,
          'amount': (amount * 100).toInt(), // Paystack expects amount in kobo
          'callback_url': 'bitsave://payment_complete', // Use your app's custom scheme if configured
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $secretKey',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        return response.data['data']; // Contains authorization_url, access_code, reference
      }
    } catch (e) {
      print('Paystack Initialization Error: $e');
    }
    return null;
  }

  /// Verifies a transaction status
  Future<bool> verifyTransaction(String reference) async {
    try {
      final secretKey = await _getSecretKey();
      if (secretKey == null || secretKey.isEmpty) {
        return false;
      }

      final response = await _dio.get(
        '/transaction/verify/$reference',
        options: Options(
          headers: {
            'Authorization': 'Bearer $secretKey',
          },
        ),
      );
      if (response.statusCode == 200 && response.data['status'] == true) {
        final data = response.data['data'];
        return data['status'] == 'success';
      }
    } catch (e) {
      print('Paystack Verification Error: $e');
    }
    return false;
  }
}
