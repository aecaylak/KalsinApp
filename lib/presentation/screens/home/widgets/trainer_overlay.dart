import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';

class TrainerOverlay extends StatefulWidget {
  final VoidCallback onFinish;

  const TrainerOverlay({super.key, required this.onFinish});

  @override
  State<TrainerOverlay> createState() => _TrainerOverlayState();
}

class _TrainerOverlayState extends State<TrainerOverlay> {
  int _step = 0;

  final List<Map<String, String>> _steps = [
    {
      'title': 'Hoş Geldin! 👋',
      'desc': 'KalsınApp ile birikim yolculuğuna başladın. İşte kısa bir tur!',
      'icon': '✨'
    },
    {
      'title': 'Kalsın Kaydet 💚',
      'desc': 'Harcamaktan vazgeçtiğin her tutarı ortadaki büyük butona basarak kaydet.',
      'icon': '💰'
    },
    {
      'title': 'Hedeflerini İzle 🎯',
      'desc': 'Sağdaki butondan yeni hedefler ekleyebilir ve ilerlemeni görebilirsin.',
      'icon': '📈'
    },
    {
      'title': 'Geçmişe Bak ⏳',
      'desc': 'Soldaki butondan tüm birikimlerini inceleyebilir ve filtreleyebilirsin.',
      'icon': '📚'
    },
    {
      'title': 'Profilini Yönet 🧑',
      'desc': 'Üstteki profil simgesine basarak ismini ve avatarını her zaman değiştirebilirsin.',
      'icon': '⚙️'
    },
  ];

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
    } else {
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _steps[_step];

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Blur background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black54),
          ),
          
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppTheme.adaptiveBorder(context)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      blurRadius: 30,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(current['icon']!, style: const TextStyle(fontSize: 48))
                        .animate(key: ValueKey('icon_$_step'))
                        .scale(duration: 400.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 24),
                    Text(
                      current['title']!,
                      style: AppTheme.headingMedium.copyWith(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      current['desc']!,
                      style: AppTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.background,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          _step == _steps.length - 1 ? 'Hadi Başlayalım!' : 'Sıradaki',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
