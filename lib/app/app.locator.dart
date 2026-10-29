// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// StackedLocatorGenerator
// **************************************************************************

// ignore_for_file: public_member_api_docs, implementation_imports, depend_on_referenced_packages

import 'package:stacked_services/src/bottom_sheet/bottom_sheet_service.dart';
import 'package:stacked_services/src/dialog/dialog_service.dart';
import 'package:stacked_services/src/navigation/navigation_service.dart';
import 'package:stacked_services/src/snackbar/snackbar_service.dart';
import 'package:stacked_shared/stacked_shared.dart';

import '../core/data/repositories/repository.dart';
import '../core/network/api_service.dart';
import '../core/services/secure_storage_service.dart';
import '../core/utils/local_stotage.dart';
import '../services/authentication_service.dart';
import '../services/bitcoin_price_service.dart';
import '../services/goals_service.dart';
import '../services/nostr_bitcoin_service.dart';
import '../services/wallet_service.dart';

final locator = StackedLocator.instance;

Future<void> setupLocator(
    {String? environment, EnvironmentFilter? environmentFilter}) async {
// Register environments
  locator.registerEnvironment(
      environment: environment, environmentFilter: environmentFilter);

// Register dependencies
  locator.registerLazySingleton(() => BottomSheetService());
  locator.registerLazySingleton(() => DialogService());
  locator.registerLazySingleton(() => NavigationService());
  locator.registerLazySingleton(() => SnackbarService());
  locator.registerLazySingleton(() => SecureStorageService());
  locator.registerLazySingleton(() => ApiService());
  locator.registerLazySingleton(() => LocalStorage());
  locator.registerLazySingleton(() => Repository());
  locator.registerLazySingleton(() => AuthenticationService());
  locator.registerLazySingleton(() => WalletService());
  locator.registerLazySingleton(() => GoalsService());
  locator.registerLazySingleton(() => BitcoinPriceService());
  locator.registerLazySingleton(() => NostrBitcoinService());
}
