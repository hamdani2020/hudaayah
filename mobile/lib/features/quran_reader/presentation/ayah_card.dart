import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/audio_controller.dart';
import '../data/lesson_models.dart';

/// Renders a single ayah with three visually distinct layers:
///   1. Arabic (RTL, diacritics, Uthmani font) — sacred, never altered.
///   2. Transliteration (optional aid).
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(ayah.verseKey, style: theme.textTheme.labelMedium),
                if (hasAudio)
                  IconButton(
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
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  ayah.arabic!,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontSize: 28,
                    height: 2.0,
                  ),
                ),
              ),
            // Layer 3 — translation, clearly labeled and visually secondary.
            if (ayah.translation != null) ...[
              const SizedBox(height: 12),
              Text('Translation',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(ayah.translation!, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
