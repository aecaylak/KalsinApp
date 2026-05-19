import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/user_profile.dart';
import '../add_saving/add_saving_sheet.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_provider.dart';
import '../history/history_screen.dart';
import '../goals/goals_screen.dart';
import 'widgets/goal_card.dart';
import 'widgets/trainer_overlay.dart';
import 'widgets/savings_list.dart';
import 'widgets/total_saved_card.dart';

/// KalsınApp'in ana ekranı.
/// Gradient arka plan üzerinde Glassmorphism kartlar ve animasyonlu UI.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final showTrainer = user != null && !user.hasSeenTrainer;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Widget homeScaffold = AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? Colors.transparent : Theme.of(context).scaffoldBackgroundColor,
        extendBodyBehindAppBar: isDark,
        body: Stack(
          children: [
            if (isDark) const _BackgroundGradient(),
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildAppBar(context, ref),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.md),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: AppTheme.sm),
                        const TotalSavedCard()
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: -0.15, curve: Curves.easeOut),
                        const SizedBox(height: AppTheme.md),
                        const GoalCard()
                            .animate(delay: 200.ms)
                            .fadeIn(duration: 500.ms)
                            .slideX(begin: 0.1),
                        const SizedBox(height: AppTheme.lg),
                        const SavedList()
                            .animate(delay: 300.ms)
                            .fadeIn(duration: 500.ms),
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SideMenuBtn(
                icon: '💰',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                },
              ),
              _KalsinFAB(
                onPressed: () => showAddSavingSheet(context),
              ),
              _SideMenuBtn(
                icon: '🎯',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalsScreen()));
                },
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );

    if (showTrainer) {
      return Stack(
        children: [
          homeScaffold,
          TrainerOverlay(
            onFinish: () {
              ref.read(userProvider.notifier).markTrainerAsSeen();
            },
          ),
        ],
      );
    }

    return homeScaffold;
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final greetingName = user?.name ?? 'Sen';
    final emoji = user?.avatarEmoji ?? '🧑';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.lg, AppTheme.sm, AppTheme.lg, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KalsınApp, $greetingName',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  foreground: Paint()
                    ..shader = AppTheme.primaryGradient.createShader(
                      const Rect.fromLTWH(0, 0, 150, 40),
                    ),
                ),
              ).animate().fadeIn(duration: 600.ms),
              Text(
                'Ne kazandın bugün? 💸',
                style: AppTheme.bodyMedium.copyWith(fontSize: 13),
              ),
            ],
          ),
          const Spacer(),
          // Avatar / profil alanı - EDITABLE
          GestureDetector(
            onTap: () => _showProfileSheet(context, ref, user),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileSheet(BuildContext context, WidgetRef ref, UserProfile? current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileSheet(current: current, ref: ref),
    );
  }
}

// ── Profile Bottom Sheet ────────────────────────────────────────────────────────

