# Design — Al-Fatihah MVP

## 1. Architecture
```
Flutter (Android/iOS)
   | HTTPS + JSON + app session token
   v
Django REST (/api/v1/)
   |            \
   |             +--> Quran Foundation Content API (server-side credentials, pre-live)
   +--> PostgreSQL (users, lessons, exercises, attempts, progress, reviews, activity)
```
Modular monolith. QF accessed only from `apps/quran_content`.

## 2. Data model (key entities)
- `User`: id, provider, provider_sub (unique together), display_name, email?, avatar,
  preferences, timestamps.
- `Lesson`: id, title, order, objectives, surah=1, ayah_start, ayah_end, status.
- `Exercise`: id, lesson_fk, type, position, config(JSON), content_references(JSON),
  answer_key(JSON, server-only), status.
- `LessonAttempt`: id, user_fk, lesson_fk, status, started_at, completed_at,
  score_summary, idempotency_key (unique).
- `ExerciseAnswer`: id, attempt_fk, exercise_fk, submitted(JSON), correct(bool), ts.
- `UserProgress`: user_fk, lesson_fk, state, best_result, completed_at, last_activity.
- `ReviewItem`: user_fk, item_type(vocab|ayah_recall), content_ref, interval, ease,
  due_at, last_result.
- `DailyActivity`: user_fk, date, xp_earned, lessons_completed (unique user+date).
- `ContentSource`: provider, resource_type, provider_ref, lang/reciter id, version/sync
  meta, attribution, caching_policy_ref, retrieved_at.

Integrity: object-level ownership; transactions for completion+XP; idempotency_key
prevents double award; indexes on (user, date) and (user, due_at).

## 3. QF adapter (apps/quran_content)
`QuranFoundationClient` — token cache (client_credentials, ~3600s, 401→refresh+retry
once), headers `x-auth-token` + `x-client-id`, pre-live base URLs, error mapping, ≤1wk
cache. Methods: get_chapter, get_verses, get_translation, get_word_by_word, get_audio.

## 4. Exercise grading
Client submits `{exercise_id, submitted}`. Server loads answer_key, compares by type:
- multiple_choice: selected option id == correct id.
- word_order: submitted token id list == canonical order.
- listening_recall: self-marked result recorded; feeds review scheduler (lenient grading).
Server returns `{correct, feedback}` only after submission.

## 5. API contract (/api/v1/)
POST /auth/google/ · POST /auth/apple/ · POST /auth/refresh/ · POST /auth/logout/ ·
GET /me/ · GET /lessons/{id}/ · POST /lessons/{id}/attempts/ ·
POST /attempts/{id}/answers/ · POST /attempts/{id}/complete/ · GET /progress/ ·
GET /reviews/due/ · GET /activity/daily/
Error envelope: `{ "error": { code, message, request_id } }`.

## 6. Review scheduler (trimmed SM-2)
Per review item: track interval + ease factor. Correct → grow interval; incorrect →
reset to short interval. Only vocab items surfaced in pilot UI.

## 7. Mobile
GoRouter routes: /onboarding, /auth, /home, /lesson/:id, /reader/:surah, /exercise,
/progress, /profile. Riverpod controllers per feature; Dio repos; secure token storage;
Dio interceptor attaches access token + handles 401 refresh.

## 8. Compliance hooks
Attribution widget on reader + settings; Privacy Policy + ToU screens; no Quran text in
seed; cache TTL enforced in adapter.
