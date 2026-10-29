import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  static const String _keyJwtToken = 'jwt_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';

  /// Save JWT auth token securely
  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyJwtToken, value: token);
  }

  /// Retrieve stored JWT auth token
  Future<String?> getToken() async {
    return await _storage.read(key: _keyJwtToken);
  }

  /// Delete stored JWT auth token
  Future<void> deleteToken() async {
    await _storage.delete(key: _keyJwtToken);
  }

  /// Save user id
  Future<void> saveUserId(String id) async {
    await _storage.write(key: _keyUserId, value: id);
  }

  /// Retrieve user id
  Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  /// Save user email
  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: _keyUserEmail, value: email);
  }

  /// Retrieve user email
  Future<String?> getUserEmail() async {
    return await _storage.read(key: _keyUserEmail);
  }

  /// Check if user has an active token
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all credentials and tokens
  Future<void> clearAuth() async {
    await _storage.delete(key: _keyJwtToken);
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyUserEmail);
  }
}
