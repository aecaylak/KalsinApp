import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/category.dart';
import '../../providers/currency_provider.dart';
import '../../providers/savings_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savings = ref.watch(savingsProvider);
    final categoryTotals = ref.watch(categoryTotalsProvider);
    final currency = ref.watch(currencyProvider);
    final formatter = NumberFormat.currency(locale: 'tr_TR', symbol: currency.symbol, decimalDigits: 0);

    // Son 7 günün günlük toplamları
    final now = DateTime.now();
    final weeklyData = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final total = savings
          .where((s) =>
              s.savedAt.year == day.year &&
              s.savedAt.month == day.month &&
              s.savedAt.day == day.day)
          .fold(0.0, (sum, s) => sum + s.amount);
      return _DayData(day: day, total: total);
    });

    final weekMax = weeklyData.map((d) => d.total).reduce((a, b) => a > b ? a : b);

    // Kategori sıralaması (büyükten küçüğe)
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalAll = categoryTotals.values.fold(0.0, (a, b) => a + b);

    // Bu ayın tasarrufu
    final thisMonth = savings
        .where((s) => s.savedAt.year == now.year && s.savedAt.month == now.month)
        .fold(0.0, (sum, s) => sum + s.amount);

    // Bu haftanın tasarrufu
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final thisWeek = savings
        .where((s) => s.savedAt.isAfter(
            DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day)
                .subtract(const Duration(seconds: 1))))
        .fold(0.0, (sum, s) => sum + s.amount);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('İstatistikler 📊'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: savings.isEmpty
          ? Center(
              child: Text('Henüz veri yok.\nİlk tasarrufunu ekle!',
                  textAlign: TextAlign.center, style: AppTheme.bodyMedium),
            )
          : ListView(
              padding: const EdgeInsets.all(AppTheme.md),
              children: [
                // ── Özet kartlar ──────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Bu Hafta',
                        value: formatter.format(thisWeek),
                        emoji: '📅',
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
                    ),
                    const SizedBox(width: AppTheme.sm),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Bu Ay',
                        value: formatter.format(thisMonth),
                        emoji: '🗓',
                      ).animate(delay: 80.ms).fadeIn(duration: 400.ms).slideY(begin: -0.1),
                    ),
                    const SizedBox(width: AppTheme.sm),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Toplam',
                        value: formatter.format(totalAll),
                        emoji: '💰',
                      ).animate(delay: 160.ms).fadeIn(duration: 400.ms).slideY(begin: -0.1),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.lg),

                // ── Haftalık bar chart ─────────────────────────────────
                Text('Son 7 Gün', style: AppTheme.headingMedium),
                const SizedBox(height: AppTheme.md),
                Container(
                  padding: const EdgeInsets.all(AppTheme.md),
                  decoration: AppTheme.adaptiveCardDecoration(context),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 140,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: weeklyData.asMap().entries.map((entry) {
                            final i = entry.key;
                            final d = entry.value;
                            final barHeight = weekMax > 0 ? (d.total / weekMax) * 110 : 4.0;
                            final isToday = d.day.day == now.day &&
                                d.day.month == now.month;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (d.total > 0)
                                      Text(
                                        formatter.format(d.total),
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: isToday
                                              ? AppTheme.primary
                                              : AppTheme.textSecondary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    const SizedBox(height: 2),
                                    TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0, end: barHeight.clamp(4.0, 110.0)),
                                      duration: Duration(milliseconds: 600 + i * 80),
                                      curve: Curves.easeOutCubic,
                                      builder: (context, h, _) => Container(
                                        height: h,
                                        decoration: BoxDecoration(
                                          gradient: isToday
                                              ? AppTheme.primaryGradient
                                              : AppTheme.accentGradient,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: weeklyData.map((d) {
                          final isToday = d.day.day == now.day && d.day.month == now.month;
                          return Expanded(
                            child: Text(
                              DateFormat('E', 'tr_TR').format(d.day),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                color: isToday ? AppTheme.primary : AppTheme.textSecondary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: AppTheme.lg),

                // ── Kategori dağılımı ─────────────────────────────────
                Text('Kategori Dağılımı', style: AppTheme.headingMedium),
                const SizedBox(height: AppTheme.md),
                if (sortedCategories.isEmpty)
                  Text('Veri yok', style: AppTheme.bodyMedium)
                else
                  ...sortedCategories.asMap().entries.map((entry) {
                    final i = entry.key;
                    final catId = entry.value.key;
                    final amount = entry.value.value;
                    final cat = AppCategories.findById(catId);
                    final pct = totalAll > 0 ? amount / totalAll : 0.0;
                    return _CategoryBar(
                      category: cat,
                      amount: amount,
                      percent: pct,
                      formatter: formatter,
                      animDelay: 300 + i * 60,
                    );
                  }),
              ],
            ),
    );
  }
}

class _DayData {
  final DateTime day;
  final double total;
  const _DayData({required this.day, required this.total});
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, required this.emoji});
  final String label;
  final String value;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: AppTheme.adaptiveCardDecoration(context, radius: 16),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
              textAlign: TextAlign.center),
          Text(label, style: AppTheme.labelSmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.category,
    required this.amount,
    required this.percent,
    required this.formatter,
    required this.animDelay,
  });
  final SavingCategory category;
  final double amount;
  final double percent;
  final NumberFormat formatter;
  final int animDelay;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.sm),
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: AppTheme.adaptiveCardDecoration(context, radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(category.emoji, style: const TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: AppTheme.sm),
              Expanded(
                child: Text(category.name,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
              ),
              Text(formatter.format(amount),
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: category.color)),
              const SizedBox(width: 6),
              Text('${(percent * 100).toStringAsFixed(0)}%',
                  style: AppTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, constraints) {
            return Stack(children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.adaptiveGlass(context),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: percent),
                duration: Duration(milliseconds: animDelay + 300),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Container(
                  height: 6,
                  width: constraints.maxWidth * v,
                  decoration: BoxDecoration(
                    color: category.color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ]);
          }),
        ],
      ),
    ).animate(delay: Duration(milliseconds: animDelay)).fadeIn(duration: 350.ms).slideX(begin: 0.1);
  }
}
