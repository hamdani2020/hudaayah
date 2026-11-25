# Design — Reader Display

## Cause of bug 1 (to confirm with a screenshot on device before changing)
Three sources each add a marker:
1. `AyahCard` appends `_endOfAyahMarker(verseKey)` after the Arabic.
2. `text_qpc_hafs` (used since the font change) already ends with the ayah-number marker.
3. `_extract_words` in `backend/apps/lessons/services.py` passes every QF word, including
   the `char_type_name == "end"` entry (the marker), which becomes a chip.

## Backend
- `get_word_by_word` already requests words; add `char_type_name` (and `position`) to
  `word_fields` if QF does not return them by default.
- `_extract_words`: skip entries whose `char_type_name` is `end` (keep `word`; keep
  `pause`/`sajdah`/`rub-el-hizb` signs out of chips too, since they are not words with
  meanings). Include `position` in each word (used later by reader-audio).
- Lesson response per ayah adds `text_has_ayah_number: bool` — true when the Arabic ends
  with an ayah-number marker (U+06DD, or Arabic-Indic / Eastern Arabic-Indic digits at
  the end after trimming). The text is not changed.

## App
- `AyahCard` shows `_endOfAyahMarker` only when `!ayah.textHasAyahNumber`.
- `ReaderDisplayMode { arabicOnly, arabicTranslation, full }`
  (`features/quran_reader/application/reader_settings.dart`), `AsyncNotifier` backed by
  `shared_preferences` key `reader.display_mode`, default `full`.
- `AyahCard` takes `displayMode` instead of `showTranslation`:
  - word chips only in `full`;
  - translation in `arabicTranslation` and `full`.
- `ReaderFloatingControls`: the translation toggle becomes a "View" button that opens a
  small bottom sheet with the three options (radio list, current one ticked).
- Profile → Settings: "Reading view" row (subtitle = current mode) opens the same sheet.
  The static "Translation: Saheeh International" row stays as information.
- Font scale stays local to the reader (not part of this spec).
