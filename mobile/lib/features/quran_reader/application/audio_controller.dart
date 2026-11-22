import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

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
  final AudioMode mode;
  final bool playing;
  final bool looping;
  final bool loading;
  final String? error;

  const AudioState({
    this.verseKey,
    this.mode = AudioMode.single,
    this.playing = false,
    this.looping = false,
    this.loading = false,
    this.error,
  });

  bool get isPlayingAll => mode == AudioMode.all;

  AudioState copyWith({
    String? verseKey,
    AudioMode? mode,
    bool? playing,
    bool? looping,
    bool? loading,
    String? error,
    bool clearError = false,
    bool clearVerseKey = false,
  }) =>
      AudioState(
        verseKey: clearVerseKey ? null : (verseKey ?? this.verseKey),
        mode: mode ?? this.mode,
        playing: playing ?? this.playing,
        looping: looping ?? this.looping,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Ayah-level audio with play/pause and repeat/loop — core to memorization
/// (flutter-feature: audio repeat/loop) — plus "play all" for the whole reader
/// screen. Presentational widgets call these methods; no scoring/progress logic.
///
/// Loop applies to whatever is playing: one ayah in single mode, the whole
/// sequence in play-all mode.
class AudioController extends Notifier<AudioState> {
  final AudioPlayer _player = AudioPlayer();

  /// verse_keys of the play-all queue, in the order loaded into the player.
  List<String> _queueKeys = const [];

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
      // In play-all mode, follow the ayah being recited so its card is highlighted.
      _player.currentIndexStream.listen((index) {
        if (state.mode != AudioMode.all || index == null) return;
        if (index >= 0 && index < _queueKeys.length) {
          state = state.copyWith(verseKey: _queueKeys[index]);
        }
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

  /// Plays or pauses one ayah. If play-all is active, it stops and this ayah
  /// plays on its own.
  Future<void> playAyah(String verseKey, String url) async {
    try {
      final needsLoad =
          state.mode != AudioMode.single || state.verseKey != verseKey;
      if (needsLoad) {
        state = state.copyWith(
            loading: true, mode: AudioMode.single, verseKey: verseKey, clearError: true);
        await _player.stop();
        await _player.setUrl(url);
        _queueKeys = const [];
        state = state.copyWith(
            verseKey: verseKey, mode: AudioMode.single, loading: false);
      }
      await _player.setLoopMode(state.looping ? LoopMode.one : LoopMode.off);
      await _togglePlayback(restartFromIndex: 0, restart: needsLoad);
    } catch (e, st) {
      _fail('Audio error for $verseKey ($url)', e, st);
    }
  }

  /// Plays every ayah in [ayahs] in order, or pauses/resumes if play-all is
  /// already loaded with the same ayahs.
  Future<void> playAll(List<AyahAudio> ayahs) async {
    if (ayahs.isEmpty) return;
    final keys = [for (final a in ayahs) a.verseKey];
    try {
      final needsLoad =
          state.mode != AudioMode.all || !listEquals(keys, _queueKeys);
      if (needsLoad) {
        state = state.copyWith(
            loading: true, mode: AudioMode.all, verseKey: keys.first, clearError: true);
        await _player.stop();
        await _player.setAudioSources(
          [for (final a in ayahs) AudioSource.uri(Uri.parse(a.url))],
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

  Future<void> toggleLoop() async {
    final looping = !state.looping;
    state = state.copyWith(looping: looping);
    final mode = !looping
        ? LoopMode.off
        : (state.mode == AudioMode.all ? LoopMode.all : LoopMode.one);
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
          index: state.mode == AudioMode.all ? restartFromIndex : null);
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
