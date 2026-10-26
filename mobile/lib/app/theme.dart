import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Sacred Serenity" theme — ported from the Stitch design tokens
/// (design/stitch/ui-spec.md). Deep teal primary, warm amber accent, light
/// surfaces. Headings use Newsreader; body uses Plus Jakarta Sans.
///
/// NOTE: Quran Arabic ayat must be rendered with a bundled Uthmani font
/// (e.g. KFGQPC Uthmanic Hafs) per quran-content-rules — added in Phase 3.
class AppTheme {
  const AppTheme._();

  // Sacred Serenity palette (light).
  static const Color primary = Color(0xFF002721);
  static const Color primaryContainer = Color(0xFF0F3E36);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF904D00);
  static const Color secondaryContainer = Color(0xFFFE932C); // warm accent
  static const Color surface = Color(0xFFEFFCF9);
  static const Color onSurface = Color(0xFF121E1C);
  static const Color onSurfaceVariant = Color(0xFF404846);
  static const Color outline = Color(0xFF717976);
  static const Color error = Color(0xFFBA1A1A);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryContainer,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      primaryContainer: primaryContainer,
      onPrimary: onPrimary,
      secondary: secondary,
      secondaryContainer: secondaryContainer,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      error: error,
    );

    final baseText = GoogleFonts.plusJakartaSansTextTheme();
    final textTheme = baseText.copyWith(
      displayLarge: GoogleFonts.newsreader(textStyle: baseText.displayLarge),
      headlineMedium: GoogleFonts.newsreader(
        textStyle: baseText.headlineMedium,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: GoogleFonts.newsreader(textStyle: baseText.headlineSmall),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      textTheme: textTheme,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryContainer,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }
}
