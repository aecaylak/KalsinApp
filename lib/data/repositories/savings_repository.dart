import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/saving.dart';
import '../../domain/models/goal.dart';
import '../../domain/models/user_profile.dart';

/// Hive ile yerel depolama işlemlerini yöneten repository.
class SavingsRepository {
  static const String _savingsBoxName = 'savings';
  static const String _goalBoxName    = 'goal';
  static const String _userBoxName    = 'user_profile';

  // ── Kutular ───────────────────────────────────────────────────
  Box<Saving> get _savingsBox => Hive.box<Saving>(_savingsBoxName);
  Box<Goal>   get _goalBox    => Hive.box<Goal>(_goalBoxName);
  Box<UserProfile> get _userBox => Hive.box<UserProfile>(_userBoxName);

  // ── Başlatma ─────────────────────────────────────────────────

  /// Hive kutularını açar, adaptörleri kaydeder ve seed atar.
  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SavingAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(GoalAdapter());
    }

    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(UserProfileAdapter());
    }

    await Hive.openBox<Saving>(_savingsBoxName);
    await Hive.openBox<Goal>(_goalBoxName);
    await Hive.openBox<UserProfile>(_userBoxName);
    await Hive.openBox('settings'); // tema ve ayarlar için
  }

  // ── Savings CRUD ─────────────────────────────────────────────

  List<Saving> getAllSavings() => _savingsBox.values.toList()
    ..sort((a, b) => b.savedAt.compareTo(a.savedAt));

  Future<void> addSaving(Saving saving) async {
    await _savingsBox.put(saving.id, saving);
  }

  Future<void> updateSaving(Saving saving) async {
    await _savingsBox.put(saving.id, saving);
  }

  Future<void> deleteSaving(String id) async {
    await _savingsBox.delete(id);
  }

  Future<void> clearAllSavings() async {
    await _savingsBox.clear();
  }

  // ── Goal CRUD ────────────────────────────────────────────────

  List<Goal> getAllGoals() => _goalBox.values.toList();

  Goal? getActiveGoal() =>
      _goalBox.isNotEmpty ? _goalBox.values.first : null;

  Future<void> addGoal(Goal goal) async {
    await _goalBox.put(goal.id, goal);
  }

  Future<void> setGoal(Goal goal) async {
    // Legacy: set a single goal (clears previous)
    await _goalBox.clear();
    await _goalBox.put(goal.id, goal);
  }

  Future<void> clearGoal() async {
    await _goalBox.clear();
  }

  Future<void> deleteGoal(String id) async {
    await _goalBox.delete(id);
  }

  // ── User Profile & Onboarding ────────────────────────────────

  UserProfile? getUserProfile() =>
      _userBox.isNotEmpty ? _userBox.get('main_profile') : null;

  bool hasCompletedOnboarding() {
    final profile = getUserProfile();
    return profile?.hasCompletedOnboarding ?? false;
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    await _userBox.put('main_profile', profile);
  }

  Future<void> clearUserProfile() async {
    await _userBox.clear();
  }

  // ── Mock Seed (Removed for real usage) ──────────────────────────

  /// (Legacy code, left for reference if we need demo data)
  Future<void> seedIfNeeded() async {
    return; // Do nothing, app is live.
  }

  // ── Hesaplama Yardımcıları ────────────────────────────────────

  /// Bu ayki toplam tasarruf
  double get currentMonthTotal {
    final now = DateTime.now();
    return getAllSavings()
        .where((s) =>
            s.savedAt.year == now.year && s.savedAt.month == now.month)
        .fold(0.0, (sum, s) => sum + s.amount);
  }

  /// Arka arkaya harcamasız gün sayısı (streak)
  int get currentStreak {
    final savings = getAllSavings();
    if (savings.isEmpty) return 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Bugün veya dün kayıt var mı? (streak'in korunması için)
    final latestDate = DateTime(
      savings.first.savedAt.year,
      savings.first.savedAt.month,
      savings.first.savedAt.day,
    );
    final daysSinceLast = todayDate.difference(latestDate).inDays;

    // Son kaydın üzerinden 2 günden fazla geçtiyse streak sıfırlanmış
    if (daysSinceLast > 1) {
      // Streak = bugün harcama yapılmadı ama son kayıt eski
      // Bu durumda streak = bugünden son kayda kadar geçen gün
      return daysSinceLast;
    }

    // Arka arkaya gün hesabı
    final savingDates = savings
        .map((s) => DateTime(s.savedAt.year, s.savedAt.month, s.savedAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 1;
    for (int i = 0; i < savingDates.length - 1; i++) {
      final diff = savingDates[i].difference(savingDates[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
