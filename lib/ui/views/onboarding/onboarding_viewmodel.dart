import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import '../auth/auth_view.dart';
import '../../../core/utils/local_stotage.dart';
import '../../../core/utils/local_store_dir.dart';

class OnboardingViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final PageController pageController = PageController();

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void nextPage() {
    if (_currentIndex < 2) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      navigateToSignup();
    }
  }

  void skip() {
    navigateToSignup();
  }

  Future<void> _setOnboarded() async {
    await locator<LocalStorage>().save(LocalStorageDir.onboarded, "true");
  }

  void navigateToSignup() async {
    await _setOnboarded();
    _navigationService.navigateToAuthView(authType: AuthType.register);
  }

  void navigateToLogin() async {
    await _setOnboarded();
    _navigationService.navigateToAuthView(authType: AuthType.login);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
