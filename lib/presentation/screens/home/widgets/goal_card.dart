import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../providers/currency_provider.dart';
import '../../../providers/goal_provider.dart';
import '../../../providers/savings_provider.dart';
import '../../add_saving/add_goal_sheet.dart';

/// Hedef kartları — PageView ile hedefler arasında kaydırılabilir.
class GoalCard extends ConsumerStatefulWidget {
  const GoalCard({super.key});

  @override
  ConsumerState<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends ConsumerState<GoalCard> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(goalsProvider);
    final allSavings = ref.watch(savingsProvider);
    final currency = ref.watch(currencyProvider);

    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: currency.symbol,
      decimalDigits: 0,
    );

    // Hedef yoksa "Hedef Ekle" kartı
    if (goals.isEmpty) {
      return _EmptyGoalCard(
        onTap: () => showAddGoalSheet(context),
      );
    }

    final sortedGoals = [...goals]..sort((a, b) => a.targetAmount.compareTo(b.targetAmount));

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            itemCount: sortedGoals.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            controller: PageController(viewportFraction: 1.0),
            itemBuilder: (context, index) {
              final goal = sortedGoals[index];
              // Hedefe özel tasarruflar
              final goalSavings = allSavings
                  .where((s) => s.goalId == goal.id)
                  .fold(0.0, (sum, s) => sum + s.amount);
              // Genel toplam (hedefe bağlanmamış)
              final generalTotal = allSavings
                  .where((s) => s.goalId == null || s.goalId!.isEmpty)
                  .fold(0.0, (sum, s) => sum + s.amount);
              final effectiveTotal = goalSavings + generalTotal;
              final progress = (effectiveTotal / goal.targetAmount).clamp(0.0, 1.0);
              final progressPct = (progress * 100).toStringAsFixed(1);

              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.md),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0x22A78BFA), Color(0x15EC4899)],
                      ),
                      border: Border.all(color: const Color(0x33A78BFA), width: 1.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Başlık
                        Row(
                          children: [
                            Text(goal.emoji, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: AppTheme.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Hedef: ${formatter.format(goal.targetAmount)}',
                                    style: AppTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: AppTheme.accentGradient,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '%$progressPct',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.md),

                        // Progress bar
                        _AnimatedProgressBar(progress: progress),
                        const SizedBox(height: AppTheme.sm),

                        // Kurtarılan / Kalan
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                goalSavings > 0
                                    ? '${formatter.format(goalSavings)} özel + ${formatter.format(generalTotal)} genel'
                                    : '${formatter.format(generalTotal)} birikti',
                                style: AppTheme.labelSmall.copyWith(
                                  color: AppTheme.primary,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${formatter.format((goal.targetAmount - effectiveTotal).clamp(0, goal.targetAmount))} kaldı',
                              style: AppTheme.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Sayfa göstergesi (dot indicator)
        if (sortedGoals.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(sortedGoals.length, (i) {
                final isActive = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.accent : AppTheme.accent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2);
  }
}

class _AnimatedProgressBar extends StatelessWidget {
  const _AnimatedProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Arka plan
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: AppTheme.adaptiveGlass(context),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Dolum animasyonu
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Container(
                  height: 10,
                  width: constraints.maxWidth * value,
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _EmptyGoalCard extends StatelessWidget {
  const _EmptyGoalCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.adaptiveBorder(context),
            width: 1.0,
          ),
          color: AppTheme.adaptiveGlass(context),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('🎯', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: AppTheme.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bir Hedef Belirle',
                    style: AppTheme.headingMedium.copyWith(fontSize: 16),
                  ),
                  Text(
                    'Ne için biriktiriyorsun?',
                    style: AppTheme.bodyMedium.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.add_circle_outline_rounded,
                color: AppTheme.accent, size: 24),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}
