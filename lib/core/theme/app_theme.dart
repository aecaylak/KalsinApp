import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// KalsınApp global tema — "Cozy Dark" paleti.
/// Koyu lacivert/mor zemin üzerinde sıcak yeşil aksanlar.
class AppTheme {
  AppTheme._();

  // ── Renk Paleti ──────────────────────────────────────────────
  static const Color background     = Color(0xFF0D1117); // Derin koyu
  static const Color surface        = Color(0xFF161B27); // Kart / panel
  static const Color surfaceLight   = Color(0xFF1E2536); // Hafif açık panel
  static const Color primary        = Color(0xFF4ADE80); // Canlı yeşil
  static const Color primaryDark    = Color(0xFF22C55E); // Koyu yeşil
  static const Color accent         = Color(0xFFA78BFA); // Lila / mor
  static const Color accentWarm     = Color(0xFFFBBF24); // Altın sarısı
  static const Color textPrimary    = Color(0xFFF1F5F9); // Neredeyse beyaz
  static const Color textSecondary  = Color(0xFF94A3B8); // Gri
  static const Color textMuted      = Color(0xFF475569); // Soluk gri
  static const Color danger         = Color(0xFFEF4444);
  static const Color glassWhite     = Color(0x14FFFFFF); // Glassmorphism taban
  static const Color glassBorder    = Color(0x22FFFFFF); // Glassmorphism çerçeve

  static const Color cardBackground = surface; // Alias used in screens

  // ── Gradient Tanımları ────────────────────────────────────────
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1117), Color(0xFF161030), Color(0xFF0D1117)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF4ADE80), Color(0xFF22D3EE)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA78BFA), Color(0xFFEC4899)],
  );

  // ── Light Tema Renkleri ───────────────────────────────────────
  static const Color lightBackground   = Color(0xFFF0F4F8);
  static const Color lightSurface      = Color(0xFFFFFFFF);
  static const Color lightSurfaceLight = Color(0xFFEAF1FB);
  static const Color lightTextPrimary  = Color(0xFF1A202C);
  static const Color lightTextSecondary = Color(0xFF4A5568);
  static const Color lightGlassWhite   = Color(0x12000000);
  static const Color lightGlassBorder  = Color(0x30000000);

  // ── ThemeData ─────────────────────────────────────────────────
  static ThemeData get light {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: lightSurface,
        error: danger,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: lightTextPrimary,
        displayColor: lightTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: lightTextPrimary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Color(0xFFF0F4F8),
        elevation: 8,
        shape: CircleBorder(),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightGlassBorder, width: 1),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: lightSurface,
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: danger,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Color(0xFF0D1117),
        elevation: 8,
        shape: CircleBorder(),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  // ── Text Styles ───────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.nunito(
        fontSize: 56,
        fontWeight: FontWeight.w900,
        letterSpacing: -2,
      );

  static TextStyle get headlineLarge => GoogleFonts.nunito(
        fontSize: 32,
        fontWeight: FontWeight.w900,
      );

  static TextStyle get headingMedium => GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get titleLarge => GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get bodyLarge => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get bodyMedium => GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      );

  static TextStyle get labelSmall => GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textMuted,
        letterSpacing: 0.5,
      );

  // ── Theme-aware helpers ───────────────────────────────────────
  static Color adaptiveGlass(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? glassWhite
        : lightGlassWhite;
  }

  static Color adaptiveBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? glassBorder
        : lightGlassBorder;
  }

  static Color adaptiveSurface(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  /// Açık temada kartların görünür olması için gölge + kenarlık ekler
  static BoxDecoration adaptiveCardDecoration(BuildContext context, {
    double radius = 20,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark ? glassBorder : lightGlassBorder,
        width: isDark ? 0.8 : 1.0,
      ),
      boxShadow: isDark
          ? []
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
    );
  }

  // ── Glassmorphism Decoration ──────────────────────────────────
  static BoxDecoration glassCard({
    double radius = 24,
    Color? borderColor,
    List<Color>? gradientColors,
  }) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: glassWhite,
        border: Border.all(
          color: borderColor ?? glassBorder,
          width: 1.0,
        ),
        gradient: gradientColors != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              )
            : null,
      );

  // ── Spacing ───────────────────────────────────────────────────
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 16;
  static const double lg   = 24;
  static const double xl   = 32;
  static const double xxl  = 48;
}
