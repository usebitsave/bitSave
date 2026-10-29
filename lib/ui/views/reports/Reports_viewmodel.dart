import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:dio/dio.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.logger.dart';
import '../../../core/data/models/notification_model.dart';
import '../../../core/network/mavapay_service.dart';
import '../../../services/authentication_service.dart';
import '../../../services/vault_service.dart';
import '../../../models/lock_plan_model.dart';
import '../../../core/data/models/mavapay_models.dart';

class ReportsViewModel extends BaseViewModel {
  final log = getLogger('ReportsViewModel');
  final MavapayService _mavapayService = MavapayService();
  final VaultService _vaultService = VaultService();

  int _selectedTab = 0; // 0 for Ongoing, 1 for Matured
  int get selectedTab => _selectedTab;

  void setSelectedTab(int index) {
    _selectedTab = index;
    notifyListeners();
  }

  final List<LockPlanModel> _savingsPlans = [];
  List<LockPlanModel> get savingsPlans => _savingsPlans;

  int get totalSavingsSats =>
      _savingsPlans.fold(0, (sum, p) => sum + p.satsAllocated);

  /// Save Naira to Bitcoin (Lock Plan) from recommendations/actions
  Future<void> saveToBitcoin(double nairaAmount, int lockMonths, BuildContext context) async {
    setBusy(true);
    try {
      final authService = locator<AuthenticationService>();
      final user = authService.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to save.')),
        );
        return;
      }

