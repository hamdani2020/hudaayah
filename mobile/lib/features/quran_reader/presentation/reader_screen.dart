import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/errors/api_exception.dart';
import '../application/audio_controller.dart';
import '../data/lesson_models.dart';
import '../data/lesson_repository.dart';
import 'ayah_card.dart';
import 'widgets/audio_strip.dart';
import 'widgets/reader_floating_controls.dart';

/// Quran reader for a lesson (design-mapping §2 screen 06). Renders Arabic RTL +
/// transliteration + translation as three distinct layers, an audio strip bound
/// to the real [audioControllerProvider], floating reader controls, the
/// "Practice this lesson" CTA, and the visible QF attribution.
///
/// Presentational: all content comes from the backend; no progression logic.
/// Font size and translation visibility are local UI state only (no API).
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.lessonId});

  final int lessonId;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  // Local-only reader preferences (no controller/API involvement).
  double _fontScale = 1.0;
  bool _showTranslation = true;

  void _decreaseFont() =>
      setState(() => _fontScale = (_fontScale - 0.1).clamp(0.8, 1.6));
  void _increaseFont() =>
      setState(() => _fontScale = (_fontScale + 0.1).clamp(0.8, 1.6));
  void _toggleTranslation() =>
      setState(() => _showTranslation = !_showTranslation);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lessonAsync = ref.watch(lessonProvider(widget.lessonId));
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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppTheme.primary,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/surah'),
        ),
        title: Text('Surah Reader',
            style: theme.textTheme.headlineSmall?.copyWith(color: AppTheme.primary)),
      ),
      body: lessonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) {
          final msg = err is ApiException ? err.message : 'Could not load the lesson.';
          return _ErrorRetry(
            message: msg,
            onRetry: () => ref.invalidate(lessonProvider(widget.lessonId)),
          );
        },
        data: (lesson) {
          final firstAudioAyah = _firstAudioAyah(lesson);
          final isStripAyahPlaying = firstAudioAyah != null &&
              audio.verseKey == firstAudioAyah.verseKey &&
              audio.playing;
          final isStripAyahLoading = firstAudioAyah != null &&
              audio.verseKey == firstAudioAyah.verseKey &&
              audio.loading;

          return Stack(
            children: [
              Column(
                children: [
                  AudioStrip(
                    surahTitle: 'Surah Al-Fātiḥah',
                    reciterLabel: 'Mishary Rashid Alafasy • Ayah 1–7',
                    playing: isStripAyahPlaying,
                    loading: isStripAyahLoading,
                    looping: audio.looping,
                    onPlayPause: firstAudioAyah == null
                        ? null
                        : () => ref
                            .read(audioControllerProvider.notifier)
                            .playAyah(
                                firstAudioAyah.verseKey, firstAudioAyah.audioUrl!),
                    onToggleLoop: () =>
                        ref.read(audioControllerProvider.notifier).toggleLoop(),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      children: [
                        for (final ayah in lesson.ayahs)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: AyahCard(
                              ayah: ayah,
                              fontScale: _fontScale,
                              showTranslation: _showTranslation,
                            ),
                          ),
                        if (lesson.exercises.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () =>
                                context.go('/lesson/${lesson.id}/practice'),
                            icon: const Icon(Icons.quiz),
                            label: const Text('Practice this lesson'),
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Visible Quran Foundation attribution (QF terms).
                        Text(
                          lesson.attribution,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Center(
                  child: ReaderFloatingControls(
                    translationVisible: _showTranslation,
                    onDecreaseFont: _decreaseFont,
                    onIncreaseFont: _increaseFont,
                    onToggleTranslation: _toggleTranslation,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// First ayah that actually has an audio URL, for the strip's main button.
  Ayah? _firstAudioAyah(Lesson lesson) {
    for (final a in lesson.ayahs) {
      if (a.audioUrl != null) return a;
    }
    return null;
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
