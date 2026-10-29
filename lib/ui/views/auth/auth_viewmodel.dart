// Path: lib/ui/views/auth/auth_viewmodel.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../../../core/data/models/user_model.dart';
import '../../../core/data/repositories/repository.dart';
import '../../../services/authentication_service.dart';
import '../../../core/utils/local_store_dir.dart';
import '../../../core/utils/local_stotage.dart';
import '../../../state.dart';
import 'auth_view.dart';
import './reset_password/reset_password_view.dart';

enum RegistrationResult { success, failure }

class AuthViewModel extends BaseViewModel {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final firstname = TextEditingController();
  final lastname = TextEditingController();
  final phone = TextEditingController();
  final estateController = TextEditingController();
  final apartmentController = TextEditingController();
  final cPassword = TextEditingController();
  bool remember = false;
  late PhoneNumber phoneNumber;
  final otp = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  int countdown = 0;
  Timer? _timer;
  bool get isCountdownActive => countdown > 0;
  bool obscure = true;
  String? errorMessage;
  bool codeSent = false;

  final AuthenticationService _authService = locator<AuthenticationService>();
  final Repository _repo = locator<Repository>();

  @override
  void dispose() {
    firstname.dispose();
    lastname.dispose();
    phone.dispose();
    estateController.dispose();
    apartmentController.dispose();
    cPassword.dispose();
    otp.dispose();
    email.dispose();
    password.dispose();
    _timer?.cancel();
    _verificationTimer?.cancel();
    super.dispose();
  }

  void init() {}

  void toggleRemember() {
    remember = !remember;
    rebuildUi();
  }

  void toggleObscure() {
    obscure = !obscure;
    rebuildUi();
  }

  void startCountdown() {
    countdown = 30;
    notifyListeners();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown > 0) {
        countdown--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  /// Registers a new user via the backend API.
  Future<void> register({
    required String fullName,
    required String dob,
    required VoidCallback onSuccess,
  }) async {
    setBusy(true);
    try {
      final emailInput = email.text.trim();
      final passwordInput = password.text.trim();

      if (emailInput.isEmpty || passwordInput.isEmpty) {
        locator<SnackbarService>().showSnackbar(
          message: 'Please fill in both email and password.',
        );
        return;
      }

      if (passwordInput.length < 8) {
        locator<SnackbarService>().showSnackbar(
          message: 'Password must be at least 8 characters long.',
        );
        return;
      }

      final resp = await _repo.register({
        'email': emailInput,
        'password': passwordInput,
      });

      if (resp.isSuccess && resp.data != null && resp.data['token'] != null) {
        final token = resp.data['token'] as String;
        await _authService.handleAuthSuccess(
          token,
          email: emailInput,
          fullName: fullName,
        );
        locator<SnackbarService>().showSnackbar(
          message: 'Account created successfully!',
        );
        onSuccess();
      } else {
        locator<SnackbarService>().showSnackbar(
          message: resp.errorMessage,
        );
      }
    } catch (e) {
      locator<SnackbarService>().showSnackbar(
        message: 'Something went wrong. Please try again later.',
      );
    } finally {
      setBusy(false);
    }
  }

  /// Logs a user in via the backend API.
  Future<void> login() async {
    setBusy(true);
    setError(null); // clear previous error
    try {
      final emailInput = email.text.trim();
      final passwordInput = password.text.trim();

      if (emailInput.isEmpty || passwordInput.isEmpty) {
        setError("Please enter both your email and password to continue.");
        return;
      }

      final resp = await _repo.login({
        'email': emailInput,
        'password': passwordInput,
      });

      if (resp.isSuccess && resp.data != null && resp.data['token'] != null) {
        final token = resp.data['token'] as String;
        await _authService.handleAuthSuccess(
          token,
          email: emailInput,
        );
        updateDeviceDetails();
        locator<NavigationService>().clearStackAndShow(Routes.homeView);
      } else {
        final errMsg = resp.errorMessage.isNotEmpty
            ? resp.errorMessage
            : 'Invalid credentials. Please check your email and password.';
        setError(errMsg);
        locator<SnackbarService>().showSnackbar(message: errMsg);
      }
    } catch (e) {
      const errMsg = "Something went wrong. Please try again later.";
      setError(errMsg);
      locator<SnackbarService>().showSnackbar(message: errMsg);
    } finally {
      setBusy(false);
    }
  }

  Timer? _verificationTimer;

  void startVerificationCheckTimer(VoidCallback onVerified) {
    // TODO: wire to backend email-verification polling if needed
    _verificationTimer?.cancel();
  }

  void cancelVerificationTimer() {
    _verificationTimer?.cancel();
  }

  Future<void> sendVerificationEmail() async {
    try {
      // TODO: call your backend resend-verification-email endpoint
      locator<SnackbarService>().showSnackbar(
        message: "A new verification link has been sent to your email.",
      );
    } catch (e) {
      locator<SnackbarService>().showSnackbar(
        message: "Failed to send verification link: $e",
      );
    }
  }

  Future<bool> checkEmailVerificationStatus() async {
    // TODO: call your backend to check verification status
    return false;
  }

  Future<void> submitOtp(String email, String code) async {
    locator<NavigationService>().navigateToView(
      ResetPasswordView(email: email, code: code),
    );
  }

  Future<void> resendOtp(String email) async {
    if (isCountdownActive) return;

    final startTime = DateTime.now();
    setBusy(true);

    try {
      final resp = await _repo.resetPasswordRequest({"email": email});
      final elapsed = DateTime.now().difference(startTime);
      debugPrint("Resend OTP latency: ${elapsed.inMilliseconds}ms");

      if (resp.statusCode == 200) {
        startCountdown();
      } else {
        locator<SnackbarService>().showSnackbar(
          message: resp.data["message"] ?? "Failed to resend OTP",
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      debugPrint("Error resending OTP: $e");
      locator<SnackbarService>().showSnackbar(
        message: "Error sending OTP: $e",
        duration: const Duration(seconds: 2),
      );
    } finally {
      setBusy(false);
    }
  }

  Future<void> createPin(String pin, VoidCallback onSuccess) async {
    setBusy(true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      onSuccess();
    } catch (e) {
      locator<SnackbarService>().showSnackbar(message: "Failed to create PIN.");
    } finally {
      setBusy(false);
    }
  }

  Future<void> updateDeviceDetails() async {
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String deviceId = "";
      String deviceType = "";
      String operatingSystem = Platform.operatingSystem;
      String? pushNotificationToken = '';
      String appVersion = "";
      String language = Platform.localeName;

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        deviceType = androidInfo.model;
        // TODO: get push token from your new notification service
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? "Unknown";
        deviceType = iosInfo.utsname.machine ?? "iOS Device";
        // TODO: get push token from your new notification service
      }

      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;

      await _repo.updateDeviceId({
        "deviceId": deviceId,
        "deviceType": deviceType,
        "operatingSystem": operatingSystem,
        "pushNotificationToken": pushNotificationToken,
        "appVersion": appVersion,
        "language": language,
      });
    } catch (e, stackTrace) {
      print("Error updating device details: $e");
      print(stackTrace);
    }
  }

  void resetForgotPasswordState() {
    codeSent = false;
    errorMessage = null;
    notifyListeners();
  }
}