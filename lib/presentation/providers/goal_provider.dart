import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/goal.dart';
import '../../data/repositories/savings_repository.dart';
import 'savings_provider.dart';

// ── Goals State ───────────────────────────────────────────────────────────────

class GoalsNotifier extends StateNotifier<List<Goal>> {
  GoalsNotifier(this._repo) : super(_repo.getAllGoals());

  final SavingsRepository _repo;

  /// Yeni bir hedef ekler
  Future<void> addGoal(Goal goal) async {
    await _repo.addGoal(goal);
    state = _repo.getAllGoals(); // refresh state
  }

  /// Belirli bir hedefi siler
  Future<void> deleteGoal(String id) async {
    await _repo.deleteGoal(id);
    state = _repo.getAllGoals(); // refresh state
  }

  /// Aktif (ilk/en yüksek öncelikli) hedefi döndürür
  Goal? get activeGoal => state.isNotEmpty ? state.first : null;
}

/// Tüm hedefler listesi
final goalsProvider = StateNotifierProvider<GoalsNotifier, List<Goal>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return GoalsNotifier(repo);
});

/// En küçük tutarlı hedefi (aktif hedef olarak) döner.
final activeGoalProvider = Provider<Goal?>((ref) {
  final goals = ref.watch(goalsProvider);
  if (goals.isEmpty) return null;
  // Küçükten büyüğe sırala ve ilkini al
  final sorted = [...goals]..sort((a, b) => a.targetAmount.compareTo(b.targetAmount));
  return sorted.first;
});

/// Bir hedefe katkıda bulunan toplam tutar:
/// - Bu hedefe özel bağlanmış tasarruflar (goalId == goal.id)
/// - Genel tasarruflar (goalId null veya boş) — tüm hedeflere sayılır
/// - Başka bir hedefe bağlı tasarruflar SAYILMAZ
final goalEffectiveTotalProvider = Provider.family<double, Goal>((ref, goal) {
  final savings = ref.watch(savingsProvider);
  double total = 0;
  for (final s in savings) {
    if (s.goalId == goal.id) {
      // Bu hedefe özel
      total += s.amount;
    } else if (s.goalId == null || s.goalId!.isEmpty) {
      // Genel (hedefe bağlanmamış) — herkese sayılır
      total += s.amount;
    }
    // Başka hedefe bağlı olanlar SAYILMAZ
  }
  return total;
});

/// Seçili bir hedefin ilerleme yüzdesi (0.0 – 1.0)
final goalProgressProvider = Provider.family<double?, Goal>((ref, goal) {
  final effectiveTotal = ref.watch(goalEffectiveTotalProvider(goal));
  final progress = effectiveTotal / goal.targetAmount;
  return progress.clamp(0.0, 1.0);
});

/// Seçili hedefin metin olarak ilerleme yüzdesi
final goalProgressTextProvider = Provider.family<String?, Goal>((ref, goal) {
  final progress = ref.watch(goalProgressProvider(goal));
  if (progress == null) return null;
  return '%${(progress * 100).toStringAsFixed(1)}';
});
