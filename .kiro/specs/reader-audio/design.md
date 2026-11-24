# Design — Reader Audio

## Step 0: API check (spike, before building)
Confirm on the **pre-live** QF API, through the backend adapter:
- Reciter list endpoint (chapter reciters / recitations resources): which IDs exist,
  names, styles.
- `GET /content/api/v4/chapter_recitations/{reciter_id}/{chapter}?segments=true`
  ([docs](https://api-docs.quran.foundation/docs/content_apis_versioned/4.0.0/chapter-reciter-audio-file/))
  for chapters 1 and 2: returns the chapter audio URL plus per-verse `timestamp_from` /
  `timestamp_to` and word `segments` `[word_index, start_ms, end_ms]` (ms).
- Whether `word_index` matches word `position` from `verses/by_key` (expected 1-based,
  words only).
- Which reciters return segments (decides the "has timings" flag).
Record the findings in this file before T1. If segments are missing on pre-live, ship
R1 + R3 with ayah-level highlighting and keep R2 behind the "has timings" flag.

## Audio source: one chapter file + timings
Today each ayah has its own URL and play-all queues them. With timings we use the
**chapter audio file** for the lesson's surah:
- single ayah = clip `[verse.start, verse.end]`;
- play-all = clip `[first verse start, last verse end]` (lessons can be part of a surah,
  e.g. Al-Baqarah 1–5);
- current ayah and word = looked up from the player position against the timings.
`just_audio` `ClippingAudioSource` covers both. Loop: `LoopMode.one` on the clip.
Fallback when a reciter has no chapter file/timings: today's per-ayah files and queue
(ayah-level highlight only).

## Backend
- `QuranFoundationClient`:
  - `get_reciters()` → cached 1 week.
  - `get_chapter_audio(reciter_id, chapter, segments=True)` → cached 1 week.
  All calls stay in `apps/quran_content` (steering).
- `GET /api/v1/reciters/` → `[{id, name, style, has_timings}]`, filtered to reciters
  with audio for the surahs of published lessons; cached.
- `PATCH /api/v1/me/preferences/` `{ "reciter_id": 7 }` → validated against the list;
  stored in `User.preferences["reciter_id"]`; owner-only (acts on `request.user`).
- Lesson detail: reciter = `?reciter=` param, else the user preference, else the
  lesson's default recitation source. Response adds:
```json
"audio": {
  "reciter": {"id": 7, "name": "...", "style": "Murattal"},
  "mode": "chapter" | "per_ayah",
  "chapter_url": "https://...",
  "verses": [
    {"verse_key": "1:1", "start_ms": 0, "end_ms": 6500,
     "words": [[1, 0, 900], [2, 900, 1800]]}
  ]
}
```
  Per-ayah `audio_url` stays for older app versions and the per-ayah fallback.
  Attribution uses the chosen reciter.
- Provenance: reciter and timings recorded like other QF resources (provider, resource
  type, ID, retrieved_at, cache policy).

## App
- `AudioController` rewrite:
  - `loadLesson(LessonAudio audio)`; `playAyah(verseKey)`, `playAll()`, `toggleLoop()`.
  - State adds `currentVerseKey`, `currentWordPosition`, `position`, `duration`
    (position stream throttled to ~10 Hz to keep rebuilds cheap).
  - Mapping position → verse/word by binary search over the timings.
- Reader:
  - List keyed per ayah with `scrollable_positioned_list` (`ItemScrollController
    .scrollTo`) so scrolling to an index works without measuring.
  - Follow mode: on while playing; a `ScrollStartNotification` from a user drag turns it
    off and shows the **Follow recitation** button.
  - Audio strip progress bar from `position / duration` of the current clip.
  - Reciter label from `audio.reciter.name`.
- `AyahCard`: Arabic rendered as one `Text.rich` with a `TextSpan` per QF word
  (`text_qpc_hafs` per word, spaces between, the QF end marker kept as the last span);
  the span with `position == currentWordPosition` gets a soft highlight background and
  `primary` colour. Word chips use the same position.
- Profile → Reciter row opens `ReciterPickerSheet` (list from `/reciters/`, timings
  badge); selecting calls `PATCH /me/preferences/`, then invalidates lesson providers.
- Listening exercises read clips from the same `audio` block.

## Risks
- Pre-live may expose fewer reciters or no segments (Step 0 decides scope).
- Chapter files for Al-Baqarah are long; clipping streams only the needed range, but
  the first seek can take a moment on slow networks (show the strip spinner).
- Per-word spans must render identically to the full-verse text; check ligatures across
  spaces on device with the bundled font.
