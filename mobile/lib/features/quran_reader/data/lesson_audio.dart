/// The lesson `audio` block (`GET /lessons/{id}/`) and the pure
/// position → verse/word mapping used by `AudioController`.
///
/// All times are absolute milliseconds in the chapter file. No Quran text lives
/// here, only timings and URLs.
library;

class AudioReciter {
  final int id;
  final String name;
  final String style;

  const AudioReciter({required this.id, required this.name, this.style = ''});

  factory AudioReciter.fromJson(Map<String, dynamic> j) => AudioReciter(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        style: j['style'] as String? ?? '',
      );
}

/// One word's segment: [position] is the QF word `position` (1-based).
class WordTiming {
  final int position;
  final int startMs;
  final int endMs;

  const WordTiming(this.position, this.startMs, this.endMs);
}

class VerseAudio {
  final String verseKey;

  /// Chapter-mode timings (absolute ms in the chapter file). Zero in per-ayah mode.
  final int startMs;
  final int endMs;

  /// Sorted by start. Words without a segment are simply absent.
  final List<WordTiming> words;

  /// Per-ayah mode only.
  final String? audioUrl;

  const VerseAudio({
    required this.verseKey,
    this.startMs = 0,
    this.endMs = 0,
    this.words = const [],
    this.audioUrl,
  });

  factory VerseAudio.fromJson(Map<String, dynamic> j) {
    final words = <WordTiming>[];
    for (final w in (j['words'] as List?) ?? const []) {
      // Ignore anything that is not exactly [index, start, end] numbers.
      if (w is List &&
          w.length == 3 &&
          w[0] is num &&
          w[1] is num &&
          w[2] is num) {
        words.add(WordTiming(
            (w[0] as num).toInt(), (w[1] as num).toInt(), (w[2] as num).toInt()));
      }
    }
    words.sort((a, b) => a.startMs.compareTo(b.startMs));
    return VerseAudio(
      verseKey: j['verse_key'] as String,
      startMs: (j['start_ms'] as num?)?.toInt() ?? 0,
      endMs: (j['end_ms'] as num?)?.toInt() ?? 0,
      words: words,
      audioUrl: j['audio_url'] as String?,
    );
  }
}

enum LessonAudioMode { chapter, perAyah }

class LessonAudio {
  final AudioReciter reciter;
  final LessonAudioMode mode;
  final String? chapterUrl;
  final int clipStartMs;
  final int clipEndMs;
  final bool hasWordTimings;
  final List<VerseAudio> verses;

  /// The reciter the learner chose, when a different one had to be used.
  final int? fallbackFrom;

  const LessonAudio({
    required this.reciter,
    required this.mode,
    required this.verses,
    this.chapterUrl,
    this.clipStartMs = 0,
    this.clipEndMs = 0,
    this.hasWordTimings = false,
    this.fallbackFrom,
  });

  bool get isChapter => mode == LessonAudioMode.chapter && chapterUrl != null;

  VerseAudio? verse(String verseKey) {
    for (final v in verses) {
      if (v.verseKey == verseKey) return v;
    }
    return null;
  }

  static LessonAudio? tryParse(Object? json) {
    if (json is! Map) return null;
    try {
      final j = json.cast<String, dynamic>();
      return LessonAudio(
        reciter:
            AudioReciter.fromJson((j['reciter'] as Map).cast<String, dynamic>()),
        mode: j['mode'] == 'chapter'
            ? LessonAudioMode.chapter
            : LessonAudioMode.perAyah,
        chapterUrl: j['chapter_url'] as String?,
        clipStartMs: (j['clip_start_ms'] as num?)?.toInt() ?? 0,
        clipEndMs: (j['clip_end_ms'] as num?)?.toInt() ?? 0,
        hasWordTimings: j['has_word_timings'] as bool? ?? false,
        fallbackFrom: j['fallback_from'] as int?,
        verses: [
          for (final v in (j['verses'] as List? ?? const []))
            VerseAudio.fromJson((v as Map).cast<String, dynamic>()),
        ],
      );
    } catch (_) {
      // A malformed block must never break the lesson; the reader falls back
      // to the per-ayah `audio_url`s.
      return null;
    }
  }
}

/// Where the player is, in verse/word terms.
class AudioPosition {
  final String? verseKey;
  final int? wordPosition;

  const AudioPosition(this.verseKey, this.wordPosition);
}

/// Position → verse/word lookup over chapter-mode timings.
class AudioTimeline {
  final List<VerseAudio> _verses; // sorted by startMs (stable)

  AudioTimeline(Iterable<VerseAudio> verses)
      : _verses = (verses.toList()..sort((a, b) => a.startMs.compareTo(b.startMs)));

  /// [absoluteMs] is a time in the chapter file.
  ///
  /// Verse: the latest verse whose start ≤ position (handles overlapping
  /// verses). Null before the first verse starts.
  /// Word: the latest word of that verse whose start ≤ position. A word without
  /// a segment is never returned; a gap keeps the previous word highlighted
  /// until the next segment starts. Null before the first segment.
  AudioPosition at(int absoluteMs) {
    var lo = 0, hi = _verses.length - 1, found = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (_verses[mid].startMs <= absoluteMs) {
        found = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    if (found < 0) return const AudioPosition(null, null);
    final verse = _verses[found];
    int? word;
    for (final w in verse.words) {
      if (w.startMs <= absoluteMs) {
        word = w.position;
      } else {
        break;
      }
    }
    return AudioPosition(verse.verseKey, word);
  }
}
