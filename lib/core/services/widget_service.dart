import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../../domain/models/saving.dart';
import '../../domain/models/goal.dart';

/// Ana ekran widget'ına veri gönderen servis.
/// SharedPreferences ("HomeWidgetPreferences") üzerinden
/// Android AppWidget ile iletişim kurar.
class WidgetService {
  WidgetService._();
  static final WidgetService instance = WidgetService._();

  static const _androidWidgetName = 'KalsinWidgetProvider';

  final _formatter = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 0,
  );

  /// Tüm verileri widget'a yazar ve güncellemeyi tetikler.
  /// Herhangi bir hata sessizce yutulur — widget opsiyonel bir özellik.
  Future<void> updateWidget({
    required List<Saving> savings,
    required List<Goal> goals,
    required int streak,
  }) async {
    try {
      final now = DateTime.now();

      // Bu ayki birikim (uygulamanın varsayılan gösterimiyle tutarlı)
      final monthlyTotal = savings
          .where((s) => s.savedAt.year == now.year && s.savedAt.month == now.month)
          .fold(0.0, (sum, s) => sum + s.amount);

      // Bugünkü birikim
      final todayTotal = savings
          .where((s) =>
              s.savedAt.year == now.year &&
              s.savedAt.month == now.month &&
              s.savedAt.day == now.day)
          .fold(0.0, (sum, s) => sum + s.amount);

      // Aktif hedef (en küçük tutarlı)
      Goal? activeGoal;
      if (goals.isNotEmpty) {
        final sorted = [...goals]
          ..sort((a, b) => a.targetAmount.compareTo(b.targetAmount));
        activeGoal = sorted.first;
      }

      // Hedef ilerleme hesapla
      double goalProgress = 0;
      String goalTitle = 'Hedef belirle';
      String goalEmoji = '🎯';
      String goalPercent = '%0';

      if (activeGoal != null) {
        double effectiveTotal = 0;
        for (final s in savings) {
          if (s.goalId == activeGoal.id) {
            effectiveTotal += s.amount;
          } else if (s.goalId == null || s.goalId!.isEmpty) {
            effectiveTotal += s.amount;
          }
        }
        goalProgress = (effectiveTotal / activeGoal.targetAmount).clamp(0.0, 1.0);
        goalTitle = activeGoal.title;
        goalEmoji = activeGoal.emoji;
        goalPercent = '%${(goalProgress * 100).toStringAsFixed(0)}';
      }

      // Widget verilerini kaydet
      await Future.wait([
        HomeWidget.saveWidgetData<String>('total_amount', _formatter.format(monthlyTotal)),
        HomeWidget.saveWidgetData<String>('today_amount', 'Bugün: ${_formatter.format(todayTotal)}'),
        HomeWidget.saveWidgetData<String>('streak_text', '🔥 $streak gün'),
        HomeWidget.saveWidgetData<String>('goal_emoji', goalEmoji),
        HomeWidget.saveWidgetData<String>('goal_title', goalTitle),
        HomeWidget.saveWidgetData<String>('goal_percent', goalPercent),
        // Double'ı String olarak kaydet — Android'de Long/Float cast sorunu yaşanmasın
        HomeWidget.saveWidgetData<String>('goal_progress', goalProgress.toStringAsFixed(4)),
      ]);

      // Android widget'ı güncelle
      await HomeWidget.updateWidget(androidName: _androidWidgetName);
    } catch (e, stack) {
      // Widget güncellemesi başarısız olursa uygulamayı çökertme
      debugPrint('[WidgetService] updateWidget error: $e\n$stack');
    }
  }
}
