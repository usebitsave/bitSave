import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../services/wallet_service.dart';
import 'package:url_launcher/url_launcher.dart';

class DepositViewModel extends BaseViewModel {
  final WalletService _walletService = locator<WalletService>();

  Future<bool> startDepositFlow(String amountStr) async {
    setBusy(true);
    try {
      final amount = double.parse(amountStr);
      final tx = await _walletService.initiateDeposit(amountNgn: amount);
      return tx != null;
    } catch (e) {
      rethrow;
    } finally {
      setBusy(false);
    }
  }
}