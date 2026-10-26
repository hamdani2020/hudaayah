import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Sacred Serenity" theme — ported from the Stitch design tokens
/// (design/stitch/ui-spec.md). Deep teal primary, warm amber accent, light
/// minty surfaces. Headlines/display use Newsreader; body/labels use Plus
/// Jakarta Sans.
///
/// NOTE: Quran Arabic ayat are rendered with the bundled Uthmani font family
/// `UthmanicHafs` (see assets/fonts/README.md) — not this theme's text styles.
class AppTheme {
  const AppTheme._();

  // ── Sacred Serenity palette (light) ──────────────────────────────────────
  static const Color primary = Color(0xFF002721);
  static const Color primaryContainer = Color(0xFF0F3E36);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF7CA99E);
  static const Color inversePrimary = Color(0xFFA2D0C4);

  static const Color secondary = Color(0xFF904D00);
  static const Color secondaryContainer = Color(0xFFFE932C); // warm amber accent
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryFixed = Color(0xFFFFDCC3);

  static const Color tertiary = Color(0xFF00281A);
  static const Color tertiaryContainer = Color(0xFF00402D);

  static const Color surface = Color(0xFFEFFCF9);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFE9F7F3);
  static const Color surfaceContainer = Color(0xFFE3F1ED);
  static const Color surfaceContainerHigh = Color(0xFFDDEBE8);
  static const Color surfaceVariant = Color(0xFFD8E5E2);

  static const Color onSurface = Color(0xFF121E1C);
  static const Color onSurfaceVariant = Color(0xFF404846);
  static const Color outline = Color(0xFF717976);
  static const Color outlineVariant = Color(0xFFC0C8C5);
  static const Color error = Color(0xFFBA1A1A);

  // Design radii (lg .5rem = 8, xl .75rem = 12).
  static const double radiusLg = 8;
  static const double radiusXl = 12;

  static ThemeData light() {
    final scheme = const ColorScheme.light().copyWith(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      inversePrimary: inversePrimary,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      tertiary: tertiary,
      tertiaryContainer: tertiaryContainer,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      surfaceContainerLowest: surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: surfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      error: error,
    );

    final body = GoogleFonts.plusJakartaSansTextTheme();
    // Type scale from the spec (display 28/36, headline 24/18, body 16/14, label 12/11).
    final textTheme = body.copyWith(
      displayLarge: GoogleFonts.newsreader(
          fontSize: 36, fontWeight: FontWeight.w600, color: onSurface),
      displayMedium: GoogleFonts.newsreader(
          fontSize: 32, fontWeight: FontWeight.w600, color: onSurface),
      displaySmall: GoogleFonts.newsreader(
          fontSize: 28, fontWeight: FontWeight.w600, color: onSurface),
      headlineMedium: GoogleFonts.newsreader(
          fontSize: 24, fontWeight: FontWeight.w600, color: onSurface),
      headlineSmall: GoogleFonts.newsreader(
          fontSize: 18, fontWeight: FontWeight.w600, color: onSurface),
      titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 20, fontWeight: FontWeight.w700, color: onSurface),
      titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
      bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 16, color: onSurface),
      bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 14, color: onSurface),
      labelMedium: GoogleFonts.plusJakartaSans(
          fontSize: 12, fontWeight: FontWeight.w600, color: onSurfaceVariant),
      labelSmall: GoogleFonts.plusJakartaSans(fontSize: 11, color: onSurfaceVariant),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceContainerLow,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 2,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          side: const BorderSide(color: outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryContainer,
          foregroundColor: onPrimary,
          textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w700),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusXl)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w600),
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: outlineVariant),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusXl)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: secondaryContainer,
        linearTrackColor: surfaceContainerHigh,
      ),
    );
  }
}
