import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_exception.dart';
import '../application/audio_controller.dart';
import '../data/lesson_repository.dart';
import 'ayah_card.dart';

/// Quran reader for a lesson. Renders Arabic RTL + translation + per-ayah audio
/// with a repeat/loop toggle, plus visible QF attribution. Presentational:
/// all content comes from the backend; no progression logic here.
class ReaderScreen extends ConsumerWidget {
  const ReaderScreen({super.key, required this.lessonId});

  final int lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lessonAsync = ref.watch(lessonProvider(lessonId));
    final audio = ref.watch(audioControllerProvider);

    // Surface audio load/playback failures.
    ref.listen(audioControllerProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Al-Fatihah'),
        actions: [
          // Repeat/loop toggle — core memorization aid.
          IconButton(
            tooltip: audio.looping ? 'Loop on' : 'Loop off',
            icon: Icon(audio.looping ? Icons.repeat_one : Icons.repeat),
            color: audio.looping ? theme.colorScheme.primary : null,
            onPressed: () => ref.read(audioControllerProvider.notifier).toggleLoop(),
          ),
        ],
      ),
      body: lessonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) {
          final msg = err is ApiException ? err.message : 'Could not load the lesson.';
          return _ErrorRetry(
            message: msg,
            onRetry: () => ref.invalidate(lessonProvider(lessonId)),
          );
        },
        data: (lesson) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final ayah in lesson.ayahs) AyahCard(ayah: ayah),
                ],
              ),
            ),
            // Visible Quran Foundation attribution (QF terms).
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: theme.colorScheme.surfaceContainerHighest,
              child: Text(
                lesson.attribution,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
