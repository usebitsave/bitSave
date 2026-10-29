import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.logger.dart';
import '../../../services/authentication_service.dart';
import '../goals/goals_view.dart';
import '../dashboard/dashboard_view.dart';
import '../Profile/profile_view.dart';
import '../activity/activity_view.dart';

class HomeViewModel extends BaseViewModel {
  final log = getLogger("HomeViewModel");

  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();

  double get walletBalance =>
      _authenticationService.currentUser?.walletBalanceNGN ?? 0.0;

  String get userName =>
      _authenticationService.currentUser?.fullName ?? 'User';

  int selectedIndex = 0;
  final PageController pageController = PageController();

  // 4-tab layout: Home / Goals / Activity / Profile
  final List<Widget> pages = [
    DashboardView(),          // 0 – Home
    const GoalsView(),        // 1 – Goals
    const ActivityView(),     // 2 – Activity
    const ProfileView(),      // 3 – Profile
  ];

  void changeSelectedPage(int index) {
    selectedIndex = index;
    pageController.jumpToPage(index);
    rebuildUi();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

}
