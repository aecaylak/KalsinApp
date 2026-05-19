import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/currency_provider.dart';
import '../../providers/savings_provider.dart';
import '../../../domain/models/category.dart';
import '../stats/stats_screen.dart';
import '../add_saving/add_saving_sheet.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTimeRange? _dateRange;
  String? _selectedCategoryId; // null = Tümü

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final savings = ref.watch(savingsProvider);

    // Apply filter
    var filteredSavings = savings;

    // Category filter
    if (_selectedCategoryId != null) {
      filteredSavings = filteredSavings.where((s) => s.categoryId == _selectedCategoryId).toList();
    }

    // Date range filter
    if (_dateRange != null) {
      filteredSavings = filteredSavings.where((s) {
        final d = s.savedAt;
        return d.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
               d.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    final currency = ref.watch(currencyProvider);
    final formatter = NumberFormat.currency(locale: 'tr_TR', symbol: currency.symbol);
    final totalFiltered = filteredSavings.fold(0.0, (sum, s) => sum + s.amount);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Kalanlar (Geçmiş)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'İstatistikler',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _pickDateRange,
          ),
          if (_dateRange != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _dateRange = null),
            ),
        ],
      ),
      body: Column(
        children: [
          // Kategori Filtresi (Slideable)
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.md),
              children: [
                _buildCategoryChip(null, 'Tümü', '🌍'),
                ...AppCategories.all.map((c) => _buildCategoryChip(c.id, c.name, c.emoji)),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.sm),
          if (_dateRange != null)
            Container(
              padding: const EdgeInsets.all(AppTheme.md),
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.md),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range, color: AppTheme.primary),
                  const SizedBox(width: AppTheme.sm),
                  Text(
                    '${DateFormat('dd MMM', 'tr_TR').format(_dateRange!.start)} - ${DateFormat('dd MMM yyyy', 'tr_TR').format(_dateRange!.end)}\nToplam: ${formatter.format(totalFiltered)}',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          Expanded(
            child: filteredSavings.isEmpty
                ? Center(
                    child: Text('Bu aralıkta kayıt yok.', style: AppTheme.bodyMedium),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.md),
                    itemCount: filteredSavings.length,
                    itemBuilder: (context, index) {
                      final item = filteredSavings[index];
                      final cat = AppCategories.findById(item.categoryId);
                      final dateStr = DateFormat('dd MMM yyyy HH:mm', 'tr_TR').format(item.savedAt);

                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Theme.of(context).colorScheme.surface,
                              title: const Text('Tasarrufu Sil'),
                              content: Text(
                                  '${formatter.format(item.amount)} tutarındaki tasarrufu silmek istediğine emin misin?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('İptal'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                                  child: const Text('Sil', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) {
                          ref.read(savingsProvider.notifier).deleteSaving(item.id);
                        },
                        background: Container(
                          margin: const EdgeInsets.only(bottom: AppTheme.sm),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: AppTheme.md),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: AppTheme.danger, size: 24),
                        ),
                        child: GestureDetector(
                          onTap: () => showAddSavingSheet(context, existing: item),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: AppTheme.sm),
                            padding: const EdgeInsets.all(AppTheme.md),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.adaptiveBorder(context), width: 0.8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: cat.color.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(cat.emoji, style: const TextStyle(fontSize: 20)),
                                ),
                                const SizedBox(width: AppTheme.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat.name,
                                        style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      if (item.note != null && item.note!.isNotEmpty)
                                        Text(
                                          item.note!,
                                          style: AppTheme.bodyMedium,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      Text(
                                        dateStr,
                                        style: AppTheme.labelSmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '+${formatter.format(item.amount)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String? id, String name, String emoji) {
    final isSelected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = id),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.adaptiveGlass(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.adaptiveBorder(context)),
        ),
        child: Row(
          children: [
            Text(emoji),
            const SizedBox(width: 4),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
