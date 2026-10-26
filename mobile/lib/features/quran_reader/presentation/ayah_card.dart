import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../application/audio_controller.dart';
import '../data/lesson_models.dart';

/// Renders a single ayah as the Stitch ayah card (design-mapping §2 screen 06)
/// with three visually distinct layers (quran-content-rules):
///   1. Arabic (RTL, diacritics, Uthmani font) — sacred, never altered.
///   2. Word-by-word + transliteration (educational aid).
///   3. Translation — clearly labeled, never styled as the Quran itself.
///
/// Presentational. [fontScale] and [showTranslation] are local UI preferences
/// forwarded from the reader; they default to a normal, fully-visible card so
/// the public widget contract is unchanged for other callers.
class AyahCard extends ConsumerWidget {
  const AyahCard({
    super.key,
    required this.ayah,
    this.fontScale = 1.0,
    this.showTranslation = true,
  });

  final Ayah ayah;
  final double fontScale;
  final bool showTranslation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final audio = ref.watch(audioControllerProvider);
    final isThis = audio.verseKey == ayah.verseKey;
    final hasAudio = ayah.audioUrl != null;
    final isLoadingThis = isThis && audio.loading;
    final isPlayingThis = isThis && audio.playing;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Verse-key badge + Juz chip.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryFixed,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        ayah.verseKey,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: AppTheme.onSecondaryFixed),
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('Juz 1', style: theme.textTheme.labelSmall),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Layer 1 — sacred Arabic, RTL, Uthmani font + end-of-ayah marker.
                if (ayah.arabic != null)
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text.rich(
                      TextSpan(
                        style: AppTextStyles.arabicAyahLg.copyWith(
                          fontSize: AppTextStyles.arabicAyahLg.fontSize! * fontScale,
                        ),
                        children: [
                          TextSpan(text: '${ayah.arabic!} '),
                          TextSpan(
                            text: _endOfAyahMarker(ayah.verseKey),
                            style: const TextStyle(color: AppTheme.secondary),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                // Layer 2 — word-by-word chips (transliteration + meaning).
                if (ayah.words.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [for (final w in ayah.words) _WordChip(word: w)],
                    ),
                  ),
                ],
                // Layer 3 — translation, clearly labeled and visually secondary.
                if (showTranslation && ayah.translation != null) ...[
                  const SizedBox(height: 14),
                  Text('TRANSLATION', style: theme.textTheme.labelSmall),
                  const SizedBox(height: 4),
                  Text(ayah.translation!, style: theme.textTheme.bodyLarge),
                ],
              ],
            ),
          ),
          // Bottom action row (play / translate / copy) on surface-container-low.
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppTheme.radiusXl),
                bottomRight: Radius.circular(AppTheme.radiusXl),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                if (hasAudio)
                  IconButton(
                    iconSize: 20,
                    color: AppTheme.primary,
                    icon: isLoadingThis
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(isPlayingThis
                            ? Icons.pause_circle
                            : Icons.play_circle),
                    onPressed: isLoadingThis
                        ? null
                        : () => ref
                            .read(audioControllerProvider.notifier)
                            .playAyah(ayah.verseKey, ayah.audioUrl!),
                  ),
                IconButton(
                  iconSize: 20,
                  color: AppTheme.onSurfaceVariant,
                  icon: const Icon(Icons.translate),
                  onPressed: null,
                ),
                const Spacer(),
                IconButton(
                  iconSize: 20,
                  color: AppTheme.onSurfaceVariant,
                  icon: const Icon(Icons.content_copy),
                  onPressed: null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Arabic-Indic numeral between ornate ayah-end brackets, derived from the
  /// verse key's ayah number (not Quran text — a decorative verse marker).
  String _endOfAyahMarker(String verseKey) {
    final ayahNumber = verseKey.contains(':') ? verseKey.split(':').last : verseKey;
    const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    var converted = ayahNumber;
    for (var i = 0; i < western.length; i++) {
      converted = converted.replaceAll(western[i], arabic[i]);
    }
    return '\u06DD$converted';
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.word});
  final WordPiece word;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        children: [
          if (word.arabic != null)
            Text(word.arabic!,
                style: const TextStyle(fontFamily: 'UthmanicHafs', fontSize: 20)),
          // Transliteration layer — italic, visually distinct from translation.
          if (word.transliteration != null)
            Text(word.transliteration!,
                textDirection: TextDirection.ltr,
                style: AppTextStyles.transliteration.copyWith(fontSize: 11)),
          if (word.translation != null)
            Text(word.translation!,
                textDirection: TextDirection.ltr,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
