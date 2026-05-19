import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/currency_provider.dart';
import '../../providers/goal_provider.dart';
import '../../../domain/models/goal.dart';

/// Hedef ekleme / düzenleme bottom sheet.
/// [existing] verilirse düzenleme modu, null ise ekleme modu.
void showAddGoalSheet(BuildContext context, {Goal? existing}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddGoalSheet(existing: existing),
  );
}

class AddGoalSheet extends ConsumerStatefulWidget {
  const AddGoalSheet({super.key, this.existing});
  final Goal? existing;

  @override
  ConsumerState<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<AddGoalSheet>
    with WidgetsBindingObserver {
  final _amountController = TextEditingController();
  final _customTitleController = TextEditingController();
  String? _selectedTitle;
  String? _selectedEmoji;
  bool _isOtherSelected = false;
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
    if (_isEditing) {
      final g = widget.existing!;
      _selectedTitle = g.title;
      _selectedEmoji = g.emoji;
      _amountController.text = g.targetAmount.toStringAsFixed(0);
      // Preset listesinde var mı?
      final match = GoalPresets.suggestions
          .any((p) => p['title'] == g.title && p['title'] != 'Diğer');
      if (!match) {
        _isOtherSelected = true;
        _customTitleController.text = g.title;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _amountController.dispose();
    _customTitleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _isOtherSelected
        ? _customTitleController.text.trim()
        : _selectedTitle;
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.'));

    if (title == null || title.isEmpty || amount == null || amount <= 0) {
      HapticFeedback.heavyImpact();
      return;
    }

    if (_isEditing) {
      final updated = widget.existing!.copyWith(
        title: title,
        targetAmount: amount,
        emoji: _selectedEmoji ?? widget.existing!.emoji,
      );
      await ref.read(goalsProvider.notifier).deleteGoal(widget.existing!.id);
      await ref.read(goalsProvider.notifier).addGoal(updated);
    } else {
      final newGoal = Goal(
        id: const Uuid().v4(),
        title: title,
        targetAmount: amount,
        emoji: _selectedEmoji ?? '🎯',
      );
      await ref.read(goalsProvider.notifier).addGoal(newGoal);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppTheme.adaptiveBorder(context)),
          left: BorderSide(color: AppTheme.adaptiveBorder(context)),
          right: BorderSide(color: AppTheme.adaptiveBorder(context)),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          AppTheme.lg, AppTheme.lg, AppTheme.lg, AppTheme.lg + _keyboardHeight),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.textMuted,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: AppTheme.md),
            Row(children: [
              const Text('🎯', style: TextStyle(fontSize: 24)),
              const SizedBox(width: AppTheme.sm),
              Text(_isEditing ? 'Hedefi Düzenle' : 'Hedef Belirle',
                  style: AppTheme.headingMedium),
            ]),
            const SizedBox(height: AppTheme.md),

            // Preset önerileri
            Text('Ne için biriktiriyorsun?',
                style: AppTheme.labelSmall.copyWith(letterSpacing: 1)),
            const SizedBox(height: AppTheme.sm),
            Wrap(
              spacing: AppTheme.sm,
              runSpacing: AppTheme.sm,
              children: GoalPresets.suggestions.map((preset) {
                final isSelected = !_isOtherSelected &&
                    _selectedTitle == preset['title'];
                final isOtherPreset = preset['title'] == 'Diğer';
                final isOtherActive = isOtherPreset && _isOtherSelected;
                final highlighted = isSelected || isOtherActive;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _isOtherSelected = isOtherPreset;
                      _selectedTitle = preset['title'] as String;
                      _selectedEmoji = preset['emoji'] as String;
                      if (!_isOtherSelected) {
                        _amountController.text =
                            (preset['amount'] as double).toStringAsFixed(0);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: highlighted
                          ? AppTheme.accent.withValues(alpha: 0.2)
                          : AppTheme.adaptiveGlass(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: highlighted
                            ? AppTheme.accent
                            : AppTheme.adaptiveBorder(context),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(preset['emoji'] as String),
                        const SizedBox(width: 6),
                        Text(
                          preset['title'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: highlighted
                                ? AppTheme.accent
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.md),

            // Özel başlık (Diğer seçildiyse)
            if (_isOtherSelected) ...[
              Text('Hedefin nedir?',
                  style: AppTheme.labelSmall.copyWith(letterSpacing: 1)),
              const SizedBox(height: AppTheme.sm),
              TextField(
                controller: _customTitleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Örn: Kitap Seti',
                  hintStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.adaptiveGlass(context),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          BorderSide(color: AppTheme.adaptiveBorder(context))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          BorderSide(color: AppTheme.adaptiveBorder(context))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                          color: AppTheme.accent, width: 1.5)),
                ),
              ),
              const SizedBox(height: AppTheme.md),
            ],

            // Hedef tutarı
            Text('Hedef Tutar (${currency.symbol})',
                style: AppTheme.labelSmall.copyWith(letterSpacing: 1)),
            const SizedBox(height: AppTheme.sm),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.accent,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 24,
                    fontWeight: FontWeight.w800),
                prefixText: '${currency.symbol} ',
                prefixStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accent),
                filled: true,
                fillColor: AppTheme.adaptiveGlass(context),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        BorderSide(color: AppTheme.adaptiveBorder(context))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        BorderSide(color: AppTheme.adaptiveBorder(context))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                        color: AppTheme.accent, width: 1.5)),
              ),
            ),
            const SizedBox(height: AppTheme.lg),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _isEditing ? 'Güncelle 🎯' : 'Hedefi Kaydet 🎯',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
