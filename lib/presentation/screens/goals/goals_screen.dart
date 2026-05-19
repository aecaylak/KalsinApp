import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/currency_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/savings_provider.dart';
import '../add_saving/add_goal_sheet.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final allSavings = ref.watch(savingsProvider);
    final currency = ref.watch(currencyProvider);
    final goalsCount = goals.length;
    final sortedGoals = [...goals]..sort((a, b) => a.targetAmount.compareTo(b.targetAmount));
    final formatter = NumberFormat.currency(locale: 'tr_TR', symbol: currency.symbol, decimalDigits: 0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Hedeflerim'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showAddGoalSheet(context),
          ),
        ],
      ),
      body: goalsCount == 0
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    'Henüz bir hedefin yok.\nSağ üstten ekle!',
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppTheme.md),
              itemCount: goalsCount,
              itemBuilder: (context, index) {
                final goal = sortedGoals[index];

                // Hedefe özel tasarruflar
                final goalSpecific = allSavings
                    .where((s) => s.goalId == goal.id)
                    .fold(0.0, (sum, s) => sum + s.amount);
                // Genel tasarruflar (hedefe bağlanmamış)
                final generalTotal = allSavings
                    .where((s) => s.goalId == null || s.goalId!.isEmpty)
                    .fold(0.0, (sum, s) => sum + s.amount);
                // Toplam = hedefe özel + genel (başka hedefe bağlı olanlar sayılmaz)
                final effectiveTotal = goalSpecific + generalTotal;
                final progress = (effectiveTotal / goal.targetAmount).clamp(0.0, 1.0);

                return Dismissible(
                  key: Key(goal.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        title: const Text('Hedefi Sil'),
                        content: Text(
                            '"${goal.title}" hedefini silmek istediğine emin misin?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('İptal'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.danger),
                            child: const Text('Sil',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) {
                    ref.read(goalsProvider.notifier).deleteGoal(goal.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${goal.title}" silindi'),
                        backgroundColor: AppTheme.danger,
                      ),
                    );
                  },
                  background: Container(
                    margin: const EdgeInsets.only(bottom: AppTheme.md),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppTheme.md),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.danger, size: 28),
                  ),
                  child: GestureDetector(
                    onTap: () => showAddGoalSheet(context, existing: goal),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: AppTheme.md),
                      padding: const EdgeInsets.all(AppTheme.md),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.adaptiveBorder(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(goal.emoji,
                                  style: const TextStyle(fontSize: 28)),
                              const SizedBox(width: AppTheme.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      goal.title,
                                      style: AppTheme.headingMedium
                                          .copyWith(fontSize: 18),
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
                                  gradient: progress >= 1.0
                                      ? AppTheme.primaryGradient
                                      : AppTheme.accentGradient,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '%${(progress * 100).toStringAsFixed(1)}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: AppTheme.sm),
                              GestureDetector(
                                onTap: () => showAddGoalSheet(context, existing: goal),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.adaptiveGlass(context),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.adaptiveBorder(context)),
                                  ),
                                  child: Icon(Icons.edit_rounded,
                                      size: 16, color: Theme.of(context).textTheme.bodySmall?.color ?? AppTheme.textSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.md),
                          Stack(
                            children: [
                              Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppTheme.adaptiveGlass(context),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: progress,
                                child: Container(
                                  height: 12,
                                  decoration: BoxDecoration(
                                    gradient: progress >= 1.0
                                        ? AppTheme.primaryGradient
                                        : AppTheme.accentGradient,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  goalSpecific > 0
                                      ? '${formatter.format(goalSpecific)} özel + ${formatter.format(generalTotal)} genel'
                                      : '${formatter.format(generalTotal)} birikti (genel)',
                                  style: AppTheme.labelSmall.copyWith(
                                      color: goalSpecific > 0
                                          ? AppTheme.primary
                                          : AppTheme.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${formatter.format((goal.targetAmount - effectiveTotal).clamp(0, goal.targetAmount))} kaldı',
                                style: AppTheme.labelSmall,
                              ),
                            ],
                          ),
                          if (progress >= 1.0) ...[
                            const SizedBox(height: AppTheme.sm),
                            const Text('🎉 Bu hedefe ulaştın!',
                                style: TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
