import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Sacred Serenity" theme — the single token source for the app, ported from
/// the authoritative Google Stitch design tokens (design/stitch/UI_SPEC.md and
/// the 8 HTML exports; see .agents/tasks/design-mapping.md §1 and §4). Deep teal
/// primary, warm amber accent, light minty surfaces. Display/headline-md use
/// Newsreader; body/UI/labels use Plus Jakarta Sans.
///
/// All colors and text styles belong here. Feature code references them via
/// `Theme.of(context).colorScheme.*` / `.textTheme.*` or the `AppTheme` /
/// `AppTextStyles` consts below — no scattered raw hex in features.
///
/// NOTE: Quran Arabic ayat are rendered with the `UthmanicHafs` font family
/// (see [AppTextStyles.arabicAyahLg] / [AppTextStyles.arabicAyahSm] and
/// assets/fonts/README.md). The .ttf is intentionally absent; Flutter falls
/// back gracefully. Do NOT add that font to pubspec.
class AppTheme {
  const AppTheme._();

  // ── Primary family ────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF002721);
  static const Color primaryContainer = Color(0xFF0F3E36);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF7CA99E);
  static const Color primaryFixed = Color(0xFFBDECE0);
  static const Color primaryFixedDim = Color(0xFFA2D0C4);
  static const Color onPrimaryFixed = Color(0xFF00201B);
  static const Color onPrimaryFixedVariant = Color(0xFF224E46);
  static const Color inversePrimary = Color(0xFFA2D0C4);

  // ── Secondary family (warm amber) ─────────────────────────────────────────
  static const Color secondary = Color(0xFF904D00); // dark amber text variant
  static const Color secondaryContainer = Color(0xFFFE932C); // warm amber accent
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF663500);
  static const Color secondaryFixed = Color(0xFFFFDCC3);
  static const Color secondaryFixedDim = Color(0xFFFFB77D);
  static const Color onSecondaryFixed = Color(0xFF2F1500);
  static const Color onSecondaryFixedVariant = Color(0xFF6E3900);

  // ── Tertiary family ───────────────────────────────────────────────────────
  static const Color tertiary = Color(0xFF00281A);
  static const Color tertiaryContainer = Color(0xFF00402D);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF34B488);
  static const Color tertiaryFixed = Color(0xFF80F9C8);
  static const Color tertiaryFixedDim = Color(0xFF62DCAD);

  // ── Surfaces ──────────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFEFFCF9);
  static const Color surfaceBright = Color(0xFFEFFCF9);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFE9F7F3);
  static const Color surfaceContainer = Color(0xFFE3F1ED);
  static const Color surfaceContainerHigh = Color(0xFFDDEBE8);
  static const Color surfaceContainerHighest = Color(0xFFD8E5E2);
  static const Color surfaceVariant = Color(0xFFD8E5E2); // deprecated M3 slot; kept for direct refs
  static const Color surfaceDim = Color(0xFFCFDDD9);
  static const Color surfaceCardBorder = Color(0xFFD0E7E1); // onboarding-local 1px border
  static const Color surfaceTint = Color(0xFF3B665D);

  static const Color onSurface = Color(0xFF121E1C);
  static const Color onSurfaceVariant = Color(0xFF404846);
  static const Color outline = Color(0xFF717976);
  static const Color outlineVariant = Color(0xFFC0C8C5);

  // ── Inverse ───────────────────────────────────────────────────────────────
  static const Color inverseSurface = Color(0xFF273331);
  static const Color onInverseSurface = Color(0xFFE6F4F0);

  // ── Error family ──────────────────────────────────────────────────────────
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ── Radii (DEFAULT 4 / lg 8 / xl 12 / 2xl 16 / 3xl 24 / full 9999) ─────────
  static const double radiusLg = 8;
  static const double radiusXl = 12;
  static const double radius2xl = 16;
  static const double radius3xl = 24;

  static ThemeData light() {
    final scheme = const ColorScheme.light().copyWith(
      // primary
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      inversePrimary: inversePrimary,
      // secondary
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      secondaryFixed: secondaryFixed,
      // tertiary
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      // surfaces
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      surfaceTint: surfaceTint,
      surfaceContainerLowest: surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHighest,
      surfaceDim: surfaceDim,
      surfaceBright: surfaceBright,
      outline: outline,
      outlineVariant: outlineVariant,
      // inverse
      inverseSurface: inverseSurface,
      onInverseSurface: onInverseSurface,
      // error
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
    );

    final base = GoogleFonts.plusJakartaSansTextTheme();
    // Type scale from design-mapping §1.2. height = lineHeight / fontSize;
    // letterSpacing (logical px) = em × fontSize.
    final textTheme = base.copyWith(
      displayLarge: GoogleFonts.newsreader(
        fontSize: 36,
        height: 44 / 36,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.02 * 36,
        color: onSurface,
      ),
      displayMedium: GoogleFonts.newsreader(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      displaySmall: GoogleFonts.newsreader(
        fontSize: 28,
        height: 36 / 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01 * 28,
        color: onSurface,
      ),
      headlineMedium: GoogleFonts.newsreader(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.01 * 24,
        color: onSurface,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        height: 26 / 16,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        height: 22 / 14,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.04 * 12,
        color: onSurfaceVariant,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        height: 14 / 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.02 * 11,
        color: onSurfaceVariant,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
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
              borderRadius: BorderRadius.circular(radiusLg)),
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
              borderRadius: BorderRadius.circular(radiusLg)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? primary : onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? primary : onSurfaceVariant,
          );
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: secondaryContainer,
        linearTrackColor: surfaceContainerHigh,
        circularTrackColor: surfaceContainerHigh,
      ),
    );
  }
}

/// Reusable text styles that have no natural Material 3 `TextTheme` slot.
/// Shared by reader, home, quiz, surah list, and completion so there is one
/// definition per role (design-mapping §1.2 / §4).
class AppTextStyles {
  const AppTextStyles._();

  /// transliteration-md — Newsreader italic 15 / h1.6, on-surface-variant.
  static TextStyle transliteration = GoogleFonts.newsreader(
    fontSize: 15,
    height: 1.6,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    letterSpacing: 0.01 * 15,
    color: AppTheme.onSurfaceVariant,
  );

  /// arabic-ayah-lg — Uthmani 30 / h≈2.27, w500, primary (graceful fallback).
  static const TextStyle arabicAyahLg = TextStyle(
    fontFamily: 'UthmanicHafs',
    fontSize: 30,
    height: 68 / 30,
    fontWeight: FontWeight.w500,
    color: AppTheme.primary,
  );

  /// arabic-ayah-sm — Uthmani 24 / h≈2.25, w500, primary (graceful fallback).
  static const TextStyle arabicAyahSm = TextStyle(
    fontFamily: 'UthmanicHafs',
    fontSize: 24,
    height: 54 / 24,
    fontWeight: FontWeight.w500,
    color: AppTheme.primary,
  );
}
