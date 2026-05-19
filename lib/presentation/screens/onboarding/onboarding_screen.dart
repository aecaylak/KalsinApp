import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/currency.dart';
import '../../../domain/models/goal.dart';
import '../../../domain/models/user_profile.dart';
import '../../providers/goal_provider.dart';
import '../../providers/user_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _goalNameController = TextEditingController();
  final _goalAmountController = TextEditingController();
  
  String _selectedEmoji = '🧑';
  String _selectedGoalEmoji = '📱';
  String _selectedCurrencyCode = 'TRY';

  final List<String> _avatarEmojis = [
    '🧑', '👩', '👨', '👧', '👦', '👽', '👾', '🐱', '🐶', '🦊',
    '🐻', '🐼', '🐨', '🐯', '🦁', '🐮', '🐷', '🐸', '🐵', '🐣',
    '🦄', '🐝', '🦋', '🐢', '🐙', '🦕', '🦖', '🐉', '🦉', '🦚',
    '🦜', '🦩', '🐧', '🦈', '🐬', '🐳', '🐠', '🦀', '🦞', '🦠',
    '👻', '🤡', '👺', '👹', '🤖', '💀', '🎃', '💩', '👑', '🧙‍♂️',
    '🧝‍♀️', '🧛‍♂️', '🧜‍♀️', '🧚‍♂️', '👼', '🦸‍♂️', '🦹‍♀️', '🕵️‍♂️', '👮‍♀️', '👷'
  ];
  final List<String> _goalEmojis = ['📱', '✈️', '💻', '🚗', '🎮', '🎓', '🏠', '⌚'];

  @override
  void dispose() {
    _nameController.dispose();
    _goalNameController.dispose();
    _goalAmountController.dispose();
    super.dispose();
  }

  void _completeOnboarding() async {
    final name = _nameController.text.trim();
    final goalName = _goalNameController.text.trim();
    final goalAmountStr = _goalAmountController.text.trim();

    if (name.isEmpty || goalName.isEmpty || goalAmountStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun!')),
      );
      return;
    }

    final amount = double.tryParse(goalAmountStr);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir hedef tutarı girin!')),
      );
      return;
    }

    // Save profile
    final profile = UserProfile(
      name: name,
      avatarEmoji: _selectedEmoji,
      hasCompletedOnboarding: true,
      currencyCode: _selectedCurrencyCode,
    );
    await ref.read(userProvider.notifier).saveProfile(profile);

    // Save initial goal
    final goal = Goal(
      id: const Uuid().v4(),
      title: goalName,
      targetAmount: amount,
      emoji: _selectedGoalEmoji,
    );
    // Use goalsProvider to add this goal (we will update goals provider next)
    await ref.read(goalsProvider.notifier).addGoal(goal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                'KalsınApp\'e\nHoş Geldin! 👋',
                style: AppTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Paranı harcamak yerine biriktir, hedeflerine daha hızlı ulaş.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // --- Avatar ve İsim ---
              Text('Seni nasıl çağıralım?', style: AppTheme.titleLarge),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  GestureDetector(
                    child: Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(child: Text(_selectedEmoji, style: const TextStyle(fontSize: 32))),
                    ),
                    onTap: () => _showEmojiPicker(true),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'İsmin veya Lakabın',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // --- Para Birimi ---
              Text('Para birimin hangisi?', style: AppTheme.titleLarge),
              const SizedBox(height: 16),
              _CurrencySelector(
                selected: _selectedCurrencyCode,
                onChanged: (code) => setState(() => _selectedCurrencyCode = code),
              ),

              const SizedBox(height: 40),

              // --- İlk Hedef ---
              Text('İlk hedefin ne?', style: AppTheme.titleLarge),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  GestureDetector(
                    child: Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Center(child: Text(_selectedGoalEmoji, style: const TextStyle(fontSize: 32))),
                    ),
                    onTap: () => _showEmojiPicker(false),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _goalNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Örn: Yeni Telefon',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _goalAmountController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Hedef Tutarı (${currencyByCode(_selectedCurrencyCode).symbol})',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  prefixText: '${currencyByCode(_selectedCurrencyCode).symbol} ',
                  prefixStyle: const TextStyle(color: Colors.white54, fontSize: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 60),

              // --- Başla Butonu ---
              ElevatedButton(
                onPressed: _completeOnboarding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.background,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 5,
                ),
                child: const Text('Başla!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmojiPicker(bool isAvatar) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final list = isAvatar ? _avatarEmojis : _goalEmojis;
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Bir Emoji Seç', style: AppTheme.titleLarge),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: list.map((e) => GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isAvatar) {
                          _selectedEmoji = e;
                        } else {
                          _selectedGoalEmoji = e;
                        }
                      });
                      Navigator.pop(context);
                    },
                    child: Text(e, style: const TextStyle(fontSize: 32)),
                  )).toList(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CurrencySelector extends StatelessWidget {
  const _CurrencySelector({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final currency = currencyByCode(selected);
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Text(currency.flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currency.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  Text(currency.code,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Text(currency.symbol,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accent)),
            const SizedBox(width: 8),
            const Icon(Icons.expand_more, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Para Birimi Seç',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  itemCount: kCurrencies.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: AppTheme.adaptiveBorder(ctx), height: 1),
                  itemBuilder: (_, i) {
                    final c = kCurrencies[i];
                    final isSelected = c.code == selected;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(c.flag,
                          style: const TextStyle(fontSize: 28)),
                      title: Text(c.name,
                          style: TextStyle(
                            color: isSelected ? AppTheme.accent : Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          )),
                      trailing: Text(c.symbol,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppTheme.accent
                                  : AppTheme.textMuted)),
                      onTap: () {
                        onChanged(c.code);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
