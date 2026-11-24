import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../app/theme.dart';
import '../../../core/errors/api_exception.dart';
import '../application/audio_controller.dart';
import '../application/reader_follow.dart';
import '../application/reader_settings.dart';
import '../data/lesson_repository.dart';
import 'ayah_card.dart';
import 'widgets/audio_strip.dart';
import 'widgets/reader_display_sheet.dart';
import 'widgets/reader_floating_controls.dart';
import 'widgets/reciter_fallback_notice.dart';

/// Quran reader for a lesson (design-mapping §2 screen 06). Renders Arabic RTL +
/// transliteration + translation as three distinct layers, an audio strip bound
/// to the real [audioControllerProvider], floating reader controls, the
/// "Practice this lesson" CTA, and the visible QF attribution.
///
/// Presentational: all content comes from the backend; no progression logic.
/// Font size is local UI state; the reading view is a saved device setting.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.lessonId});

  final int lessonId;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  // Local-only reader preferences (no controller/API involvement).
  double _fontScale = 1.0;

  final _itemScroll = ItemScrollController();
  final _itemPositions = ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    // Hand the lesson's audio block (reciter, clip, timings) to the player
    // once the lesson is loaded. Deferred: providers must not change mid-build.
    ref.listenManual(lessonProvider(widget.lessonId), (_, next) {
      final lesson = next.valueOrNull;
      if (lesson == null) return;
      Future.microtask(() {
        if (mounted) {
          ref.read(audioControllerProvider.notifier).loadLesson(lesson.audio);
        }
      });
    }, fireImmediately: true);
  }

  void _scrollToVerse(String? verseKey) {
    final lesson = ref.read(lessonProvider(widget.lessonId)).valueOrNull;
    if (lesson == null || verseKey == null) return;
    final index = lesson.ayahs.indexWhere((a) => a.verseKey == verseKey);
    if (index < 0 || !_itemScroll.isAttached) return;
    _itemScroll.scrollTo(
      index: index,
      alignment: 0.05,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  void _onRecitedAyahChanged(AudioState? prev, AudioState next) {
    if (next.verseKey == null || next.verseKey == prev?.verseKey) return;
    final lesson = ref.read(lessonProvider(widget.lessonId)).valueOrNull;
    if (lesson == null) return;
    final index = lesson.ayahs.indexWhere((a) => a.verseKey == next.verseKey);
    if (shouldScrollToAyah(
      playAll: next.isPlayingAll,
      following: ref.read(readerFollowProvider),
      index: index,
      visible: _itemPositions.itemPositions.value,
    )) {
      _scrollToVerse(next.verseKey);
    }
  }

  void _onPlayAllPressed(List<AyahAudio> queue, AudioState audio) {
    // Starting play-all (not pausing it) resumes following.
    if (!(audio.isPlayingAll && audio.playing)) {
      ref.read(readerFollowProvider.notifier).resume();
    }
    ref.read(audioControllerProvider.notifier).playAll(queue);
  }

  void _followRecitation() {
    ref.read(readerFollowProvider.notifier).resume();
    _scrollToVerse(ref.read(audioControllerProvider).verseKey);
  }

  void _decreaseFont() =>
      setState(() => _fontScale = (_fontScale - 0.1).clamp(0.8, 1.6));
  void _increaseFont() =>
      setState(() => _fontScale = (_fontScale + 0.1).clamp(0.8, 1.6));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lessonAsync = ref.watch(lessonProvider(widget.lessonId));
    final audio = ref.watch(audioControllerProvider);
    final following = ref.watch(readerFollowProvider);
    final displayMode = ref.watch(readerDisplayModeProvider).valueOrNull ??
        ReaderDisplayMode.full;

    ref.listen(audioControllerProvider, _onRecitedAyahChanged);

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
          // The big play button recites every ayah on this screen in order.
          final queue = [
            for (final a in lesson.ayahs)
              if (a.audioUrl != null)
                AyahAudio(verseKey: a.verseKey, url: a.audioUrl!),
          ];
          final isPlayingAll = audio.isPlayingAll && audio.playing;
          final isLoadingAll = audio.isPlayingAll && audio.loading;

          // Heading comes from the lesson's own backend metadata (so each surah
          // shows correctly). Prefer the Arabic surah name; fall back to title.
          final surahTitle =
              lesson.surahNameAr.isNotEmpty ? lesson.surahNameAr : lesson.title;
          final reciter = lesson.audio?.reciter.name ?? '';
          final reciterLabel =
              reciter.isEmpty ? lesson.ayahRange : '$reciter • ${lesson.ayahRange}';

          return Stack(
            children: [
              Column(
                children: [
                  AudioStrip(
                    surahTitle: surahTitle,
                    reciterLabel: reciterLabel,
                    playing: isPlayingAll,
                    loading: isLoadingAll,
                    looping: audio.looping,
                    progress: audio.isPlayingAll ? audio.progress : 0,
                    onPlayPause: (queue.isEmpty && !(lesson.audio?.isChapter ?? false))
                        ? null
                        : () => _onPlayAllPressed(queue, audio),
                    onToggleLoop: () =>
                        ref.read(audioControllerProvider.notifier).toggleLoop(),
                  ),
                  ReciterFallbackNotice(audio: lesson.audio),
                  Expanded(
                    child: NotificationListener<ScrollStartNotification>(
                      onNotification: (n) {
                        // A drag by the learner (not our own scrollTo) stops following.
                        if (n.dragDetails != null) {
                          ref.read(readerFollowProvider.notifier).userScrolled();
                        }
                        return false;
                      },
                      child: ScrollablePositionedList.builder(
                        itemScrollController: _itemScroll,
                        itemPositionsListener: _itemPositions,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: lesson.ayahs.length + 1,
                        itemBuilder: (context, i) {
                          if (i < lesson.ayahs.length) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: AyahCard(
                                ayah: lesson.ayahs[i],
                                fontScale: _fontScale,
                                displayMode: displayMode,
                                noWordHighlightNote: lesson.audio != null &&
                                    !lesson.audio!.hasWordTimings,
                              ),
                            );
                          }
                          return Column(
                            children: [
                              if (lesson.exercises.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                FilledButton.icon(
                                  onPressed: () => context
                                      .push('/lesson/${lesson.id}/practice'),
                                  icon: const Icon(Icons.quiz),
                                  label: const Text('Practice this lesson'),
                                ),
                              ],
                              const SizedBox(height: 16),
                              // Visible Quran Foundation attribution (QF terms).
                              Text(
                                lesson.attribution,
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              if (audio.isPlayingAll && !following)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 72,
                  child: Center(
                    child: FilledButton.icon(
                      key: const Key('follow_recitation'),
                      onPressed: _followRecitation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Follow recitation'),
                    ),
                  ),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Center(
                  child: ReaderFloatingControls(
                    onDecreaseFont: _decreaseFont,
                    onIncreaseFont: _increaseFont,
                    onOpenView: () => showReaderDisplaySheet(context),
                  ),
                ),
              ),
            ],
          );
        },
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
