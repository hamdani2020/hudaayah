import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../application/audio_controller.dart';
import '../data/lesson_models.dart';

/// Renders a single ayah with three visually distinct layers (quran-content-rules):
///   1. Arabic (RTL, diacritics, Uthmani font) — sacred, never altered.
///   2. Word-by-word + transliteration (educational aid).
///   3. Translation — clearly labeled, never styled as the Quran itself.
class AyahCard extends ConsumerWidget {
  const AyahCard({super.key, required this.ayah});

  final Ayah ayah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final audio = ref.watch(audioControllerProvider);
    final isThis = audio.verseKey == ayah.verseKey;
    final hasAudio = ayah.audioUrl != null;
    final isLoadingThis = isThis && audio.loading;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(ayah.verseKey, style: theme.textTheme.labelMedium),
                ),
                if (hasAudio)
                  IconButton(
                    iconSize: 32,
                    icon: isLoadingThis
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(isThis && audio.playing
                            ? Icons.pause_circle
                            : Icons.play_circle),
                    color: theme.colorScheme.primary,
                    onPressed: isLoadingThis
                        ? null
                        : () => ref
                            .read(audioControllerProvider.notifier)
                            .playAyah(ayah.verseKey, ayah.audioUrl!),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Layer 1 — sacred Arabic, RTL, Uthmani font.
            if (ayah.arabic != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    ayah.arabic!,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'UthmanicHafs',
                      fontSize: 30,
                      height: 2.1,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
            // Layer 2 — word-by-word chips (transliteration + meaning).
            if (ayah.words.isNotEmpty) ...[
              const SizedBox(height: 8),
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
            if (ayah.translation != null) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Text('TRANSLATION', style: theme.textTheme.labelSmall),
              const SizedBox(height: 2),
              Text(ayah.translation!, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
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
          if (word.transliteration != null)
            Text(word.transliteration!,
                textDirection: TextDirection.ltr,
                style: theme.textTheme.labelSmall),
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
