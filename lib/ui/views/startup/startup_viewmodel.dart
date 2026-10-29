import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../../../core/data/models/user_model.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../../core/utils/local_store_dir.dart';
import '../../../core/utils/local_stotage.dart';
import '../../../services/authentication_service.dart';
import '../../../state.dart';

class StartupViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _secureStorage = locator<SecureStorageService>();
  final _authService = locator<AuthenticationService>();

  Future<void> runStartupLogic() async {
    setBusy(true);
    try {
      await Future.delayed(const Duration(milliseconds: 800));

      // 1. Check if secure JWT token exists
      final token = await _secureStorage.getToken();

      if (token != null && token.isNotEmpty) {
        // Attempt to fetch profile from staging API with Bearer token
        try {
          await _authService.fetchUserProfile();
        } catch (e) {
          debugPrint('Could not refresh profile online: $e');
        }

        // Check if cached user data is available
        final userJson = await locator<LocalStorage>().fetch(LocalStorageDir.authUser);
        if (userJson != null) {
          try {
            profile.value = User.fromJson(Map<String, dynamic>.from(jsonDecode(userJson)));
          } catch (_) {}
        }

        userLoggedIn.value = true;
        _navigationService.clearStackAndShow(Routes.homeView);
      } else {
        _navigationService.clearStackAndShow(Routes.onboardingView);
      }
    } catch (e, st) {
      debugPrint('Startup init error: $e\n$st');
      _navigationService.clearStackAndShow(Routes.onboardingView);
    } finally {
      setBusy(false);
    }
  }
}