
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';

import '../core/data/repositories/repository.dart';
import '../core/network/api_service.dart';
import '../core/utils/local_stotage.dart';
import '../core/services/secure_storage_service.dart';
import '../services/wallet_service.dart';
import '../ui/dialogs/info_alert/info_alert_dialog.dart';
import '../ui/views/auth/auth_view.dart';
import '../ui/views/dashboard/dashboard_view.dart';
import '../ui/views/home/home_view.dart';
import '../services/authentication_service.dart';
import '../services/bitcoin_price_service.dart';
import '../services/goals_service.dart';
import '../services/nostr_bitcoin_service.dart';
import '../services/wallet_service.dart';
import '../ui/views/onboarding/onboarding_view.dart';
import '../ui/views/startup/startup_view.dart';
// @stacked-import
/// @author Amrah sali
/// email: saliamrah300@gmail.com
/// sept, 2025
///

@StackedApp(
  logger: StackedLogger(),
  routes: [
    MaterialRoute(page: HomeView),
    MaterialRoute(page: StartupView),
    MaterialRoute(page: AuthView),
    MaterialRoute(page: DashboardView),
    MaterialRoute(page: OnboardingView),

    // MaterialRoute(page: NotificationView),
    // MaterialRoute(page: ProfileView),
// @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: BottomSheetService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: SnackbarService),
    LazySingleton(classType: SecureStorageService),
    LazySingleton(classType: ApiService),
    LazySingleton(classType: LocalStorage),
    LazySingleton(classType: Repository),
    LazySingleton(classType: AuthenticationService),
    LazySingleton(classType: WalletService),
    LazySingleton(classType: GoalsService),
    LazySingleton(classType: BitcoinPriceService),
    LazySingleton(classType: NostrBitcoinService),

    // @stacked-service
  ],
  // bottomsheets: [
  //   // StackedBottomsheet(classType: NoticeSheet),
  //   // @stacked-bottom-sheet
  // ],
  dialogs: [
    StackedDialog(classType: InfoAlertDialog),
    // @stacked-dialog
  ],
)
class App {}
