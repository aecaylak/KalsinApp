import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/theme/app_theme.dart';
import '../presentation/providers/theme_provider.dart';
import '../presentation/providers/user_provider.dart';
import '../presentation/providers/widget_provider.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';

/// Uygulamanın kök widget'ı. MaterialApp + tema tanımları burada.
class KalsinApp extends ConsumerWidget {
  const KalsinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    // Ana ekran widget'ını güncel tut
    ref.watch(widgetUpdateProvider);

    return MaterialApp(
      title: 'KalsınApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProvider);
    final isCompleted = userProfile?.hasCompletedOnboarding ?? false;
    return isCompleted ? const HomeScreen() : const OnboardingScreen();
  }
}
