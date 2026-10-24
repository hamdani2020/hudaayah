# Requirements — Al-Fatihah MVP

> Note: this spec follows a requirements/design/tasks convention as structured project
> context. It is authored documentation, not a CLI-enforced format.

## 1. Goal
A new learner can complete the full learning loop for Surah Al-Fatihah
(Listen → Read → Understand → Practice → Recall → Review) in ~5–10 minutes and return
the next day, with all progress server-authoritative.

## 2. User stories & acceptance criteria (EARS-style)

### R1 Authentication
- WHEN a user taps "Continue with Google" or "Continue with Apple", THE SYSTEM SHALL
  verify the provider token server-side and return an app session.
- THE SYSTEM SHALL key accounts on `(provider, provider_sub)`, never email alone.
- THE SYSTEM SHALL store session tokens in platform-secure storage and never log tokens.
- WHEN a user logs out, THE SYSTEM SHALL revoke the app session and clear local creds.

### R2 Quran content (Al-Fatihah)
- THE SYSTEM SHALL fetch Arabic text, a selected translation, word-by-word data, and
  audio for all 7 ayahs from Quran Foundation via the Django adapter only.
- THE SYSTEM SHALL NOT hardcode or permanently mirror QF verse text; cache ≤ 1 week.
- THE SYSTEM SHALL render Arabic RTL with correct diacritics and never auto-translate it.
- THE SYSTEM SHALL display Quran Foundation attribution.

### R3 Reading
- THE learner SHALL navigate ayah-by-ayah, view Arabic + translation, and play/replay
  ayah audio with repeat/loop.

### R4 Exercises (3 types)
- THE SYSTEM SHALL support `multiple_choice`, `word_order`, `listening_recall`.
- THE SYSTEM SHALL grade every answer on the server and SHALL NOT send the answer key
  to the client before submission.
- WHEN a recall answer is wrong, THE SYSTEM SHALL respond with gentle, encouraging
  feedback (no "failed" framing).

### R5 Progress, XP, streak
- THE SYSTEM SHALL calculate XP, streak, daily goal, and completion on the server.
- Completion + reward updates SHALL run in a transaction and SHALL be idempotent
  (duplicate submissions never double-award).
- THE SYSTEM SHALL persist progress so it survives logout/login.

### R6 Spaced repetition
- THE SYSTEM SHALL schedule vocabulary review items (trimmed SM-2) and expose due items.
- THE data model SHALL support an ayah-recall review type (not required in pilot UI).

### R7 Reliability / online-first
- THE SYSTEM SHALL show explicit loading/timeout/offline states.
- THE SYSTEM SHALL NOT mark a lesson complete until the backend confirms it.
- THE SYSTEM SHALL retry safe reads with bounded backoff and SHALL NOT blindly retry
  writes that could duplicate progress.

### R8 Compliance
- THE SYSTEM SHALL publish a Privacy Policy + Terms of Use before pilot.
- THE SYSTEM SHALL keep QF `client_secret` server-side only.
- THE SYSTEM SHALL NOT use QF content for ML training.

## 3. Out of scope
Hadith, tafsir, AI tutor, Tajweed scoring, social, offline sync, multiple paths,
levels/badges beyond XP+streak, surahs beyond Al-Fatihah.

## 4. Definition of done (pilot)
Google+Apple auth works on device; Al-Fatihah delivered via QF through Django; exercises
graded server-side; progress/XP durable + retry-safe; Arabic + attribution + audio
correct; failures handled without losing confirmed progress; CI/monitoring/backups
operational; no critical security/content-rights/data-integrity issues.
