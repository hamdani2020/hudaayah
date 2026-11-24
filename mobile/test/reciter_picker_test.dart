import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudaayah/features/profile/data/reciter_repository.dart';
import 'package:hudaayah/features/profile/presentation/reciter_picker_sheet.dart';
import 'package:hudaayah/features/quran_reader/data/lesson_audio.dart';
import 'package:hudaayah/features/quran_reader/presentation/widgets/reciter_fallback_notice.dart';

class _FakeRepo extends ReciterRepository {
  _FakeRepo({this.saved, this.failSave = false}) : super(Dio());
  final int? saved;
  final bool failSave;
  final saves = <int>[];

  @override
  Future<List<Reciter>> fetchReciters() async => const [
        Reciter(id: 6, name: 'Husary', style: 'Murattal', hasTimings: true),
        Reciter(id: 7, name: 'Afasy', style: 'Murattal'),
      ];

  @override
  Future<int?> fetchSavedReciterId() async => saved;

  @override
  Future<void> saveReciterId(int id) async {
    if (failSave) throw Exception('offline');
    saves.add(id);
  }
}

Widget _app(_FakeRepo repo, Widget child) => ProviderScope(
      overrides: [reciterRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('ticks the saved reciter and marks word timings', (t) async {
    await t.pumpWidget(_app(_FakeRepo(saved: 6), const ReciterPickerSheet()));
    await t.pumpAndSettle();
    expect(find.text('Husary'), findsOneWidget);
    expect(find.text('Murattal · Word highlighting'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('reciter-6')),
            matching: find.byIcon(Icons.check)),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('reciter-7')),
            matching: find.byIcon(Icons.check)),
        findsNothing);
  });

  testWidgets('tapping a reciter saves it', (t) async {
    final repo = _FakeRepo(saved: 7);
    await t.pumpWidget(_app(repo, const ReciterPickerSheet()));
    await t.pumpAndSettle();
    await t.tap(find.text('Husary'));
    await t.pumpAndSettle();
    expect(repo.saves, [6]);
  });

  testWidgets('a failed save keeps the sheet and shows a message', (t) async {
    await t.pumpWidget(
        _app(_FakeRepo(saved: 7, failSave: true), const ReciterPickerSheet()));
    await t.pumpAndSettle();
    await t.tap(find.text('Husary'));
    await t.pumpAndSettle();
    expect(find.text('We could not save your choice. Please try again.'),
        findsOneWidget);
  });

  group('ReciterFallbackNotice', () {
    LessonAudio audio(int? from) => LessonAudio(
          reciter: const AudioReciter(id: 7, name: 'Afasy'),
          mode: LessonAudioMode.perAyah,
          verses: const [],
          fallbackFrom: from,
        );

    testWidgets('names both reciters when the choice was replaced', (t) async {
      await t.pumpWidget(
          _app(_FakeRepo(), ReciterFallbackNotice(audio: audio(6))));
      await t.pumpAndSettle();
      expect(
          find.textContaining('Husary is not available for this lesson'),
          findsOneWidget);
      expect(find.textContaining('default reciter, Afasy'), findsOneWidget);
    });

    testWidgets('shows nothing without a fallback', (t) async {
      await t.pumpWidget(
          _app(_FakeRepo(), ReciterFallbackNotice(audio: audio(null))));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('reciter-fallback-notice')),
          findsNothing);
    });
  });
}