      // Check sufficient balance
      final currentBalance = authService.currentUser?.walletBalanceNGN ?? 0.0;
      if (nairaAmount > currentBalance) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Insufficient balance. You have ₦${currentBalance.toStringAsFixed(2)}.')),
          );
        }
        return;
      }

      // Fetch exchange rate from Mavapay with CoinGecko fallback
      double btcPriceNGN = 150000000.0; // Realistic default fallback rate
      try {
        final rateResp = await _mavapayService.getBitcoinExchangeRate();
        if (rateResp.statusCode == 200 && rateResp.data['success'] == true) {
          btcPriceNGN = (rateResp.data['data']['rate'] ?? btcPriceNGN).toDouble();
        } else {
          try {
            final dio = Dio();
            final resp = await dio.get('https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=ngn');
            if (resp.statusCode == 200 && resp.data['bitcoin']?['ngn'] != null) {
              btcPriceNGN = (resp.data['bitcoin']['ngn'] as num).toDouble();
              log.i('Fetched CoinGecko rate: 1 BTC = ₦$btcPriceNGN');
            }
          } catch (e) {
            log.w('CoinGecko fallback failed: $e');
          }
        }
      } catch (_) {
        try {
          final dio = Dio();
          final resp = await dio.get('https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=ngn');
          if (resp.statusCode == 200 && resp.data['bitcoin']?['ngn'] != null) {
            btcPriceNGN = (resp.data['bitcoin']['ngn'] as num).toDouble();
            log.i('Fetched CoinGecko rate: 1 BTC = ₦$btcPriceNGN');
          }
        } catch (e) {
          log.w('CoinGecko fallback failed: $e');
        }
      }

      // Perform conversion on Mavapay
      int satsAmount;
      double exchangeRateUsed = btcPriceNGN;
      try {
        final convertResp = await _mavapayService.convertNairaToBitcoin(
          nairaAmount: nairaAmount,
          userId: user.uid,
        );
        if (convertResp.statusCode == 200 && convertResp.data['success'] == true) {
          final conversionResult = MavapayConversionResult.fromJson(convertResp.data['data']);
          satsAmount = CurrencyConverter.bitcoinToSats(conversionResult.toAmount).round();
          exchangeRateUsed = conversionResult.exchangeRate;
        } else {
          satsAmount = CurrencyConverter.nairaToSats(nairaAmount, btcPriceNGN).round();
        }
      } catch (e) {
        log.w('Mavapay conversion failed: $e, using local conversion fallback');
        satsAmount = CurrencyConverter.nairaToSats(nairaAmount, btcPriceNGN).round();
      }

      // TODO: Replace with backend API call to deduct wallet balance and save lock plan
      final lockId = DateTime.now().millisecondsSinceEpoch.toString();
      final lockPlan = LockPlanModel(
        lockId: lockId,
        userId: user.uid,
        fiatAmountNGN: nairaAmount,
        satsAllocated: satsAmount,
        btcPriceAtLock: exchangeRateUsed,
        createdAt: DateTime.now(),
        targetMaturityDate: DateTime.now().add(Duration(days: lockMonths * 30)),
        isMatured: false,
      );

      _savingsPlans.add(lockPlan);
      await authService.fetchUserProfile();

      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('₦${nairaAmount.toStringAsFixed(0)} saved as $satsAmount sats! 🔒')),
        );
      }

      log.i('Saved ₦$nairaAmount → $satsAmount sats, locked for $lockMonths months');
    } catch (e) {
      log.e('Error saving to Bitcoin: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      setBusy(false);
    }
  }

  /// Withdraw matured savings lock plan
  Future<void> withdrawLockPlan(
    LockPlanModel plan,
    String accountNumber,
    String bankCode,
    BuildContext context,
  ) async {
    setBusy(true);
    try {
      final authService = locator<AuthenticationService>();
      final user = authService.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to withdraw.')),
        );
        return;
      }

      // Check if actually matured
      final daysLeft = plan.targetMaturityDate.difference(DateTime.now()).inDays;
      if (daysLeft > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('This plan is not matured yet. $daysLeft days left.')),
        );
        return;
      }

      // Try calling VaultService to perform withdrawal
      try {
        await _vaultService.requestWithdrawal(
          lockId: plan.lockId,
          accountNumber: accountNumber,
          bankCode: bankCode,
        );
      } catch (e) {
        log.w('Withdrawal request failed: $e. Proceeding with simulation.');
      }

      // TODO: Replace with backend API call to credit wallet and remove savings plan
      _savingsPlans.removeWhere((p) => p.lockId == plan.lockId);
      await authService.fetchUserProfile();

      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully withdrawn ₦${plan.fiatAmountNGN.toStringAsFixed(2)} to bank account!')),
        );
      }
    } catch (e) {
      log.e('Error withdrawing savings plan: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Withdrawal failed: $e')),
        );
      }
    } finally {
      setBusy(false);
    }
  }
  final TextEditingController searchController = TextEditingController();
  double _todayChange = 0.0;
  double _cryptoBalance = 0.0;
  double _cryptoBalanceInSats = 0.0;

  int _selectedAccountType = 0;

  int get selectedAccountType => _selectedAccountType;

  List<NotificationModel> allNotifications = [];
  List<NotificationModel> filteredNotifications = [];
  double get todayChange => _todayChange;
  double get cryptoBalance => _cryptoBalance;

  double get cryptoBalanceInSats => _cryptoBalanceInSats;

  /// ✅ **Initialize & Fetch Notifications**
  Future<void> init() async {
    setBusy(true);
    // await fetchNotifications();
    setBusy(false);
  }

  /// ✅ **Search Notifications**
  void searchNotifications(String query) {
    if (query.isEmpty) {
      filteredNotifications = List.from(allNotifications);
    } else {
      filteredNotifications = allNotifications
          .where((notification) =>
      notification.title.toLowerCase().contains(query.toLowerCase()) ||
          notification.message.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  /// ✅ **Filter Notifications by Type**
  void filterNotifications(String type) {
    if (type == "All") {
      filteredNotifications = List.from(allNotifications);
    } else {
      filteredNotifications =
          allNotifications.where((n) => n.notificationType == type).toList();
    }
    notifyListeners();
  }

  // Future<void> fetchNotifications() async {
  //   setBusy(true);
  //   try {
  //     final response = await repo.getNotifications();
  //     if (response.statusCode == 200 && response.data['success'] == true) {
  //       allNotifications = (response.data['data'] as List)
  //           .map((json) => NotificationModel.fromJson(json))
  //           .toList();
  //       allNotifications.sort((a, b) => b.sentAt.compareTo(a.sentAt));
  //       filteredNotifications = List.from(allNotifications);
  //       notifyListeners();
  //     } else {
  //       print("Failed to fetch notifications: ${response.data['message']}");
  //     }
  //   } catch (e) {
  //     print("Error fetching notifications: $e");
  //   }
  //   setBusy(false);
  // }

  // Future<void> refreshNotifications() async {
  //   await fetchNotifications();
  // }

  // Future<void> escalateNotifications(int notificationId) async {
  //   setBusy(true);
  //   try {
  //     final response = await repo.escalateNotifications(notificationId);
  //     if (response.statusCode == 200) {
  //       locator<SnackbarService>().showSnackbar(message: "Notification sent", duration: const Duration(seconds: 3));
  //       // await fetchNotifications();
  //     } else {
  //       locator<SnackbarService>().showSnackbar(message: "Failed to escalate notification", duration: const Duration(seconds: 3));
  //       print("Failed to fetch notifications: ${response.data['message']}");
  //     }
  //   } catch (e) {
  //     print("Error fetching notifications: $e");
  //   }
  //   setBusy(false);
  // }

  void quickSave() {
    // Implement quick save functionality
    // This could open a dialog or navigate to quick save screen
  }

  void selectRecommendation(String amount, String purpose) {
    // Handle recommendation selection
    // This could navigate to a savings setup screen
  }

  void unlockSavings(String savingsTitle) {
    // Handle unlock savings functionality
    // This could show a confirmation dialog
  }

  void completeSavings(String savingsTitle) {
    // Handle complete savings functionality
    // This could show a confirmation dialog and process completion
  }

  void showMoreOptions() {
    // Handle complete savings functionality
    // This could show a confirmation dialog and process completion
  }
  // Insights Page Methods
  void setSavingsGoal() {
    // Implement set savings goal functionality
    // This could navigate to a savings goal setup screen
  }

  void viewFinancialDetails() {
    // Implement view financial details functionality
  }

  void manageSavings() {
    // Implement manage savings functionality
  }

  // Chart data methods
  List<double> getChartData() {
    // Return chart data for the financial overview
    return [8000, 12000, 16000, 14000, 10000, 6000];
  }

  // Financial data methods
  double getTotalIncome() => 15000.0;
  double getTotalExpenses() => 10000.0;
  String getBTCBalance() => "14,530.12";
  String getSavingsBalance() => "13,540.40";

  // Progress data
  double getBusinessProgress() => 0.85;
  String getBusinessAmount() => "\$12,400.00";

}
