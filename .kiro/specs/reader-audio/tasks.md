# Tasks — Reader Audio

Start after the 1.1.0 specs (navigation-and-shell, progress-feedback, reader-display).
Depends on reader-display D2 (word `position`).

## Kiro tasks
- [ ] A0 Spike: check reciters, chapter audio and segments on pre-live for chapters 1–2;
      write findings into design.md; confirm scope with the owner. (R1–R3)
- [ ] A1 Adapter: `get_reciters`, `get_chapter_audio(segments=True)`, 1-week cache,
      provenance; tests with mocked QF responses. (R2, R3)
- [ ] A2 `GET /reciters/` and `PATCH /me/preferences/` (validation, owner-only); tests. (R3)
- [ ] A3 Lesson detail `audio` block (chapter or per-ayah mode, timings, reciter,
      attribution); keep `audio_url`; tests. (R1–R3)
- [ ] A4 `AudioController` on clipped chapter audio with position → verse/word mapping;
      per-ayah fallback. (R1, R2)
- [ ] A5 Reader: positioned list, follow mode + Follow recitation button, real progress
      bar, reciter label. (R1, R3)
- [ ] A6 `AyahCard`: per-word spans with the current word highlighted; chip highlight;
      "no word highlighting" note. (R2)
- [ ] A7 Reciter picker sheet in Profile; listening exercises use the chosen reciter. (R3)
- [ ] A8 `flutter analyze`, backend tests, release build. (R1–R3)

## Owner checks
- [ ] O1 Play-all on Al-Baqarah 1–5: the list keeps the recited ayah on screen; manual
      scroll shows Follow recitation; the progress bar moves.
- [ ] O2 Words highlight in step with the reciter (spot-check with a qualified reader
      that the text renders exactly as before).
- [ ] O3 Change reciter in Profile: the reader, attribution and listening exercises use it;
      it is kept after signing in on another device.
