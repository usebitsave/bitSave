import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../app/app.locator.dart';
import '../core/data/models/api_models.dart';
import '../core/data/models/user_model.dart' as legacy;
import '../core/data/repositories/repository.dart';
import '../core/services/secure_storage_service.dart';
import '../core/utils/local_store_dir.dart';
import '../core/utils/local_stotage.dart';
import '../models/user_model.dart';
import '../state.dart';

class AuthenticationService {
  final _secureStorage = locator<SecureStorageService>();
  final _repository = locator<Repository>();
  final _localStorage = locator<LocalStorage>();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  BitSaveUserProfile? _apiProfile;
  BitSaveUserProfile? get apiProfile => _apiProfile;

  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  bool get isAuthenticated => _currentUser != null || _apiProfile != null;

  void setCurrentUser(UserModel user, String userId) {
    _currentUser = user;
    _currentUserId = userId;
  }

  /// Sets up user state after receiving JWT token from register or login
  Future<bool> handleAuthSuccess(String token, {String? email, String? fullName}) async {
    // 1. Store JWT token securely
    await _secureStorage.saveToken(token);

    // 2. Fetch authenticated user profile from GET /api/v1/users/me
    try {
      final profileResp = await _repository.getProfile();
      if (profileResp.isSuccess && profileResp.data != null) {
        final profileData = profileResp.data;
        if (profileData is Map<String, dynamic>) {
          _apiProfile = BitSaveUserProfile.fromJson(profileData);
          _currentUserId = _apiProfile!.id;
          await _secureStorage.saveUserId(_apiProfile!.id);
          await _secureStorage.saveUserEmail(_apiProfile!.email);

          // Populate UserModel for UI views
          final userEmail = _apiProfile!.email;
          final userName = (fullName != null && fullName.isNotEmpty)
              ? fullName
              : userEmail.split('@').first;

          _currentUser = UserModel(
            uid: _apiProfile!.id,
            fullName: userName,
            email: userEmail,
            dob: '',
            walletBalanceNGN: 0.0,
            createdAt: _apiProfile!.createdAt,
            isProfileComplete: true,
          );

          // Update legacy User state for views using state.dart
          profile.value = legacy.User(
            email: userEmail,
            firstName: userName,
            username: userName,
            createdAt: _apiProfile!.createdAt,
          );
          userLoggedIn.value = true;

          // Save to local storage for quick offline display
          await _localStorage.save(
            LocalStorageDir.authUser,
            jsonEncode(_currentUser!.toJson()),
          );

          return true;
        }
      }
    } catch (e) {
      debugPrint("Error fetching user profile after auth: $e");
    }

    // Fallback if profile fetch fails: construct basic session
    final fallbackEmail = email ?? 'user@bitsave.io';
    final fallbackName = (fullName != null && fullName.isNotEmpty)
        ? fullName
        : fallbackEmail.split('@').first;

    _currentUser = UserModel(
      uid: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fallbackName,
      email: fallbackEmail,
      dob: '',
      walletBalanceNGN: 0.0,
    );
    userLoggedIn.value = true;
    return true;
  }

  Future<void> addFundsToWallet(double amount) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        walletBalanceNGN: (_currentUser!.walletBalanceNGN) + amount,
      );
    }
  }

  Future<void> fetchUserProfile([String? userId]) async {
    final resp = await _repository.getProfile();
    if (resp.isSuccess && resp.data is Map<String, dynamic>) {
      _apiProfile = BitSaveUserProfile.fromJson(resp.data);
      _currentUserId = _apiProfile!.id;
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          email: _apiProfile!.email,
          createdAt: _apiProfile!.createdAt,
        );
      }
    }
  }

  Future<void> logout() async {
    await _secureStorage.clearAuth();
    await _localStorage.delete(LocalStorageDir.authUser);
    _currentUser = null;
    _apiProfile = null;
    _currentUserId = null;
    userLoggedIn.value = false;
    profile.value = legacy.User();
  }
}