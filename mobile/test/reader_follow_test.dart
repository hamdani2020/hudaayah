import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudaayah/features/quran_reader/application/audio_controller.dart';
import 'package:hudaayah/features/quran_reader/application/reader_follow.dart';
import 'package:hudaayah/features/quran_reader/presentation/widgets/audio_strip.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

ItemPosition pos(int i, double a, double b) =>
    ItemPosition(index: i, itemLeadingEdge: a, itemTrailingEdge: b);

void main() {
  group('shouldScrollToAyah', () {
    test('play-all scrolls when the ayah is off screen and following', () {
      expect(
          shouldScrollToAyah(
              playAll: true, following: true, index: 3, visible: [pos(0, 0, 0.5)]),
          isTrue);
    });
    test('play-all does not scroll after a manual scroll', () {
      expect(
          shouldScrollToAyah(
              playAll: true, following: false, index: 3, visible: const []),
          isFalse);
    });
    test('play-all does not scroll when the ayah is fully visible', () {
      expect(
          shouldScrollToAyah(
              playAll: true, following: true, index: 1, visible: [pos(1, 0.2, 0.7)]),
          isFalse);
    });
    test('play-all scrolls when the ayah is partly cut off', () {
      expect(
          shouldScrollToAyah(
              playAll: true, following: true, index: 1, visible: [pos(1, 0.6, 1.3)]),
          isTrue);
    });
    test('single ayah scrolls only when completely off screen', () {
      expect(
          shouldScrollToAyah(
              playAll: false, following: false, index: 1, visible: [pos(1, 0.6, 1.3)]),
          isFalse);
      expect(
          shouldScrollToAyah(
              playAll: false, following: false, index: 5, visible: [pos(1, 0, 1)]),
          isTrue);
    });
  });

  test('ReaderFollow: scroll stops following, resume restores it', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.listen(readerFollowProvider, (_, _) {});
    expect(c.read(readerFollowProvider), isTrue);
    c.read(readerFollowProvider.notifier).userScrolled();
    expect(c.read(readerFollowProvider), isFalse);
    c.read(readerFollowProvider.notifier).resume();
    expect(c.read(readerFollowProvider), isTrue);
  });

  test('AudioState.progress is position / duration, clamped', () {
    expect(const AudioState().progress, 0);
    expect(
        const AudioState(
                position: Duration(seconds: 12), duration: Duration(seconds: 48))
            .progress,
        0.25);
    expect(
        const AudioState(
                position: Duration(seconds: 60), duration: Duration(seconds: 48))
            .progress,
        1.0);
  });

  testWidgets('AudioStrip shows the progress value and reciter label',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AudioStrip(
          surahTitle: 'Title',
          reciterLabel: 'Some Reciter • Ayah 1–7',
          playing: true,
          loading: false,
          looping: false,
          progress: 0.4,
          onPlayPause: () {},
          onToggleLoop: () {},
        ),
      ),
    ));
    final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('audio_progress')));
    expect(bar.value, 0.4);
    expect(find.text('Some Reciter • Ayah 1–7'), findsOneWidget);
  });
}
