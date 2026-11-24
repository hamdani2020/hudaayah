import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudaayah/features/authentication/application/auth_controller.dart';
import 'package:hudaayah/features/profile/application/reminder_controller.dart';
import 'package:hudaayah/features/profile/data/reciter_repository.dart';
import 'package:hudaayah/features/profile/presentation/profile_screen.dart';
import 'package:hudaayah/features/progress/data/progress_models.dart';
import 'package:hudaayah/features/progress/data/progress_repository.dart';
import 'package:hudaayah/features/quran_reader/application/reader_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuth extends AuthController {
  @override
  Future<AuthState> build() async => const AuthState();
}

class _FakeReminder extends ReminderController {
  @override
  Future<ReminderSettings> build() async => ReminderSettings.initial;
}

class _FakeReciter extends SelectedReciterController {
  @override
  Future<int?> build() async => null;
}

void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_FakeAuth.new),
        reminderControllerProvider.overrideWith(_FakeReminder.new),
        selectedReciterProvider.overrideWith(_FakeReciter.new),
        progressSummaryProvider.overrideWith(
          (ref) => Completer<ProgressSummary>().future,
        ),
        recitersProvider.overrideWith((ref) => Completer<List<Reciter>>().future),
      ],
    );
    addTearDown(container.dispose);
    await tester.runAsync(
      () => container.read(readerDisplayModeProvider.future),
    );
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pump();
    return container;
  }

  testWidgets('Reading view row shows the saved mode and opens the sheet', (
    tester,
  ) async {
    await pump(
      tester,
      prefs: {ReaderDisplayModeNotifier.prefsKey: 'arabicTranslation'},
    );
    expect(find.text('Reading view'), findsOneWidget);
    expect(find.text('Arabic + translation'), findsOneWidget);
    // The static translation row stays as information.
    expect(find.text('Saheeh International'), findsOneWidget);

    await tester.tap(find.text('Reading view'));
    await tester.pumpAndSettle();
    expect(find.text('Reading view'), findsNWidgets(2));
    for (final m in ReaderDisplayMode.values) {
      expect(find.byKey(Key('reader_view_${m.name}')), findsOneWidget);
    }
  });

  testWidgets('choosing a mode in the sheet updates the row subtitle', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Full'), findsOneWidget);
    await tester.tap(find.text('Reading view'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reader_view_arabicOnly')));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    // Close the sheet so only the Profile row can show the label.
    Navigator.of(tester.element(find.byType(ProfileScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Full'), findsNothing);
    expect(find.text('Arabic only'), findsOneWidget);
  });
}
