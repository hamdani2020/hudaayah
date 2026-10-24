# Hudaayah — UI/UX Spec (from Google Stitch)

Source: Stitch project **"Hudaayah Quran Learning App"** (`projects/8483347196154126326`),
device MOBILE, theme **"Sacred Serenity"**. Pulled via Stitch MCP `get_screen` +
`download_file` on 2026-10-24. Raw HTML per screen is in `design/stitch/screens/`.
Consistency re-check against the live Stitch project on 2026-10-24 (10 screens): the
designs still match this spec, **except** the former "App Overview" screen has been
replaced by an onboarding variant titled **"Hudaayah Quran & Tajweed App"** that
reintroduces out-of-scope **Tajweed** and **Tafsir** framing — see the ⚠️ table.

> How to refresh: in a shell that sourced `~/.zshrc`, the Stitch MCP (OAuth) is live.
> Re-run `list_screens` / `get_screen` / `download_file` for project `8483347196154126326`.

---

## ⚠️ Scope reconciliation (read first)

The Stitch designs are richer than the agreed Al-Fatihah MVP and include several
**out-of-scope** features. Flagged here so implementation follows the steering scope,
not the mockups, unless you decide to widen scope.

| Feature in design | MVP status | Recommendation |
|---|---|---|
| Tajweed colored rules + legend (Idgham, Ghunnah, Qalqalah), "Tajweed App" title | OUT (docs exclude Tajweed) | Defer. Show plain Arabic for pilot; keep tokens for later. |
| Tafsir / "Context" buttons | OUT (no full tafsir) | Hide for MVP. |
| Transliteration line | Not in MVP list | Optional; cheap to include if QF provides it. |
| Bookmarks / share per ayah | OUT (no social) | Defer bookmarks; drop share for pilot. |
| Email/password sign-in | OUT (Google + Apple only) | Keep Google + Apple; hide email path. |
| "Word of the Day", journal entry, levels ("Level 3"), mindfulness minutes | OUT (XP+streak only) | Defer; keep XP + streak + daily goal. |
| Arabic UI locale toggle | Not in MVP | Defer; English UI for pilot. |
| "Hudaayah Quran & **Tajweed** App" onboarding variant screen (title + "Tafsir" copy) | OUT (Tajweed + full tafsir excluded) | Ignore for pilot. Use the plain `welcome-onboarding.html`. |

The three MVP exercise types (multiple_choice, word_order, listening_recall) must be the
exercise surface. The design's quiz screen is a multiple_choice — good; word_order and
listening_recall still need layouts (not present in Stitch yet).

---

## Design tokens (from inline Tailwind config — port to Flutter ThemeData)

Palette "Sacred Serenity" (LIGHT):
- primary `#002721`, primary-container `#0f3e36`, on-primary `#ffffff`,
  on-primary-container `#7ca99e`, inverse-primary `#a2d0c4`
- secondary `#904d00`, secondary-container `#fe932c` (warm accent),
  secondary-fixed `#ffdcc3`, on-secondary `#ffffff`
- tertiary `#00281a`, tertiary-container `#00402d`
- surface `#effcf9`, surface-container-lowest `#ffffff`,
  surface-container-low `#e9f7f3`, surface-container `#e3f1ed`,
  surface-container-high `#ddebe8`, surface-variant `#d8e5e2`
- on-surface `#121e1c`, on-surface-variant `#404846`, outline `#717976`,
  outline-variant `#c0c8c5`, error `#ba1a1a`
- Full M3 token set present in each screen's `<script id="tailwind-config">`.

Typography:
- Headlines/display/transliteration: **Newsreader**
- Body/labels: **Plus Jakarta Sans**
- Arabic ayah: **Noto Serif** (24px small / 30px large, generous line-height ~54–68px).
  NOTE: for actual Quran rendering, bundle a dedicated Uthmani font (e.g. KFGQPC
  Uthmanic Hafs) per quran-content-rules; Noto Serif is the design placeholder.
- Type scale: display-lg 36px, display-lg-mobile 28px, headline-md 24px,
  headline-sm 18px, body-lg 16px, body-md 14px, label-md 12px, label-sm 11px.

Shape/spacing: radius lg .5rem / xl .75rem / full; spacing scale xs .25 → xl 2.25rem,
gutter 1rem, margin 1.25rem.

---

## Screen → feature → route map

GoRouter routes assume the structure in `.kiro/steering/structure.md`.

