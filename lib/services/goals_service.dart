import 'package:flutter/foundation.dart';
import '../app/app.locator.dart';
import '../core/data/models/api_models.dart';
import '../core/data/repositories/repository.dart';

class GoalsService {
  final _repository = locator<Repository>();

  final ValueNotifier<List<BitSaveSavingsGoal>> goals =
      ValueNotifier<List<BitSaveSavingsGoal>>([]);

  bool _loaded = false;
  bool get isLoaded => _loaded;

  // ── Fetch all goals ────────────────────────────────────────────────────────
  Future<List<BitSaveSavingsGoal>> fetchGoals({bool forceRefresh = false}) async {
    if (_loaded && !forceRefresh) return goals.value;
    try {
      final resp = await _repository.getGoals();
      if (resp.isSuccess && resp.data != null) {
        final raw = resp.data;
        List<dynamic> list = [];
        if (raw is List) {
          list = raw;
        } else if (raw is Map && raw['goals'] is List) {
          list = raw['goals'];
        } else if (raw is Map && raw['data'] is List) {
          list = raw['data'];
        }
        goals.value = list
            .map((e) => BitSaveSavingsGoal.fromJson(e as Map<String, dynamic>))
            .toList();
        _loaded = true;
      }
    } catch (e) {
      debugPrint('GoalsService.fetchGoals error: $e');
    }
    return goals.value;
  }

  // ── Create goal ────────────────────────────────────────────────────────────
  /// [name]              — human-readable label
  /// [targetAmountNgn]   — amount as decimal string e.g. "50000.00"
  /// [deadline]          — ISO-8601 datetime string
  Future<BitSaveSavingsGoal?> createGoal({
    required String name,
    required String targetAmountNgn,
    required String deadline,
    String category = 'General',
    String contributionFrequency = 'Monthly',
  }) async {
    try {
      final resp = await _repository.createGoal({
        'name': name,
        'target_amount_ngn': targetAmountNgn,
        'deadline': deadline,
        'category': category,
        'contribution_frequency': contributionFrequency,
      });
      if (resp.isSuccess && resp.data != null) {
        final data = resp.data is Map ? resp.data as Map<String, dynamic> : null;
        if (data != null) {
          final goal = BitSaveSavingsGoal.fromJson(data);
          goals.value = [...goals.value, goal];
          return goal;
        }
      }
    } catch (e) {
      debugPrint('GoalsService.createGoal error: $e');
    }
    return null;
  }

  // ── Update goal ────────────────────────────────────────────────────────────
  Future<BitSaveSavingsGoal?> updateGoal(
    String id, {
    String? name,
    String? targetAmountNgn,
    String? deadline,
    String? category,
    String? contributionFrequency,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (targetAmountNgn != null) body['target_amount_ngn'] = targetAmountNgn;
      if (deadline != null) body['deadline'] = deadline;
      if (category != null) body['category'] = category;
      if (contributionFrequency != null) {
        body['contribution_frequency'] = contributionFrequency;
      }

      final resp = await _repository.updateGoal(id, body);
      if (resp.isSuccess && resp.data != null) {
        final data = resp.data as Map<String, dynamic>?;
        if (data != null) {
          final updated = BitSaveSavingsGoal.fromJson(data);
          goals.value = goals.value.map((g) => g.id == id ? updated : g).toList();
          return updated;
        }
      }
    } catch (e) {
      debugPrint('GoalsService.updateGoal error: $e');
    }
    return null;
  }

  // ── Delete goal ────────────────────────────────────────────────────────────
  Future<bool> deleteGoal(String id) async {
    try {
      final resp = await _repository.deleteGoal(id);
      if (resp.isSuccess) {
        goals.value = goals.value.where((g) => g.id != id).toList();
        return true;
      }
    } catch (e) {
      debugPrint('GoalsService.deleteGoal error: $e');
    }
    return false;
  }

  void clearCache() {
    _loaded = false;
    goals.value = [];
  }
}
