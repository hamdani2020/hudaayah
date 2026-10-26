import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// Snapshot of audio playback for the reader UI.
class AudioState {
  /// verse_key currently loaded, or null.
  final String? verseKey;
  final bool playing;
  final bool looping;
  final bool loading;
  final String? error;

  const AudioState({
    this.verseKey,
    this.playing = false,
    this.looping = false,
    this.loading = false,
    this.error,
  });

  AudioState copyWith({
    String? verseKey,
    bool? playing,
    bool? looping,
    bool? loading,
    String? error,
    bool clearError = false,
  }) =>
      AudioState(
        verseKey: verseKey ?? this.verseKey,
        playing: playing ?? this.playing,
        looping: looping ?? this.looping,
        loading: loading ?? this.loading,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Ayah-level audio with play/pause and repeat/loop — core to memorization
/// (flutter-feature: audio repeat/loop). Presentational widgets call these
/// methods; no scoring/progress logic here.
class AudioController extends Notifier<AudioState> {
  final AudioPlayer _player = AudioPlayer();

  @override
  AudioState build() {
    _player.playerStateStream.listen((s) {
      // A finished track reports processingState=completed while `playing`
      // can remain true. Treat completion as "not playing" so the UI flips the
      // button back to play.
      final isPlaying = s.playing && s.processingState != ProcessingState.completed;
      state = state.copyWith(playing: isPlaying);
    });
    ref.onDispose(_player.dispose);
    return const AudioState();
  }

  Future<void> playAyah(String verseKey, String url) async {
    try {
      if (state.verseKey != verseKey) {
        state = state.copyWith(loading: true, clearError: true);
        await _player.setUrl(url);
        state = state.copyWith(verseKey: verseKey, loading: false);
      }
      await _player.setLoopMode(state.looping ? LoopMode.one : LoopMode.off);
      if (_player.playing) {
        await _player.pause();
      } else {
        if (_player.processingState == ProcessingState.completed) {
          await _player.seek(Duration.zero);
        }
        await _player.play();
      }
    } catch (e, st) {
      // Surface load/playback failures instead of silently doing nothing.
      debugPrint('Audio error for $verseKey ($url): $e');
      debugPrintStack(stackTrace: st);
      state = state.copyWith(
        loading: false,
        playing: false,
        error: 'Could not play audio. Check your connection.',
      );
    }
  }

  Future<void> toggleLoop() async {
    final looping = !state.looping;
    state = state.copyWith(looping: looping);
    await _player.setLoopMode(looping ? LoopMode.one : LoopMode.off);
  }

  Future<void> stop() async {
    await _player.stop();
    state = state.copyWith(playing: false);
  }
}

final audioControllerProvider =
    NotifierProvider<AudioController, AudioState>(AudioController.new);
