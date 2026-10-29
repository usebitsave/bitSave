import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.logger.dart';
import '../../../core/data/models/api_models.dart';
import '../../../services/goals_service.dart';
import '../../../services/wallet_service.dart';

class GoalsViewModel extends BaseViewModel {
  final log = getLogger('GoalsViewModel');
  final GoalsService _goalsService = locator<GoalsService>();
  final WalletService _walletService = locator<WalletService>();

  List<BitSaveSavingsGoal> get goals => _goalsService.goals.value;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Controllers for the create/edit sheet ──────────────────────────────────
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  DateTime? selectedDeadline;
  String selectedCategory = 'General';
  String selectedFrequency = 'Monthly';

  final List<String> categories = const [
    'General',
    'Emergency',
    'Education',
    'Housing',
    'Car',
    'Business',
  ];

  final List<String> frequencies = const [
    'Daily',
    'Weekly',
    'Monthly',
    'Flexible',
  ];

  void setCategory(String cat) {
    selectedCategory = cat;
    notifyListeners();
  }

  void setFrequency(String freq) {
    selectedFrequency = freq;
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    setBusy(true);
    _errorMessage = null;
    try {
      await _goalsService.fetchGoals(forceRefresh: true);
    } catch (e) {
      _errorMessage = 'Failed to load goals. Pull to refresh.';
      log.e('init error: $e');
    } finally {
      setBusy(false);
    }
  }

  Future<void> refresh() => init();

  // ── Create ─────────────────────────────────────────────────────────────────
  Future<bool> createGoal(BuildContext context) async {
    final name = nameController.text.trim();
    final amountText = amountController.text.trim().replaceAll(',', '');
    final deadline = selectedDeadline;

    if (name.isEmpty || amountText.isEmpty || deadline == null) return false;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return false;

    setBusy(true);
    try {
      final created = await _goalsService.createGoal(
        name: name,
        targetAmountNgn: amount.toStringAsFixed(2),
        deadline: deadline.toUtc().toIso8601String(),
        category: selectedCategory,
        contributionFrequency: selectedFrequency,
      );
      if (created != null) {
        _clearForm();
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to create goal. Please try again.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      log.e('createGoal error: $e');
      _errorMessage = 'An error occurred.';
      notifyListeners();
      return false;
    } finally {
      setBusy(false);
    }
  }

  // ── Update ─────────────────────────────────────────────────────────────────
  Future<bool> updateGoal(String id) async {
    final name = nameController.text.trim();
    final amountText = amountController.text.trim().replaceAll(',', '');
    final deadline = selectedDeadline;

    setBusy(true);
    try {
      final updated = await _goalsService.updateGoal(
        id,
        name: name.isNotEmpty ? name : null,
        targetAmountNgn: amountText.isNotEmpty
            ? (double.tryParse(amountText) ?? 0).toStringAsFixed(2)
            : null,
        deadline: deadline?.toUtc().toIso8601String(),
        category: selectedCategory,
        contributionFrequency: selectedFrequency,
      );
      _clearForm();
      notifyListeners();
      return updated != null;
    } catch (e) {
      log.e('updateGoal error: $e');
      return false;
    } finally {
      setBusy(false);
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<bool> deleteGoal(String id) async {
    setBusy(true);
    try {
      final ok = await _goalsService.deleteGoal(id);
      notifyListeners();
      return ok;
    } catch (e) {
      log.e('deleteGoal error: $e');
      return false;
    } finally {
      setBusy(false);
    }
  }

  // ── Deposit into a goal ────────────────────────────────────────────────────
  Future<BitSaveTransaction?> depositToGoal({
    required double amountNgn,
    required String goalId,
  }) async {
    setBusy(true);
    try {
      // 1. Get quote
      final quote = await _walletService.getQuote(amountNgn: amountNgn);

      // 2. Initiate deposit (mocked — treat as instant)
      final tx = await _walletService.initiateDeposit(
        amountNgn: amountNgn,
        quoteId: quote?.id,
        goalId: goalId,
      );
      return tx;
    } catch (e) {
      log.e('depositToGoal error: $e');
      return null;
    } finally {
      setBusy(false);
    }
  }

  // ── Form helpers ───────────────────────────────────────────────────────────
  void prefillForm(BitSaveSavingsGoal goal) {
    nameController.text = goal.name;
    amountController.text = goal.targetAmountDouble.toStringAsFixed(0);
    selectedDeadline = goal.deadline;
    selectedCategory = goal.category;
    selectedFrequency = goal.contributionFrequency;
    notifyListeners();
  }

  void setDeadline(DateTime date) {
    selectedDeadline = date;
    notifyListeners();
  }

  void _clearForm() {
    nameController.clear();
    amountController.clear();
    selectedDeadline = null;
    selectedCategory = 'General';
    selectedFrequency = 'Monthly';
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────
  /// Days remaining until deadline
  int daysLeft(DateTime? deadline) {
    if (deadline == null) return 0;
    return deadline.difference(DateTime.now()).inDays.clamp(0, 9999);
  }

  /// Progress: how far along time-wise from createdAt → deadline
  double timeProgress(BitSaveSavingsGoal goal) {
    if (goal.deadline == null || goal.createdAt == null) return 0.0;
    final total = goal.deadline!.difference(goal.createdAt!).inDays;
    final elapsed = DateTime.now().difference(goal.createdAt!).inDays;
    if (total <= 0) return 1.0;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}