class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet({required this.current, required this.ref});
  final UserProfile? current;
  final WidgetRef ref;

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet>
    with WidgetsBindingObserver {
  late final TextEditingController _nameController;
  late String _selectedEmoji;
  double _keyboardHeight = 0;

  static const _avatarEmojis = [
    '🧑', '👩', '👨', '👧', '👦', '👽', '👾', '🐱', '🐶', '🦊',
    '🐻', '🐼', '🐨', '🐯', '🦁', '🐮', '🐷', '🐸', '🐵', '🐣',
    '🦄', '🐝', '🦋', '🐢', '🐙', '🦕', '🦖', '🐉', '🦉', '🦚',
    '🦜', '🦩', '🐧', '🦈', '🐬', '🐳', '🐠', '🦀', '🦞', '🦠',
    '👻', '🤡', '👺', '👹', '🤖', '💀', '🎃', '💩', '👑', '🧙‍♂️',
    '🧝‍♀️', '🧛‍♂️', '🧜‍♀️', '🧚‍♂️', '👼', '🦸‍♂️', '🦹‍♀️', '🕵️‍♂️', '👮‍♀️', '👷',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _nameController = TextEditingController(text: widget.current?.name);
    _selectedEmoji = widget.current?.avatarEmoji ?? '🧑';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final bottom = WidgetsBinding.instance.platformDispatcher.views.first
            .viewInsets.bottom /
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    if (!mounted) return;
    setState(() => _keyboardHeight = bottom);
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final updated = widget.current?.copyWith(
          name: name,
          avatarEmoji: _selectedEmoji,
        ) ??
        UserProfile(
          name: name,
          avatarEmoji: _selectedEmoji,
          hasCompletedOnboarding: true,
        );
    widget.ref.read(userProvider.notifier).saveProfile(updated);
    Navigator.pop(context);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hesabı Sil', style: TextStyle(color: Colors.redAccent)),
        content: const Text(
          'Profil, tüm tasarruf kayıtların ve hedeflerin kalıcı olarak silinecek.\n\nBu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              widget.ref.read(userProvider.notifier).resetProfile();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hesabı Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.md),

            // Başlık
            Row(children: [
              const Text('👤', style: TextStyle(fontSize: 24)),
              const SizedBox(width: AppTheme.sm),
              Text('Profili Düzenle', style: AppTheme.headingMedium),
            ]),
            const SizedBox(height: AppTheme.lg),

            // Avatar seçici
            Text('Avatarın', style: AppTheme.labelSmall.copyWith(letterSpacing: 1)),
            const SizedBox(height: AppTheme.sm),
            SizedBox(
              height: 56,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _avatarEmojis.length,
                itemBuilder: (_, i) {
                  final e = _avatarEmojis[i];
                  final selected = e == _selectedEmoji;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedEmoji = e);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 48, height: 48,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.accent.withValues(alpha: 0.2)
                            : AppTheme.adaptiveGlass(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppTheme.accent
                              : AppTheme.adaptiveBorder(context),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(e, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppTheme.md),

            // İsim alanı
            Text('İsmin', style: AppTheme.labelSmall.copyWith(letterSpacing: 1)),
            const SizedBox(height: AppTheme.sm),
            TextField(
              controller: _nameController,
              style: const TextStyle(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'İsmin veya Lakabın',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.adaptiveGlass(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.adaptiveBorder(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.adaptiveBorder(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.md),

            // Tema seçimi
            Text('Tema', style: AppTheme.labelSmall.copyWith(letterSpacing: 1)),
            const SizedBox(height: AppTheme.sm),
            Consumer(
              builder: (ctx, ref, _) {
                final notifier = ref.read(themeProvider.notifier);
                final current = ref.watch(themeProvider);
                final options = [
                  (ThemeMode.dark, '🌙', 'Koyu'),
                  (ThemeMode.light, '☀️', 'Açık'),
                  (ThemeMode.system, '🌓', 'Sistem'),
                ];
                return Row(
                  children: options.map((opt) {
                    final (mode, emoji, label) = opt;
                    final active = current == mode;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => notifier.setTheme(mode),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: active
                                ? AppTheme.accent.withValues(alpha: 0.2)
                                : AppTheme.adaptiveGlass(ctx),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: active
                                  ? AppTheme.accent
                                  : AppTheme.adaptiveBorder(ctx),
                              width: active ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 18)),
                              const SizedBox(height: 2),
                              Text(label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                                    color: active ? AppTheme.accent : AppTheme.textSecondary,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: AppTheme.lg),

            // Kaydet butonu
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
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Kaydet 👤',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.sm),

            // Hesabı Sil
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _confirmDelete,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  '🗑 Hesabı Sil',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated Background ────────────────────────────────────────────────────────

class _BackgroundGradient extends StatefulWidget {
  const _BackgroundGradient();

  @override
  State<_BackgroundGradient> createState() => _BackgroundGradientState();
}

class _BackgroundGradientState extends State<_BackgroundGradient>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [
              Color(0xFF0D1117),
              Color(0xFF161030),
              Color(0xFF0D1A20),
            ],
            stops: [
              0.0,
              0.3 + _animation.value * 0.2,
              1.0,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Dekoratif arka plan circle (blur efekti)
            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent.withValues(alpha: 0.04 + _animation.value * 0.04),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -60,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.03 + _animation.value * 0.03),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom FAB ─────────────────────────────────────────────────────────────────

class _KalsinFAB extends StatefulWidget {
  const _KalsinFAB({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_KalsinFAB> createState() => _KalsinFABState();
}

class _KalsinFABState extends State<_KalsinFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 0.1,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.45),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('💚', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'Kalsın! Kaydet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0D1117),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: 500.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.5, curve: Curves.easeOut);
  }
}

class _SideMenuBtn extends StatelessWidget {
  final String icon;
  final VoidCallback onPressed;

  const _SideMenuBtn({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.adaptiveBorder(context)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 2),
            )
          ]
        ),
        child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
      ),
    ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.5, curve: Curves.easeOut);
  }
}
