# Quran font (Uthmani)

The reader renders ayat with the font family `UthmanicHafs`
(`lib/features/quran_reader/presentation/ayah_card.dart`).

## To enable the proper Uthmani face

1. Obtain the licensed **KFGQPC Uthmanic Hafs** font (King Fahd Glorious Quran
   Printing Complex). Per steering (tech.md), Quran fonts **may** be bundled with
   attribution and an active Quran Foundation Developer Console account.
2. Place the file here as:
   ```
   assets/fonts/UthmanicHafs.ttf
   ```
3. Uncomment the `fonts:` block in `mobile/pubspec.yaml`, then:
   ```
   flutter pub get
   ```

## Until the font is added

The build intentionally does **not** reference a missing asset (the `fonts:` block
is commented out), so `flutter pub get` and `flutter run` work. The ayah text falls
back to the default system font — Arabic still renders RTL with correct diacritics,
just not in the Uthmani typeface.

## Rules
- Never alter, subset-in-a-way-that-corrupts, or modify the Quran glyphs.
- Keep attribution for the font per its license and QF terms.
