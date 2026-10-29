import '../../network/api_response.dart';

abstract class IRepository {
  // --- BitSave Core Staging Endpoints ---

  /// POST /api/v1/auth/login
  Future<ApiResponse> login(Map<String, dynamic> req);

  /// POST /api/v1/auth/register
  Future<ApiResponse> register(Map<String, dynamic> req);

  /// GET /api/v1/users/me
  Future<ApiResponse> getProfile();

  /// GET /api/v1/wallets
  Future<ApiResponse> getWallets();

  /// GET /api/v1/goals
  Future<ApiResponse> getGoals();

  /// POST /api/v1/goals
  Future<ApiResponse> createGoal(Map<String, dynamic> req);

  /// GET /api/v1/goals/{id}
  Future<ApiResponse> getGoalById(String id);

  /// PUT /api/v1/goals/{id}
  Future<ApiResponse> updateGoal(String id, Map<String, dynamic> req);

  /// DELETE /api/v1/goals/{id}
  Future<ApiResponse> deleteGoal(String id);

  /// POST /api/v1/quotes
  Future<ApiResponse> createQuote(Map<String, dynamic> req);

  /// GET /api/v1/transactions
  Future<ApiResponse> getTransactions();

  /// POST /api/v1/transactions
  Future<ApiResponse> initiateDeposit(Map<String, dynamic> req, {String? idempotencyKey});

  /// Clear session/logout
  Future<ApiResponse> logOut();

  // --- Supporting/Legacy Methods (retained for backward compatibility) ---
  Future<ApiResponse> generatePaystackAccessCode({
    required String email,
    required int amount,
    String currency,
    String reference,
  });

  Future<ApiResponse> updateDeviceId(Map<String, dynamic> req);

  Future<ApiResponse> resetPasswordRequest(Map<String, dynamic> req);

  Future<ApiResponse> forgotPassword(Map<String, dynamic> req);

  Future<ApiResponse> verifyPasswordResetCode({
    required String email,
    required String code,
    required String newPassword,
  });
}
