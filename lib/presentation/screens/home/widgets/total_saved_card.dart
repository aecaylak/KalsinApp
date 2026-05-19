import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../providers/currency_provider.dart';
import '../../../providers/savings_provider.dart';

/// Animasyonlu toplam tasarruf sayacı — ana ekranın kalbi.
/// Glassmorphism kart içinde büyük TL tutarını gösterir.
class TotalSavedCard extends ConsumerStatefulWidget {
  const TotalSavedCard({super.key});

  @override
  ConsumerState<TotalSavedCard> createState() => _TotalSavedCardState();
}

class _TotalSavedCardState extends ConsumerState<TotalSavedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _repaintKey = GlobalKey();
  late Animation<double> _valueAnimation;
  double _previousTotal = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double newValue) {
    _valueAnimation = Tween<double>(
      begin: _previousTotal,
      end: newValue,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward(from: 0);
    _previousTotal = newValue;
  }

  @override
  Widget build(BuildContext context) {
    final total = ref.watch(totalSavedProvider);
    final count = ref.watch(totalCountProvider);
    final timeframe = ref.watch(timeframeProvider);
    final currency = ref.watch(currencyProvider);

    // Değer değiştiğinde animasyonu başlat
    if (total != _previousTotal) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _animateTo(total));
    }

    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: currency.symbol,
      decimalDigits: 2,
    );

    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy', 'tr_TR').format(now);

    return RepaintBoundary(
      key: _repaintKey,
      child: ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: Theme.of(context).brightness == Brightness.dark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0x2A4ADE80), // yeşil cam
                      Color(0x1422D3EE), // cyan cam
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0x204ADE80),
                      Color(0x1522D3EE),
                    ],
                  ),
            border: Border.all(color: AppTheme.adaptiveBorder(context), width: 1.2),
            boxShadow: Theme.of(context).brightness == Brightness.light
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst etiket
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      ref.read(timeframeProvider.notifier).update((state) => state.next);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('💚', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            timeframe.label,
                            style: AppTheme.labelSmall.copyWith(
                              color: AppTheme.primary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        monthName,
                        style: AppTheme.labelSmall,
                      ),
                      Text(
                        '$count tasarruf',
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.primary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.md),

              // Animasyonlu TL sayacı
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final displayValue = _controller.isAnimating
                      ? _valueAnimation.value
                      : total;
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatter.format(displayValue),
                      style: AppTheme.displayLarge.copyWith(
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [Color(0xFF4ADE80), Color(0xFF22D3EE)],
                          ).createShader(
                              const Rect.fromLTWH(0, 0, 300, 80)),
                      ),
                    ),
                  );
                },
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3),

              const SizedBox(height: AppTheme.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Harika gidiyorsun! Böyle devam et 🎯',
                    style: AppTheme.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: () => ShareService.instance.shareWidget(
                      _repaintKey,
                      'KalsınApp — Tasarruf Özeti',
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.share_rounded,
                          color: AppTheme.primary, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),  // ClipRRect
    );  // RepaintBoundary
  }
}

