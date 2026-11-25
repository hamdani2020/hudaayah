# Requirements — Reader Display

Release: 1.1.0. Fixes tester bug 1 and adds tester feature 2.

## R1 One end-of-ayah marker per ayah (bug 1)
- Each ayah shows exactly **one** end-of-ayah marker with its number.
- The marker comes from the Quran Foundation text when that text includes it; the app
  adds its own decorative marker only when the text has none.
- The end-of-ayah marker is not shown as a word-by-word chip.
- The Quran text itself is never modified (quran-content-rules).

## R2 Choose what to show while reading (feature 2)
- Three reading views:
  1. **Arabic only**: the ayah in Arabic, nothing else.
  2. **Arabic + translation**: Arabic and the labelled translation.
  3. **Full**: Arabic, word-by-word chips (meaning + transliteration) and translation.
- Default: **Full** (current behaviour).
- Changed from the reader (one tap opens the choice) and from Profile → Settings →
  "Reading view". Both show the same, saved setting.
- Saved on the phone; kept after closing the app.
- Arabic is always shown and never auto-translated. The translation stays labelled
  "TRANSLATION" and visually separate from the Quran text.
- Audio controls and font size work the same in every view.
