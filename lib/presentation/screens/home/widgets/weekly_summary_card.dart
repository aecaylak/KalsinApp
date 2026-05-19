import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../providers/currency_provider.dart';
import '../../../providers/goal_provider.dart';
import '../../../providers/savings_provider.dart';
import '../../../providers/streak_provider.dart';

class WeeklySummaryCard extends ConsumerWidget {
  const WeeklySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savings = ref.watch(savingsProvider);
    final goals = ref.watch(goalsProvider);
    final streak = ref.watch(streakProvider);
    final streakBadge = ref.watch(streakBadgeProvider);
    final currency = ref.watch(currencyProvider);
    final formatter = NumberFormat.currency(locale: 'tr_TR', symbol: currency.symbol, decimalDigits: 0);

    final now = DateTime.now();

    // Bu hafta
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final thisWeekSavings = savings.where((s) => s.savedAt.isAfter(
        startOfWeek.subtract(const Duration(seconds: 1))));
    final thisWeekTotal = thisWeekSavings.fold(0.0, (sum, s) => sum + s.amount);
    final thisWeekCount = thisWeekSavings.length;

    // Geçen hafta
    final lastWeekStart = startOfWeek.subtract(const Duration(days: 7));
    final lastWeekEnd = startOfWeek.subtract(const Duration(seconds: 1));
    final lastWeekTotal = savings
        .where((s) => s.savedAt.isAfter(lastWeekStart) && s.savedAt.isBefore(lastWeekEnd))
        .fold(0.0, (sum, s) => sum + s.amount);

    final isUp = thisWeekTotal >= lastWeekTotal;
    final diff = (thisWeekTotal - lastWeekTotal).abs();

    // Metinsel çıkarımlar (insights)
    final List<String> insights = [];

    // Hedefe ulaşma tahmini
    for (final goal in goals) {
      final allTimeTotal = savings.fold(0.0, (sum, s) => sum + s.amount);
      // Hedefe özel tasarruflar
      final goalSpecific = savings
          .where((s) => s.goalId == goal.id)
          .fold(0.0, (sum, s) => sum + s.amount);
      final effectiveTotal = goalSpecific > 0 ? goalSpecific : allTimeTotal;
      final remaining = (goal.targetAmount - effectiveTotal).clamp(0.0, double.infinity);

      if (remaining <= 0) {
        insights.add('🎉 "${goal.title}" hedefine ulaştın!');
      } else if (thisWeekTotal > 0) {
        final fourWeeksAgo = startOfWeek.subtract(const Duration(days: 28));
        final recentTotal = savings
            .where((s) => s.savedAt.isAfter(fourWeeksAgo))
            .fold(0.0, (sum, s) => sum + s.amount);
        final weeklyAvg = recentTotal / 4;
        if (weeklyAvg > 0) {
          final weeksLeft = (remaining / weeklyAvg).ceil();
          if (weeksLeft <= 52) {
            if (weeksLeft == 1) {
              insights.add('🎯 "${goal.title}" hedefine bu hafta ulaşabilirsin!');
            } else {
              insights.add('⏱️ "${goal.title}" hedefine ~$weeksLeft haftada ulaşırsın');
            }
          }
        }
      }
    }

    // Haftalık karşılaştırma insight
    if (lastWeekTotal > 0 && thisWeekTotal > 0) {
      if (thisWeekTotal > lastWeekTotal * 1.5) {
        insights.add('📈 Bu hafta geçen haftaya göre çok daha iyi gidiyorsun!');
      } else if (thisWeekTotal < lastWeekTotal * 0.5) {
        insights.add('💪 Geçen hafta daha iyiydin, biraz daha çabalayabilirsin!');
      }
    }

    // Streak insight
    if (streak >= 7) {
      insights.add('🏆 $streak günlük seri! Muhteşem gidiyorsun!');
    } else if (streak >= 3) {
      insights.add('⚡ $streak günlük seri! Devam et!');
    }

    if (thisWeekCount == 0 && insights.isEmpty && streak == 0) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? null : Theme.of(context).colorScheme.surface,
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x20A78BFA), Color(0x10EC4899)],
              )
            : null,
        border: Border.all(color: isDark ? const Color(0x30A78BFA) : AppTheme.lightGlassBorder),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst satır: Bu Hafta başlığı + streak + trend
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('Bu Hafta', style: AppTheme.headingMedium.copyWith(fontSize: 16)),
              const Spacer(),
              // Streak rozeti
              if (streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentWarm.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentWarm.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(streak > 0 ? '🔥' : '🌱', style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 3),
                      Text(
                        '$streak gün $streakBadge',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentWarm,
                        ),
                      ),
                    ],
                  ),
                ),
              if (streak > 0 && lastWeekTotal > 0) const SizedBox(width: 6),
              // Trend
              if (lastWeekTotal > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isUp
                        ? AppTheme.primary.withValues(alpha: 0.15)
                        : AppTheme.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: isUp ? AppTheme.primary : AppTheme.danger,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        formatter.format(diff),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isUp ? AppTheme.primary : AppTheme.danger,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                formatter.format(thisWeekTotal),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$thisWeekCount tasarruf',
                style: AppTheme.labelSmall,
              ),
            ],
          ),
          // Insights
          if (insights.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...insights.take(3).map((text) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )),
          ],
        ],
      ),
    )
        .animate(delay: 150.ms)
        .fadeIn(duration: 500.ms)
        .slideX(begin: -0.1);
  }
}
