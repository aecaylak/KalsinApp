import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../providers/streak_provider.dart';

/// Arka arkaya tasarruf günü sayacı — streak widget.
/// Ateş emojisi ve motivasyonel rozet ile gamification hissi verir.
class StreakWidget extends ConsumerWidget {
  const StreakWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final badge = ref.watch(streakBadgeProvider);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.md, vertical: AppTheme.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x28FBBF24), Color(0x18F97316)],
            ),
            border: Border.all(
              color: const Color(0x35FBBF24),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              // Ateş effect
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Text(
                  streak > 0 ? '🔥' : '🌱',
                  style: const TextStyle(fontSize: 36),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(end: 1.05, duration: 1200.ms,
                        curve: Curves.easeInOut),
              ),
              const SizedBox(width: AppTheme.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$streak Günlük Seri',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accentWarm,
                      ),
                    ),
                    Text(
                      badge,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.accentWarm.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Mini streak flames
              Row(
                children: List.generate(
                  streak.clamp(0, 5),
                  (i) => Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      '🔥',
                      style: TextStyle(fontSize: 10 + (i * 1.5)),
                    )
                        .animate(delay: Duration(milliseconds: i * 100))
                        .fadeIn()
                        .scaleXY(begin: 0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
