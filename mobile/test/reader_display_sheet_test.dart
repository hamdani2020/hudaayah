import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudaayah/features/quran_reader/application/reader_settings.dart';
import 'package:hudaayah/features/quran_reader/presentation/widgets/reader_display_sheet.dart';
import 'package:hudaayah/features/quran_reader/presentation/widgets/reader_floating_controls.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(
      () => container.read(readerDisplayModeProvider.future),
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ReaderFloatingControls(
                  onDecreaseFont: () {},
                  onIncreaseFont: () {},
                  onOpenView: () => showReaderDisplaySheet(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return container;
  }

  ReaderDisplayMode? ticked(WidgetTester tester) => tester
      .widget<RadioGroup<ReaderDisplayMode>>(
        find.byType(RadioGroup<ReaderDisplayMode>),
      )
      .groupValue;

  testWidgets('the View button replaces the translation toggle', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('View'), findsOneWidget);
    expect(find.text('Translation'), findsNothing);
  });

  testWidgets(
    'View opens the sheet with three options; Full ticked by default',
    (tester) async {
      await pump(tester);
      await tester.tap(find.text('View'));
      await tester.pumpAndSettle();
      expect(find.text('Reading view'), findsOneWidget);
      for (final m in ReaderDisplayMode.values) {
        expect(find.byKey(Key('reader_view_${m.name}')), findsOneWidget);
      }
      expect(ticked(tester), ReaderDisplayMode.full);
    },
  );

  testWidgets('ticks the saved mode', (tester) async {
    await pump(
      tester,
      prefs: {ReaderDisplayModeNotifier.prefsKey: 'arabicTranslation'},
    );
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    expect(ticked(tester), ReaderDisplayMode.arabicTranslation);
  });

  testWidgets('choosing an option saves it through the notifier', (
    tester,
  ) async {
    final container = await pump(tester);
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reader_view_arabicOnly')));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(
      container.read(readerDisplayModeProvider).value,
      ReaderDisplayMode.arabicOnly,
    );
    expect(ticked(tester), ReaderDisplayMode.arabicOnly);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(ReaderDisplayModeNotifier.prefsKey), 'arabicOnly');
  });
}
