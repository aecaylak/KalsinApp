import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'savings_provider.dart';

// ── Streak Provider ───────────────────────────────────────────────────────────

/// Arka arkaya "harcama kaydedilen" gün sayısını hesaplar.
/// Streak mantığı: Biz "no-spend" değil "tasarruf bilinci" uygulamasıyız;
/// bu yüzden streak = arka arkaya tasarruf kaydedilen gün sayısı.
/// Dün veya bugün kayıt yoksa streak sıfırlanır.
final streakProvider = Provider<int>((ref) {
  final savings = ref.watch(savingsProvider);
  if (savings.isEmpty) return 0;

  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);

  // Tarihleri benzersiz günlere indir ve sırala (en yeni başta)
  final savingDates = savings
      .map((s) => DateTime(s.savedAt.year, s.savedAt.month, s.savedAt.day))
      .toSet()
      .toList()
        ..sort((a, b) => b.compareTo(a));

  // En son kayıt bugün veya dün değilse streak = 0
  final latestDate = savingDates.first;
  final gap = todayDate.difference(latestDate).inDays;
  if (gap > 1) return 0;

  // Arka arkaya günleri say
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
});

/// Streak durumunu metinsel başarım rozeti olarak döner
final streakBadgeProvider = Provider<String>((ref) {
  final streak = ref.watch(streakProvider);
  if (streak == 0) return 'Başla! 🌱';
  if (streak < 3) return 'Harika! 🔥';
  if (streak < 7) return 'Süper! 💪';
  if (streak < 14) return 'Efsane! ⚡';
  return 'Unstoppable! 🏆';
});
