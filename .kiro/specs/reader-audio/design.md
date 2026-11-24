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

### Step 0 findings (pre-live, through `QuranFoundationClient._content_get`)
Checked chapters 1 and 2 for every reciter. Only IDs and timing numbers were inspected;
no Quran text or secrets were logged.

**Reciters**
| id | name / style | source list | chapter files 1, 2 | ch1 file length |
|----|--------------|-------------|--------------------|-----------------|
| 6 | Mahmoud Khalil Al-Husary, Murattal | `chapter_reciters` + `recitations` | yes, yes | 48 s |
| 7 | Mishari Rashid al-Afasy, Murattal | `chapter_reciters` + `recitations` | yes, yes | 46 s |
| 12 | Mahmoud Khalil Al-Husary, Muallim | `chapter_reciters` only | yes, yes | 64 s |
| 173 | Mishari al-Afasy (Streaming) | `chapter_reciters` only | yes, yes | 39 s |
- `resources/chapter_reciters` returns 4 reciters; `resources/recitations` (per-ayah
  files) returns only 6 and 7. So reciters 12 and 173 have **no per-ayah fallback**;
  they work only in chapter mode.
- Chapter 2 files are 2–4 hours (~7–14 million ms), so clipping is required.

**Chapter audio response** (`chapter_recitations/{id}/{ch}`)
- Body is `{"audio_file": {id, chapter_id, audio_url, duration, file_size, format,
  timestamps}}`.
- `audio_url` is **absolute** (`https://download.quranicaudio.com/qdc/...`); no base
  prefix is needed. This host differs from the per-ayah audio host; the app must allow it.
- `audio_file.duration` is in ms but rounded to whole seconds (e.g. 48000 while the last
  verse ends at 48210). Use the last `timestamp_to` as the clip end, not `duration`.
- `timestamps` is **empty unless `segments=true`** is sent. With `segments=true` every
  reciter returns one entry per verse (7 for ch1, 286 for ch2), all with segments.
- Timestamp entry: `{verse_key, timestamp_from, timestamp_to, duration, segments}`.
  All times are absolute ms in the chapter file. Segments are `[word_index, start, end]`.

**`word_index` vs `verses/by_key` word `position`**
- `word_index` is 1-based and counts **words only** (`char_type_name == "word"`); the
  end marker has no segment. In all 4 reciters × 2 chapters, no segment pointed at a word
  position that does not exist.
- Not every word has a segment. Verses where segments cover all words / only some:
  6: ch1 7/7, ch2 238/286; 7: ch1 7/7, ch2 222/286; 12: ch1 7/7, ch2 149/286;
  173: ch1 7/7, ch2 266/286. The highlighter must tolerate words with no segment
  (keep the previous word highlighted until the next segment starts).

**Data quirks the backend must normalise** (in the adapter, before caching the API shape)
- Malformed segments: reciter 7 returns entries with 1 or 2 numbers instead of 3
  (ch1 `1:3`; ch2 `2:114`, `2:255`). Drop any segment that is not exactly 3 numbers.
- Reciter 12 returns floats (`660.0`); round to int ms.
- Reciter 6 `duration` per verse is negative; ignore the field and use `to − from`.
- Reciter 7 word segments start up to ~65 ms before the verse's `timestamp_from`; clamp
  segment times into `[timestamp_from, timestamp_to]`.
- Reciter 173 ch2: 10 verses start before the previous verse ends; when looking up the
  current verse, pick the latest verse whose `start ≤ position`.
- Reciter 173 ch1 verse `1:1` has zero length (`from = to = 80`, all word segments
  `[n, 80, 80]`). The Al-Fatihah file appears not to include a recitation of 1:1 with
  timings, so 1:1 cannot be played or highlighted for 173.

**Has-timings flag:** all 4 reciters return word segments for chapters 1 and 2, so
`has_timings` is true for all 4. The flag is still computed per reciter and chapter
(segments present for ≥1 verse and no zero-length verse in the lesson range), so a
reciter with broken data drops to ayah-level highlighting.

**Scope impact:** R1, R2 and R3 are all feasible on pre-live. Chapter mode is the main
path. Per-ayah fallback exists only for reciters 6 and 7. The default reciter must be
one of those two, because it is also the fallback in R3. Reciters with no per-ayah
files and no usable chapter timings for a lesson are left out of the list for that
lesson's surah.

**Open questions for the owner (confirm before T1):**
1. Reciter 173 (Afasy Streaming): hide it from the picker (it duplicates reciter 7, and
   Al-Fatihah 1:1 has no usable timing), or list it only for Al-Baqarah? Proposed: hide.
2. Reciter 12 (Husary Muallim, teaching style with pauses for repetition): list it?
   Proposed: list it, labelled "Muallim (teaching)".
3. Default reciter: 7 (Afasy, the current default) or 6 (Husary)? Proposed: keep 7.

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