| Stitch screen | File | Feature | Route | In-pilot? |
|---|---|---|---|---|
| Welcome & Onboarding | `welcome-onboarding.html` | onboarding | `/onboarding` | ✅ (trim benefits copy) |
| Sign In & Authentication | `sign-in.html` | authentication | `/auth` | ✅ (Google + Apple only) |
| Home Dashboard | `home-dashboard.html` | progress/home | `/home` | ✅ (streak, daily habit, continue) |
| Surah & Verse Selection | `surah-verse-selection.html` | learning_path / quran_reader | `/surahs` | ◻︎ partial (pilot = Al-Fatihah only) |
| Quran Reader - Al-Fatihah | `quran-reader-al-fatihah.html` | quran_reader + audio | `/reader/1` | ✅ (strip Tajweed/tafsir/bookmark) |
| Quranic Vocabulary Lesson | `vocabulary-lesson.html` | lessons (understand) | `/lesson/:id` | ✅ (word-by-word, root, audio) |
| Interactive Quiz & Feedback | `quiz-exercise-feedback.html` | exercises (multiple_choice) | `/exercise` | ✅ |
| Lesson Completion & Progress | `lesson-completion-progress.html` | gamification/progress | `/lesson/:id/complete` | ✅ (XP+streak; drop journal/mindfulness) |
| Learning History & Profile | `history-profile-settings.html` | profile | `/profile` | ✅ (drop levels; keep streak/stats, logout, privacy, account deletion) |
| Hudaayah Quran & Tajweed App (onboarding variant) | `app-overview.html` | (alt onboarding) | — | ❌ ignore — reintroduces Tajweed/Tafsir; use `welcome-onboarding.html` instead |

---

## Per-screen notes (MVP-relevant)

### Onboarding `/onboarding`
Hero "Build a Heartfelt, Daily Connection with the Quran"; three value cards
(Daily Micro-Habits · 10 mins/day, Quranic Vocabulary · spaced repetition,
Word-by-Word recitation); language toggle (defer); CTA "Get Started — It's Free".

### Sign In `/auth`
"Continue with Google" + "Continue with Apple" (KEEP). Email/password block → hide for
MVP. Footer links **Terms of Service** + **Privacy Policy** (required by QF terms — wire
to real pages). "Sacred Data Sanctuary" trust note.

### Home `/home`
Greeting, **streak** (fire icon, "7d"), today's habit card with progress %
("5 mins remaining", Continue), daily goal. Drop "Word of the Day". This is the daily
habit hub — day-2/day-7 return driver.

### Reader `/reader/1`
Sticky audio strip: play, reciter label ("Mishary Rashid Alafasy • Ayah 1-7"), speed
(1.0x), **loop/repeat** toggle, scrubber — matches R3 (audio repeat/loop). Ayah cards:
Arabic (RTL, tap word → meaning tooltip = word-by-word), transliteration, English
translation, per-ayah play. Floating controls: font A-/A+, translation toggle.
REMOVE for pilot: Tajweed tags/legend/palette, Tafsir "menu_book", bookmark/share.
Audio + translation come from QF via backend; never auto-translate Arabic; show QF
attribution.

### Vocabulary lesson `/lesson/:id`
Root-based learning (e.g. R-H-M), part of speech, occurrence count, Arabic term,
transliteration, **Listen Pronunciation** (audio), step progress "Step 3 of 5". Maps to
"Understand" phase. Keep educational content clearly separated from Quran text.

### Quiz `/exercise`
multiple_choice: question about a root's meaning, options with select state, correct/▸
feedback. Server grades (never ship answer key). Use gentle feedback copy (adab).
STILL NEEDED (not in Stitch): word_order and listening_recall layouts.

### Completion `/lesson/:id/complete`
"Alhamdulillah!" celebration, streak increment ("8-Day Streak +1"), session summary.
Keep XP + streak; drop journal entry / mindfulness-minutes / level mechanics.

### Profile `/profile`
Stats (streak, surahs read, roots known), settings, dark mode, language, **logout**.
Add: privacy policy, terms, **account deletion** (required before launch). Drop level
("Seeker of Light Level 3") for pilot.

---

## Build implications
1. Create a Flutter `ThemeData` from the token table above (seed color `#0f3e36`,
   M3, Newsreader + Plus Jakarta Sans via `google_fonts`, Uthmani font bundled for ayat).
2. Reader already specifies the audio repeat/loop + word-tap interactions the MVP needs.
3. Two exercise layouts (word_order, listening_recall) are not yet designed in Stitch —
   generate them later with `generate_screen_from_text`, or design in-app.
4. Honor scope flags above: implement the MVP subset, keep richer features behind
   post-pilot backlog.
