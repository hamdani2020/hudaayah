import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudaayah/features/quran_reader/application/audio_controller.dart';
import 'package:hudaayah/features/quran_reader/data/lesson_models.dart';
import 'package:hudaayah/features/quran_reader/presentation/ayah_card.dart';

/// Holds a fixed [AudioState]; never touches the player.
class _FakeAudio extends AudioController {
  _FakeAudio(this._initial);
  final AudioState _initial;

  @override
  AudioState build() => _initial;
}

// Placeholder tokens stand in for QF word text; the card only joins and
// compares strings, so no Quran text is needed in tests.
const _w = ['w1', 'w2', 'w3'];

Ayah _ayah({List<int?> positions = const [1, 2, 3], String? arabic}) => Ayah(
      verseKey: '1:1',
      arabic: arabic ?? _w.join(' '),
      audioUrl: 'https://example.test/a.mp3',
      words: [
        for (var i = 0; i < _w.length; i++)
          WordPiece(position: positions[i], arabic: _w[i], transliteration: 't$i'),
      ],
    );

Future<void> _pump(
  WidgetTester tester,
  Ayah ayah,
  AudioState audio, {
  bool note = false,
}) async {
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(),
    overrides: [audioControllerProvider.overrideWith(() => _FakeAudio(audio))],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AyahCard(ayah: ayah, noWordHighlightNote: note),
        ),
      ),
    ),
  ));
}

/// The Arabic line: the Text.rich whose root span has per-word children.
List<TextSpan> _arabicSpans(WidgetTester tester) {
  final rich = tester.widgetList<RichText>(find.byType(RichText)).firstWhere(
        (r) => r.text.toPlainText().contains('w1'),
      );
  // Text.rich wraps our span in a root span.
  final ours = (rich.text as TextSpan).children!.single as TextSpan;
  return ours.children!.cast<TextSpan>();
}

bool _highlighted(TextSpan s) => s.style?.backgroundColor != null;

void main() {
  testWidgets('highlights only the span of the current word', (tester) async {
    await _pump(tester, _ayah(),
        const AudioState(verseKey: '1:1', currentWordPosition: 2, playing: true));
    final spans = _arabicSpans(tester);
    final words = spans.where((s) => _w.contains(s.text)).toList();
    expect(words.map((s) => s.text), _w);
    expect(words.map(_highlighted), [false, true, false]);
  });

  testWidgets('text is unchanged by splitting into word spans', (tester) async {
    await _pump(tester, _ayah(), const AudioState());
    final rich = tester.widgetList<RichText>(find.byType(RichText)).firstWhere(
          (r) => r.text.toPlainText().contains('w1'),
        );
    expect(rich.text.toPlainText(), startsWith('w1 w2 w3 '));
  });

  testWidgets('no highlight when another ayah is playing', (tester) async {
    await _pump(tester, _ayah(),
        const AudioState(verseKey: '1:2', currentWordPosition: 2, playing: true));
    expect(_arabicSpans(tester).any(_highlighted), isFalse);
  });

  testWidgets('a word with no matching position never highlights',
      (tester) async {
    // Position 9 has no word (e.g. a word without a segment keeps no highlight).
    await _pump(tester, _ayah(),
        const AudioState(verseKey: '1:1', currentWordPosition: 9));
    expect(_arabicSpans(tester).any(_highlighted), isFalse);
  });

  testWidgets('falls back to the verse text as one piece without positions',
      (tester) async {
    await _pump(tester, _ayah(positions: [null, null, null]),
        const AudioState(verseKey: '1:1', currentWordPosition: 2));
    final spans = _arabicSpans(tester);
    expect(spans.first.text, 'w1 w2 w3');
    expect(spans.any(_highlighted), isFalse);
  });

  testWidgets('falls back when the words do not reproduce the verse text',
      (tester) async {
    await _pump(tester, _ayah(arabic: 'w1 w2 other'),
        const AudioState(verseKey: '1:1', currentWordPosition: 2));
    expect(_arabicSpans(tester).first.text, 'w1 w2 other');
  });

  testWidgets('highlights the matching word chip', (tester) async {
    await _pump(tester, _ayah(),
        const AudioState(verseKey: '1:1', currentWordPosition: 3));
    final colours = tester
        .widgetList<Container>(find.ancestor(
          of: find.text('t2'),
          matching: find.byType(Container),
        ))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .map((d) => d.color)
        .toSet();
    final other = tester
        .widgetList<Container>(find.ancestor(
          of: find.text('t0'),
          matching: find.byType(Container),
        ))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .map((d) => d.color)
        .toSet();
    expect(colours, isNot(equals(other)));
  });

  testWidgets('shows the note only while this ayah plays and timings are absent',
      (tester) async {
    const note = "Word highlighting isn't available for this reciter.";
    await _pump(tester, _ayah(),
        const AudioState(verseKey: '1:1', playing: true),
        note: true);
    expect(find.text(note), findsOneWidget);

    await _pump(tester, _ayah(), const AudioState(verseKey: '1:1'), note: true);
    expect(find.text(note), findsNothing);

    await _pump(tester, _ayah(),
        const AudioState(verseKey: '1:1', playing: true));
    expect(find.text(note), findsNothing);
  });
}
