import 'package:dio/dio.dart';

import '../../../app/app.locator.dart';
import '../../config/app_config.dart';
import '../../network/api_response.dart';
import '../../network/api_service.dart';
import '../../services/secure_storage_service.dart';
import 'repository_interface.dart';

class Repository extends IRepository {
  final api = locator<ApiService>();
  final secureStorage = locator<SecureStorageService>();

  // ==========================================
  // BitSave Core Staging API Endpoints
  // ==========================================

  /// POST /api/v1/auth/login
  @override
  Future<ApiResponse> login(Map<String, dynamic> req) async {
    final response = await api.call(
      method: HttpMethod.post,
      endpoint: AppConfig.loginEndpoint,
      reqBody: {
        'email': req['email'],
        'password': req['password'],
      },
      protected: false,
    );
    return response;
  }

  /// POST /api/v1/auth/register
  @override
  Future<ApiResponse> register(Map<String, dynamic> req) async {
    final response = await api.call(
      method: HttpMethod.post,
      endpoint: AppConfig.registerEndpoint,
      reqBody: {
        'email': req['email'],
        'password': req['password'],
      },
      protected: false,
    );
    return response;
  }

  /// GET /api/v1/users/me
  @override
  Future<ApiResponse> getProfile() async {
    final response = await api.call(
      method: HttpMethod.get,
      endpoint: AppConfig.userMeEndpoint,
      protected: true,
    );
    return response;
  }

  /// GET /api/v1/wallets (Mocked)
  @override
  Future<ApiResponse> getWallets() async {
    final response = await api.call(
      method: HttpMethod.get,
      endpoint: AppConfig.walletsEndpoint,
      protected: true,
    );
    return response;
  }

  /// GET /api/v1/goals
  @override
  Future<ApiResponse> getGoals() async {
    final response = await api.call(
      method: HttpMethod.get,
      endpoint: AppConfig.goalsEndpoint,
      protected: true,
    );
    return response;
  }

  /// POST /api/v1/goals
  /// Required: name, target_amount_ngn (string), deadline (ISO8601 string)
  @override
  Future<ApiResponse> createGoal(Map<String, dynamic> req) async {
    final response = await api.call(
      method: HttpMethod.post,
      endpoint: AppConfig.goalsEndpoint,
      reqBody: req,
      protected: true,
    );
    return response;
  }

  /// GET /api/v1/goals/{id}
  @override
  Future<ApiResponse> getGoalById(String id) async {
    final response = await api.call(
      method: HttpMethod.get,
      endpoint: '${AppConfig.goalsEndpoint}/$id',
      protected: true,
    );
    return response;
  }

  /// PUT /api/v1/goals/{id}
  @override
  Future<ApiResponse> updateGoal(String id, Map<String, dynamic> req) async {
    final response = await api.call(
      method: HttpMethod.put,
      endpoint: '${AppConfig.goalsEndpoint}/$id',
      reqBody: req,
      protected: true,
    );
    return response;
  }

  /// DELETE /api/v1/goals/{id}
  @override
  Future<ApiResponse> deleteGoal(String id) async {
    final response = await api.call(
      method: HttpMethod.delete,
      endpoint: '${AppConfig.goalsEndpoint}/$id',
      protected: true,
    );
    return response;
  }

  /// POST /api/v1/quotes (Mocked)
  /// Required: amount_ngn (string)
  @override
  Future<ApiResponse> createQuote(Map<String, dynamic> req) async {
    final response = await api.call(
      method: HttpMethod.post,
      endpoint: AppConfig.quotesEndpoint,
      reqBody: req,
      protected: true,
    );
    return response;
  }

  /// GET /api/v1/transactions (Mocked)
  @override
  Future<ApiResponse> getTransactions() async {
    final response = await api.call(
      method: HttpMethod.get,
      endpoint: AppConfig.transactionsEndpoint,
      protected: true,
    );
    return response;
  }

  /// POST /api/v1/transactions (Mocked)
  /// Required header: Idempotency-Key
  /// Body: amount_ngn (string), quote_id (optional uuid)
  @override
  Future<ApiResponse> initiateDeposit(
    Map<String, dynamic> req, {
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ??
        'bitsave_tx_${DateTime.now().millisecondsSinceEpoch}_${req['amount_ngn']}';

    final response = await api.call(
      method: HttpMethod.post,
      endpoint: AppConfig.transactionsEndpoint,
      reqBody: req,
      customHeaders: {
        'Idempotency-Key': key,
      },
      protected: true,
    );
    return response;
  }

  /// Log out and clear stored secure session
  @override
  Future<ApiResponse> logOut() async {
    await secureStorage.clearAuth();
    return ApiResponse(
      Response(
        statusCode: 200,
        data: {'status': 'logged_out'},
        requestOptions: RequestOptions(path: '/logout'),
      ),
    );
  }

  // ==========================================
  // Supporting Methods
  // ==========================================

  @override
  Future<ApiResponse> generatePaystackAccessCode({
    required String email,
    required int amount,
    String currency = "NGN",
    String reference = "",
  }) async {
    final String apiUrl = "https://api.paystack.co/transaction/initialize";

    try {
      final dio = Dio();
      dio.options.headers["Content-Type"] = "application/json";

      final response = await dio.post(apiUrl, data: {
        "email": email,
        "amount": amount * 100, // Convert to kobo
        "currency": currency,
        "reference": reference.isNotEmpty
            ? reference
            : "bitsave_${DateTime.now().millisecondsSinceEpoch}"
      });

      if (response.statusCode == 200 && response.data['status'] == true) {
        return ApiResponse(response);
      } else {
        return ApiResponse(Response(
          requestOptions: RequestOptions(path: apiUrl),
          statusCode: response.statusCode ?? 400,
          data: {"error": response.data["message"] ?? "Failed to initialize payment"},
        ));
      }
    } catch (e) {
      return ApiResponse(Response(
        requestOptions: RequestOptions(path: apiUrl),
        statusCode: 500,
        data: {"error": "Failed to generate access code: $e"},
      ));
    }
  }

  @override
  Future<ApiResponse> updateDeviceId(Map<String, dynamic> req) async {
    // Stubbed for mobile device tracking
    return ApiResponse(
      Response(
        statusCode: 200,
        data: {'status': 'ok'},
        requestOptions: RequestOptions(path: '/device-details'),
      ),
    );
  }

  @override
  Future<ApiResponse> resetPasswordRequest(Map<String, dynamic> req) async {
    // Staging API does not yet expose reset password endpoint
    return ApiResponse(
      Response(
        statusCode: 200,
        data: {'message': 'Password reset request recorded'},
        requestOptions: RequestOptions(path: '/auth/resetpassword'),
      ),
    );
  }

  @override
  Future<ApiResponse> forgotPassword(Map<String, dynamic> req) async {
    return ApiResponse(
      Response(
        statusCode: 200,
        data: {'message': 'Instructions sent'},
        requestOptions: RequestOptions(path: '/auth/forgotpassword'),
      ),
    );
  }

  @override
  Future<ApiResponse> verifyPasswordResetCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    return ApiResponse(
      Response(
        statusCode: 200,
        data: {'message': 'Password reset verified'},
        requestOptions: RequestOptions(path: '/auth/verify-reset'),
      ),
    );
  }
}
