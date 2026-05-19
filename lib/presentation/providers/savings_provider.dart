import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/notification_service.dart';
import '../../domain/models/saving.dart';
import '../../domain/models/category.dart';
import '../../data/repositories/savings_repository.dart';

// ── Repository Provider ───────────────────────────────────────────────────────

final repositoryProvider = Provider<SavingsRepository>((ref) {
  return SavingsRepository();
});

// ── Timeframe State ───────────────────────────────────────────────────────────

enum SavingsTimeframe {
  daily,
  weekly,
  monthly,
  allTime,
}

extension SavingsTimeframeExt on SavingsTimeframe {
  String get label {
    switch (this) {
      case SavingsTimeframe.daily:
        return 'BUGÜN KURTARDIĞIN';
      case SavingsTimeframe.weekly:
        return 'BU HAFTA KURTARDIĞIN';
      case SavingsTimeframe.monthly:
        return 'BU AY KURTARDIĞIN';
      case SavingsTimeframe.allTime:
        return 'TOPLAM KURTARDIĞIN';
    }
  }

  SavingsTimeframe get next {
    final values = SavingsTimeframe.values;
    final nextIndex = (index + 1) % values.length;
    return values[nextIndex];
  }
}

final timeframeProvider = StateProvider<SavingsTimeframe>((ref) => SavingsTimeframe.monthly);

// ── Savings State ─────────────────────────────────────────────────────────────

class SavingsNotifier extends StateNotifier<List<Saving>> {
  SavingsNotifier(this._repo) : super(_repo.getAllSavings());

  final SavingsRepository _repo;
  final _uuid = const Uuid();

  /// Yeni bir tasarruf kaydı ekler ve state'i günceller.
  Future<void> addSaving({
    required double amount,
    required String categoryId,
    String? note,
    DateTime? date,
    String? goalId,
  }) async {
    final saving = Saving(
      id: _uuid.v4(),
      amount: amount,
      categoryId: categoryId,
      note: note,
      savedAt: date ?? DateTime.now(),
      goalId: goalId,
    );
    await _repo.addSaving(saving);
    state = _repo.getAllSavings();
    unawaited(NotificationService.instance.showSavingAdded(amount));
  }

  /// Mevcut bir tasarrufu günceller.
  Future<void> updateSaving(Saving saving) async {
    await _repo.updateSaving(saving);
    state = _repo.getAllSavings();
  }

  /// Belirtilen id'li kaydı siler.
  Future<void> deleteSaving(String id) async {
    await _repo.deleteSaving(id);
    state = _repo.getAllSavings();
  }

  /// Sadece bu ayın tasarruflarını döner.
  List<Saving> get currentMonthSavings {
    final now = DateTime.now();
    return state
        .where((s) =>
            s.savedAt.year == now.year && s.savedAt.month == now.month)
        .toList();
  }
}

/// Tüm savings listesi
final savingsProvider =
    StateNotifierProvider<SavingsNotifier, List<Saving>>((ref) {
  final repo = ref.watch(repositoryProvider);
  return SavingsNotifier(repo);
});

/// Seçilen timeframe'e göre kurtarılan TL miktarı
final totalSavedProvider = Provider<double>((ref) {
  final savings = ref.watch(savingsProvider);
  final timeframe = ref.watch(timeframeProvider);
  
  final now = DateTime.now();

  Iterable<Saving> filtered = savings;
  switch (timeframe) {
    case SavingsTimeframe.daily:
      filtered = savings.where((s) => s.savedAt.year == now.year && s.savedAt.month == now.month && s.savedAt.day == now.day);
      break;
    case SavingsTimeframe.weekly:
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfToday = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      filtered = savings.where((s) => s.savedAt.isAfter(startOfToday.subtract(const Duration(seconds: 1))));
      break;
    case SavingsTimeframe.monthly:
      filtered = savings.where((s) => s.savedAt.year == now.year && s.savedAt.month == now.month);
      break;
    case SavingsTimeframe.allTime:
      // no filter
      break;
  }

  return filtered.fold(0.0, (sum, s) => sum + s.amount);
});

/// Seçilen timeframe'e göre tasarruf adedi
final totalCountProvider = Provider<int>((ref) {
  final savings = ref.watch(savingsProvider);
  final timeframe = ref.watch(timeframeProvider);

  final now = DateTime.now();

  Iterable<Saving> filtered = savings;
  switch (timeframe) {
    case SavingsTimeframe.daily:
      filtered = savings.where((s) => s.savedAt.year == now.year && s.savedAt.month == now.month && s.savedAt.day == now.day);
      break;
    case SavingsTimeframe.weekly:
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfToday = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      filtered = savings.where((s) => s.savedAt.isAfter(startOfToday.subtract(const Duration(seconds: 1))));
      break;
    case SavingsTimeframe.monthly:
      filtered = savings.where((s) => s.savedAt.year == now.year && s.savedAt.month == now.month);
      break;
    case SavingsTimeframe.allTime:
      break;
  }

  return filtered.length;
});

/// Son N adet tasarruf (ana ekrandaki liste için)
final recentSavingsProvider = Provider.family<List<Saving>, int>((ref, count) {
  final all = ref.watch(savingsProvider);
  // Max 15 ile sınırla
  final limit = count > 15 ? 15 : count;
  return all.take(limit).toList();
});

/// Kategori bazlı toplam (istatistik için hazır)
final categoryTotalsProvider = Provider<Map<String, double>>((ref) {
  final savings = ref.watch(savingsProvider);
  final result = <String, double>{};
  for (final s in savings) {
    result[s.categoryId] = (result[s.categoryId] ?? 0) + s.amount;
  }
  return result;
});

/// Seçili kategori (AddSavingSheet için geçici state)
final selectedCategoryProvider =
    StateProvider<SavingCategory?>((ref) => null);
