import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../data/lesson_audio.dart';

/// What is loaded in the player.
enum AudioMode {
  /// A single ayah (the small per-ayah buttons).
  single,

  /// Every ayah on the reader screen, in order (the big play button).
  all,
}

/// One ayah's recitation, used to build the play-all queue.
class AyahAudio {
  final String verseKey;
  final String url;

  const AyahAudio({required this.verseKey, required this.url});
}

/// Snapshot of audio playback for the reader UI.
class AudioState {
  /// verse_key of the ayah currently loaded or being recited, or null.
  final String? verseKey;

  /// QF word `position` being recited, or null (no timings, or no segment yet).
  final int? currentWordPosition;
  final AudioMode mode;
  final bool playing;
  final bool looping;
  final bool loading;
  final String? error;

  /// Position and length of the loaded clip (not the whole chapter file).
  final Duration position;
  final Duration duration;

  const AudioState({
    this.verseKey,
    this.currentWordPosition,
    this.mode = AudioMode.single,
    this.playing = false,
    this.looping = false,
    this.loading = false,
    this.error,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  String? get currentVerseKey => verseKey;

  /// Fraction (0–1) of the loaded clip played; 0 when the length is unknown.
  double get progress {
    final total = duration.inMilliseconds;
    if (total <= 0) return 0;
    return (position.inMilliseconds / total).clamp(0.0, 1.0);
  }
  bool get isPlayingAll => mode == AudioMode.all;

  AudioState copyWith({
    String? verseKey,
    int? currentWordPosition,
    AudioMode? mode,
    bool? playing,
    bool? looping,
    bool? loading,
    String? error,
    Duration? position,
    Duration? duration,
    bool clearError = false,
    bool clearVerseKey = false,
    bool clearWord = false,
  }) =>
      AudioState(
        verseKey: clearVerseKey ? null : (verseKey ?? this.verseKey),
        currentWordPosition:
            clearWord ? null : (currentWordPosition ?? this.currentWordPosition),
        mode: mode ?? this.mode,
        playing: playing ?? this.playing,
        looping: looping ?? this.looping,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
        position: position ?? this.position,
        duration: duration ?? this.duration,
      );
}

/// Ayah-level audio with play/pause and repeat/loop — core to memorization
/// (flutter-feature: audio repeat/loop) — plus "play all" for the whole reader
/// screen. Presentational widgets call these methods; no scoring/progress logic.
///
/// With a chapter-mode [LessonAudio] (see [loadLesson]) one clipped chapter file
/// plays: a single ayah clips to that verse, play-all clips to the lesson range,
/// and the current verse/word come from the player position. Otherwise it falls
/// back to the per-ayah files, with ayah-level highlighting only.
///
/// Loop applies to whatever is playing: the clip in chapter mode, one ayah in
/// per-ayah single mode, or the whole sequence in per-ayah play-all.
class AudioController extends Notifier<AudioState> {
  final AudioPlayer _player = AudioPlayer();

  LessonAudio? _audio;

  /// verse_keys of the per-ayah play-all queue, in the order loaded.
  List<String> _queueKeys = const [];

  /// Chapter mode: what the loaded clip is, and where it starts in the file.
  String? _clipKey; // verse_key, or '*' for the whole lesson range
  int _clipOffsetMs = 0;
  AudioTimeline? _timeline;

  @override
  AudioState build() {
    final subs = <StreamSubscription<dynamic>>[
      _player.playerStateStream.listen((s) {
        // A finished track reports processingState=completed while `playing`
        // can remain true. Treat completion as "not playing" so the UI flips
        // the button back to play.
        final isPlaying =
            s.playing && s.processingState != ProcessingState.completed;
        state = state.copyWith(playing: isPlaying);
      }),
      // Per-ayah play-all: follow the ayah being recited.
      _player.currentIndexStream.listen((index) {
        if (_timeline != null || state.mode != AudioMode.all || index == null) {
          return;
        }
        if (index >= 0 && index < _queueKeys.length) {
          state = state.copyWith(verseKey: _queueKeys[index]);
        }
      }),
      _player
          .createPositionStream(
            minPeriod: const Duration(milliseconds: 100),
            maxPeriod: const Duration(milliseconds: 100),
          )
          .listen(_onPosition),
      _player.durationStream.listen((d) {
        if (d != null) state = state.copyWith(duration: d);
      }),
    ];
    ref.onDispose(() {
      for (final s in subs) {
        s.cancel();
      }
      _player.dispose();
    });
    return const AudioState();
  }

  /// Gives the controller the lesson's audio block. A different lesson or
  /// reciter stops playback; pass null to use per-ayah URLs only.
  Future<void> loadLesson(LessonAudio? audio) async {
    if (identical(audio, _audio)) return;
    _audio = audio;
    _clipKey = null;
    _timeline = null;
    _queueKeys = const [];
    await _player.stop();
    state = state.copyWith(
      playing: false,
      mode: AudioMode.single,
      position: Duration.zero,
      duration: Duration.zero,
      clearVerseKey: true,
      clearWord: true,
      clearError: true,
    );
  }

  void _onPosition(Duration pos) {
    final timeline = _timeline;
    if (timeline == null) {
      state = state.copyWith(position: pos);
      return;
    }
    final at = timeline.at(_clipOffsetMs + pos.inMilliseconds);
    if (state.mode == AudioMode.all) {
      state = state.copyWith(
        position: pos,
        verseKey: at.verseKey,
        currentWordPosition: at.wordPosition,
        clearVerseKey: at.verseKey == null,
        clearWord: at.wordPosition == null,
      );
    } else {
      // Single ayah: the clip is one verse; only the word changes.
      state = state.copyWith(
        position: pos,
        currentWordPosition: at.wordPosition,
        clearWord: at.wordPosition == null,
      );
    }
  }

  /// Plays or pauses one ayah. If play-all is active, it stops and this ayah
  /// plays on its own. [url] is the per-ayah file, used when there is no
  /// chapter audio for this verse.
  Future<void> playAyah(String verseKey, [String? url]) async {
    final audio = _audio;
    final verse = audio?.verse(verseKey);
    try {
      if (audio != null && audio.isChapter && verse != null) {
        await _playChapterClip(
          key: verseKey,
          mode: AudioMode.single,
          startMs: verse.startMs,
          endMs: verse.endMs,
          timeline: AudioTimeline([verse]),
        );
        return;
      }
      final perAyahUrl = verse?.audioUrl ?? url;
      if (perAyahUrl == null) {
        _fail('No audio for $verseKey', 'missing url', StackTrace.current);
        return;
      }
      final needsLoad = _timeline != null ||
          state.mode != AudioMode.single ||
          state.verseKey != verseKey;
      if (needsLoad) {
        _timeline = null;
        _clipKey = null;
        state = state.copyWith(
            loading: true,
            mode: AudioMode.single,
            verseKey: verseKey,
            clearWord: true,
            clearError: true);
        await _player.stop();
        await _player.setUrl(perAyahUrl);
        _queueKeys = const [];
        state = state.copyWith(
            verseKey: verseKey, mode: AudioMode.single, loading: false);
      }
      await _player.setLoopMode(state.looping ? LoopMode.one : LoopMode.off);
      await _togglePlayback(restartFromIndex: 0, restart: needsLoad);
    } catch (e, st) {
      _fail('Audio error for $verseKey', e, st);
    }
  }

  /// Plays every ayah of the lesson in order, or pauses/resumes if already
  /// loaded. [fallback] is the legacy per-ayah list, used only when the lesson
  /// has no audio block.
  Future<void> playAll([List<AyahAudio> fallback = const []]) async {
    final audio = _audio;
    try {
      if (audio != null && audio.isChapter && audio.verses.isNotEmpty) {
        await _playChapterClip(
          key: '*',
          mode: AudioMode.all,
          startMs: audio.clipStartMs,
          endMs: audio.clipEndMs,
          timeline: AudioTimeline(audio.verses),
        );
        return;
      }
      final queue = [
        if (audio != null)
          for (final v in audio.verses)
            if (v.audioUrl != null)
              AyahAudio(verseKey: v.verseKey, url: v.audioUrl!),
        if (audio == null || audio.verses.every((v) => v.audioUrl == null))
          ...fallback,
      ];
      if (queue.isEmpty) return;
      final keys = [for (final a in queue) a.verseKey];
      final needsLoad = _timeline != null ||
          state.mode != AudioMode.all ||
          !listEquals(keys, _queueKeys);
      if (needsLoad) {
        _timeline = null;
        _clipKey = null;
        state = state.copyWith(
            loading: true,
            mode: AudioMode.all,
            verseKey: keys.first,
            clearWord: true,
            clearError: true);
        await _player.stop();
        await _player.setAudioSources(
          [for (final a in queue) AudioSource.uri(Uri.parse(a.url))],
          initialIndex: 0,
          initialPosition: Duration.zero,
        );
        _queueKeys = keys;
        state = state.copyWith(
            verseKey: keys.first, mode: AudioMode.all, loading: false);
      }
      await _player.setLoopMode(state.looping ? LoopMode.all : LoopMode.off);
      await _togglePlayback(restartFromIndex: 0, restart: needsLoad);
    } catch (e, st) {
      _fail('Audio error for play-all', e, st);
    }
  }

  Future<void> _playChapterClip({
    required String key,
    required AudioMode mode,
    required int startMs,
    required int endMs,
    required AudioTimeline timeline,
  }) async {
    final audio = _audio!;
    final needsLoad = _clipKey != key || state.mode != mode;
    if (needsLoad) {
      _clipKey = key;
      _clipOffsetMs = startMs;
      _timeline = timeline;
      _queueKeys = const [];
      state = state.copyWith(
        loading: true,
        mode: mode,
        verseKey: mode == AudioMode.single ? key : audio.verses.first.verseKey,
        clearWord: true,
        clearError: true,
        position: Duration.zero,
        duration: Duration(milliseconds: endMs - startMs),
      );
      await _player.stop();
      await _player.setAudioSource(ClippingAudioSource(
        child: AudioSource.uri(Uri.parse(audio.chapterUrl!)),
        start: Duration(milliseconds: startMs),
        end: Duration(milliseconds: endMs),
      ));
      state = state.copyWith(loading: false);
    }
    await _player.setLoopMode(state.looping ? LoopMode.one : LoopMode.off);
    await _togglePlayback(restartFromIndex: 0, restart: needsLoad);
  }

  Future<void> toggleLoop() async {
    final looping = !state.looping;
    state = state.copyWith(looping: looping);
    final mode = !looping
        ? LoopMode.off
        : (state.mode == AudioMode.all && _timeline == null
            ? LoopMode.all
            : LoopMode.one);
    await _player.setLoopMode(mode);
  }

  Future<void> stop() async {
    await _player.stop();
    state = state.copyWith(playing: false);
  }

  Future<void> _togglePlayback({
    required int restartFromIndex,
    required bool restart,
  }) async {
    if (!restart && _player.playing &&
        _player.processingState != ProcessingState.completed) {
      await _player.pause();
      return;
    }
    if (_player.processingState == ProcessingState.completed) {
      // Finished: start again from the first ayah (or the start of the single ayah).
      await _player.seek(Duration.zero,
          index: state.mode == AudioMode.all && _timeline == null
              ? restartFromIndex
              : null);
    }
    // Not awaited: play() completes only when playback stops.
    unawaited(_player.play());
  }

  void _fail(String context, Object e, StackTrace st) {
    // Surface load/playback failures instead of silently doing nothing.
    debugPrint('$context: $e');
    debugPrintStack(stackTrace: st);
    state = state.copyWith(
      loading: false,
      playing: false,
      error: 'Could not play audio. Check your connection.',
    );
  }
}

final audioControllerProvider =
    NotifierProvider<AudioController, AudioState>(AudioController.new);
