import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hudaayah/features/quran_reader/application/reader_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to full when nothing is stored', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(await c.read(readerDisplayModeProvider.future),
        ReaderDisplayMode.full);
  });

  test('setMode persists and a new container reads it back', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(readerDisplayModeProvider.future);
    await c
        .read(readerDisplayModeProvider.notifier)
        .setMode(ReaderDisplayMode.arabicOnly);
    expect(c.read(readerDisplayModeProvider).value,
        ReaderDisplayMode.arabicOnly);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('reader.display_mode'), 'arabicOnly');

    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    expect(await c2.read(readerDisplayModeProvider.future),
        ReaderDisplayMode.arabicOnly);
  });

  test('unknown stored value falls back to full', () async {
    SharedPreferences.setMockInitialValues({'reader.display_mode': 'bogus'});
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(await c.read(readerDisplayModeProvider.future),
        ReaderDisplayMode.full);
  });
}
