import 'package:flutter_test/flutter_test.dart';
import 'package:hudaayah/features/quran_reader/data/lesson_audio.dart';

// Word 2 of 2:1 has no segment on purpose.
const _v1 = VerseAudio(
  verseKey: '2:1',
  startMs: 1000,
  endMs: 3000,
  words: [WordTiming(1, 1000, 1800), WordTiming(3, 2000, 3000)],
);
const _v2 = VerseAudio(
  verseKey: '2:2',
  startMs: 3000,
  endMs: 5000,
  words: [],
);

void main() {
  group('AudioTimeline.at', () {
    final t = AudioTimeline([_v2, _v1]); // unsorted input

    test('before the first verse: nothing', () {
      final p = t.at(500);
      expect(p.verseKey, isNull);
      expect(p.wordPosition, isNull);
    });

    test('maps position to verse and word', () {
      expect(t.at(1000).verseKey, '2:1');
      expect(t.at(1000).wordPosition, 1);
      expect(t.at(1799).wordPosition, 1);
      expect(t.at(2500).wordPosition, 3);
    });

    test('gap keeps the previous word; missing word 2 is never returned', () {
      final seen = {for (var ms = 1000; ms < 3000; ms += 50) t.at(ms).wordPosition};
      expect(seen, {1, 3});
      expect(t.at(1900).wordPosition, 1);
    });

    test('verse boundary switches verse', () {
      expect(t.at(2999).verseKey, '2:1');
      expect(t.at(3000).verseKey, '2:2');
    });

    test('verse without word timings gives a verse but no word', () {
      final p = t.at(4000);
      expect(p.verseKey, '2:2');
      expect(p.wordPosition, isNull);
    });

    test('empty timeline does not crash', () {
      expect(AudioTimeline(const []).at(1000).verseKey, isNull);
    });
  });

  group('LessonAudio.tryParse', () {
    test('parses chapter mode and skips malformed word entries', () {
      final a = LessonAudio.tryParse({
        'reciter': {'id': 7, 'name': 'Mishari', 'style': ''},
        'mode': 'chapter',
        'chapter_url': 'https://example.test/2.mp3',
        'clip_start_ms': 1000,
        'clip_end_ms': 5000,
        'has_word_timings': true,
        'verses': [
          {
            'verse_key': '2:1',
            'start_ms': 1000,
            'end_ms': 3000,
            'words': [
              [1, 1000, 1800],
              [2, 'x', 2000],
              [3, 2000],
            ],
          },
        ],
      })!;
      expect(a.isChapter, isTrue);
      expect(a.verse('2:1')!.words.length, 1);
      expect(a.verse('9:9'), isNull);
    });

    test('per-ayah mode keeps audio_url', () {
      final a = LessonAudio.tryParse({
        'reciter': {'id': 1, 'name': 'R'},
        'mode': 'per_ayah',
        'verses': [
          {'verse_key': '1:1', 'audio_url': 'https://example.test/1.mp3'}
        ],
      })!;
      expect(a.isChapter, isFalse);
      expect(a.verse('1:1')!.audioUrl, isNotNull);
    });

    test('malformed or missing block returns null', () {
      expect(LessonAudio.tryParse(null), isNull);
      expect(LessonAudio.tryParse({'mode': 'chapter'}), isNull);
    });
  });
}
