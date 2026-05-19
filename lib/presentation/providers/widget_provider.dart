import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/widget_service.dart';
import 'savings_provider.dart';
import 'goal_provider.dart';
import 'streak_provider.dart';

/// Savings, goals veya streak değiştiğinde ana ekran widget'ını günceller.
/// Bu provider'ı app root'ta watch ederek canlı tutuluyor.
final widgetUpdateProvider = Provider<void>((ref) {
  final savings = ref.watch(savingsProvider);
  final goals = ref.watch(goalsProvider);
  final streak = ref.watch(streakProvider);

  // Widget verilerini güncelle (async, sonucu beklemeye gerek yok)
  WidgetService.instance.updateWidget(
    savings: savings,
    goals: goals,
    streak: streak,
  );
});
