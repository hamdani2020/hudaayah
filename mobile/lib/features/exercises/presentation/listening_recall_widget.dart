import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../quran_reader/application/audio_controller.dart';
import '../../quran_reader/data/lesson_models.dart';
import '../data/exercise_models.dart';

/// Play the ayah audio, recite from memory, then self-mark. Lenient and
/// encouraging (adab) — no pass/fail pressure. The self-mark is submitted and
/// the server records it leniently (feeds the review scheduler later).
class ListeningRecallWidget extends ConsumerWidget {
  const ListeningRecallWidget({
    super.key,
    required this.exercise,
    required this.ayahs,
    required this.enabled,
    required this.onSubmit,
  });

  final Exercise exercise;
  final List<Ayah> ayahs;
  final bool enabled;
  final void Function(Map<String, dynamic> submitted) onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final verseKey = exercise.config['verse_key'] as String?;
    final audio = ref.watch(audioControllerProvider);

    final ayah = _findAyah(verseKey);
    final isThis = audio.verseKey == verseKey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(exercise.prompt, style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        if (ayah?.audioUrl != null)
          Center(
            child: IconButton.filled(
              iconSize: 48,
              icon: Icon(isThis && audio.playing ? Icons.pause : Icons.play_arrow),
              onPressed: enabled
                  ? () => ref
                      .read(audioControllerProvider.notifier)
                      .playAyah(verseKey!, ayah!.audioUrl!)
                  : null,
            ),
          )
        else
          Text('Audio unavailable for this ayah.',
              style: theme.textTheme.bodyMedium),
        const SizedBox(height: 24),
        Text('How did your recitation feel?',
            style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: enabled
                    ? () => onSubmit({'self_marked_correct': false})
                    : null,
                child: const Text('Still learning'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: enabled
                    ? () => onSubmit({'self_marked_correct': true})
                    : null,
                child: const Text('I recalled it'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Ayah? _findAyah(String? verseKey) {
    for (final a in ayahs) {
      if (a.verseKey == verseKey) return a;
    }
    return null;
  }
}
