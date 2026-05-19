import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/category.dart';
import '../../../domain/models/goal.dart';
import '../../../domain/models/saving.dart';
import '../../providers/currency_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/savings_provider.dart';

/// Harcama ekleme/düzenleme bottom sheet.
void showAddSavingSheet(BuildContext context, {Saving? existing}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddSavingSheet(existing: existing),
  );
}

class AddSavingSheet extends ConsumerStatefulWidget {
  const AddSavingSheet({super.key, this.existing});
  final Saving? existing;

  @override
  ConsumerState<AddSavingSheet> createState() => _AddSavingSheetState();
}

class _AddSavingSheetState extends ConsumerState<AddSavingSheet>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late AnimationController _successController;
  late ConfettiController _confettiController;
  bool _showSuccess = false;
  DateTime? _selectedDate;
  Goal? _selectedGoal;
  double _keyboardHeight = 0;

  bool get _isEditing => widget.existing != null;

  @override
  void didChangeMetrics() {
    final bottom = WidgetsBinding.instance.platformDispatcher.views.first.viewInsets.bottom /
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    if (!mounted) return;
    setState(() => _keyboardHeight = bottom);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    if (_isEditing) {
      final e = widget.existing!;
      _amountController.text = e.amount.toStringAsFixed(e.amount == e.amount.roundToDouble() ? 0 : 2);
      _noteController.text = e.note ?? '';
      _selectedDate = e.savedAt;
      // Set category in next frame so provider is available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final cat = AppCategories.findById(e.categoryId);
        ref.read(selectedCategoryProvider.notifier).state = cat;
        // Set goal if exists
        if (e.goalId != null) {
          final goals = ref.read(goalsProvider);
          final match = goals.where((g) => g.id == e.goalId);
          if (match.isNotEmpty) {
            setState(() => _selectedGoal = match.first);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _amountController.dispose();
    _noteController.dispose();
    _successController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final selectedCategory = ref.read(selectedCategoryProvider);
    final amountText = _amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    if (selectedCategory == null || amount == null || amount <= 0) {
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.lightImpact();

    if (_isEditing) {
      final updated = widget.existing!.copyWith(
        amount: amount,
        categoryId: selectedCategory.id,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        savedAt: _selectedDate ?? widget.existing!.savedAt,
        goalId: _selectedGoal?.id,
      );
      await ref.read(savingsProvider.notifier).updateSaving(updated);
    } else {
      await ref.read(savingsProvider.notifier).addSaving(
            amount: amount,
            categoryId: selectedCategory.id,
            note: _noteController.text.isEmpty ? null : _noteController.text,
            date: _selectedDate,
            goalId: _selectedGoal?.id,
          );
    }

    setState(() => _showSuccess = true);
    _confettiController.play();
    await _successController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      ref.read(selectedCategoryProvider.notifier).state = null;
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final goals = ref.watch(goalsProvider);
    final currency = ref.watch(currencyProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppTheme.adaptiveBorder(context), width: 1),
          left: BorderSide(color: AppTheme.adaptiveBorder(context), width: 1),
          right: BorderSide(color: AppTheme.adaptiveBorder(context), width: 1),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            AppTheme.lg, AppTheme.lg, AppTheme.lg, AppTheme.lg + _keyboardHeight),
        physics: const BouncingScrollPhysics(),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle çubuğu
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.md),

          Row(
            children: [
              Text(_isEditing ? '✏️' : '💚', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: AppTheme.sm),
              Text(_isEditing ? 'Tasarrufu Düzenle' : 'Ne Kurtardın?', style: AppTheme.headingMedium),
            ],
          ),
          const SizedBox(height: AppTheme.md),

          // Kategori seçim
          Text('Kategori', style: AppTheme.labelSmall.copyWith(letterSpacing: 1)),
          const SizedBox(height: AppTheme.sm),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AppCategories.all.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppTheme.sm),
              itemBuilder: (context, i) {
                final cat = AppCategories.all[i];
                final isSelected = selectedCategory?.id == cat.id;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(selectedCategoryProvider.notifier).state = cat;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 70,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cat.color.withValues(alpha: 0.25)
                          : AppTheme.adaptiveGlass(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? cat.color : AppTheme.adaptiveBorder(context),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(cat.emoji, style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 9,
                            color: isSelected ? cat.color : AppTheme.textSecondary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  )
                      .animate(delay: Duration(milliseconds: i * 40))
                      .fadeIn()
                      .scaleXY(begin: 0.85),
                );
              },
            ),
          ),
          const SizedBox(height: AppTheme.md),

          // Tutar girişi
          Text('Ne Kadar Kurtardın? (${currency.symbol})', style: AppTheme.labelSmall.copyWith(letterSpacing: 1)),
          const SizedBox(height: AppTheme.sm),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.primary,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 28, fontWeight: FontWeight.w800),
              prefixText: '${currency.symbol} ',
              prefixStyle: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.primary),
              filled: true,
              fillColor: AppTheme.adaptiveGlass(context),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.adaptiveBorder(context))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.adaptiveBorder(context))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
            ),
          ),
          const SizedBox(height: AppTheme.sm),

          // Not alanı
          TextField(
            controller: _noteController,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            decoration: InputDecoration(
              hintText: 'Neden vazgeçtin? (isteğe bağlı)',
              hintStyle: AppTheme.bodyMedium,
              filled: true,
              fillColor: AppTheme.adaptiveGlass(context),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.adaptiveBorder(context))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.adaptiveBorder(context))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.accent, width: 1.5)),
            ),
          ),
          const SizedBox(height: AppTheme.sm),

          // Hedefe bağla (hedef varsa göster)
          if (goals.isNotEmpty) ...[
            Text('Hedefe Bağla (isteğe bağlı)',
                style: AppTheme.labelSmall.copyWith(letterSpacing: 1)),
            const SizedBox(height: AppTheme.sm),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _selectedGoal = null),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: _selectedGoal == null
                            ? AppTheme.adaptiveGlass(context)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _selectedGoal == null
                              ? AppTheme.primary
                              : AppTheme.adaptiveBorder(context),
                        ),
                      ),
                      child: Center(
                        child: Text('Genel',
                            style: TextStyle(
                              fontSize: 13,
                              color: _selectedGoal == null
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                              fontWeight: _selectedGoal == null
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            )),
                      ),
                    ),
                  ),
                  ...goals.map((goal) {
                    final isSelected = _selectedGoal?.id == goal.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedGoal = goal),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.accent.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected ? AppTheme.accent : AppTheme.adaptiveBorder(context),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(goal.emoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(goal.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected
                                      ? AppTheme.accent
                                      : AppTheme.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                )),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.sm),
          ],

          // Tarih seçimi
          GestureDetector(
            onTap: _pickDate,
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 20, color: AppTheme.accent),
                const SizedBox(width: 8),
                Text(
                  _selectedDate == null
                      ? 'Tarih Seç (Opsiyonel)'
                      : DateFormat('dd MMM yyyy', 'tr_TR').format(_selectedDate!),
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.accent),
                ),
                if (_selectedDate != null) ...[
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20, color: AppTheme.textMuted),
                    onPressed: () => setState(() => _selectedDate = null),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppTheme.lg),

          // CTA Butonu
          SizedBox(
            width: double.infinity,
            height: 56,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                gradient: _showSuccess
                    ? const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF16A34A)])
                    : AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _showSuccess ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _showSuccess
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🎉', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(_isEditing ? 'Güncellendi!' : 'Harika! Kurtardın!',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_isEditing ? '✏️' : '💚', style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(_isEditing ? 'Güncelle' : 'Kalsın!',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0D1117))),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
        ),
        // Konfeti — şeetin üstünde görünür
        if (_showSuccess)
          Positioned(
            top: -50,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 30,
                colors: const [
                  AppTheme.primary,
                  AppTheme.accent,
                  Color(0xFFFBBF24),
                  Colors.white,
                ],
                shouldLoop: false,
              ),
            ),
          ),
      ],
    );
  }
}
