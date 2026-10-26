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
- `Lesson`: id, title, order, objectives, surah=1, ayah_start, ayah_end,
  status(`draft|in_review|published|archived`), approved_by(fk User, null),
  approved_at(null).
- `Exercise`: id, lesson_fk, type, position, config(JSON), content_references(JSON),
  answer_key(JSON, server-only), status(`draft|in_review|published|archived`),
  approved_by(fk User, null), approved_at(null).
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

## 9. Runtime / deployment (Docker)
The backend runs in Docker (Compose v2). Two services for MVP:
```
docker-compose.yml
  web  -> Django/DRF (build: backend/Dockerfile), port 8000,
          settings=config.settings.development, env_file=.env (gitignored)
  db   -> postgres:16, named volume pgdata, reachable from web at host "db"
```
- Dev: `docker compose up --build`; API at `http://localhost:8000/api/v1/`.
- Migrations / admin / tests run inside the container:
  `docker compose exec web python manage.py <cmd>`.
- DB host inside Compose is the service name `db` (not `localhost`); the port may be
  published to the host for inspection.
- Secrets (QF client id/secret, Django `SECRET_KEY`, DB creds, OAuth keys) come from the
  gitignored `.env` injected via Compose — never baked into the image or committed.
- Postgres data persists in the `pgdata` volume; back it up before destructive ops.
- Production image uses `config.settings.production`, a WSGI server (e.g. gunicorn),
  TLS termination upstream, and separate (non pre-live) QF credentials.

## 10. Content administration & review (pilot = Django admin)
Decision: for the pilot, admin is the **built-in Django admin** only — no custom UI.
Anything bespoke (reviewer portal, dashboards, support tooling) is post-pilot backlog.

- Access: staff/superuser accounts (`is_staff`). Create via
  `docker compose exec web python manage.py createsuperuser`. Learner (Google/Apple)
  accounts are never staff.
- Registered models: `Lesson`, `Exercise`, `ContentSource`, and read-only views of
  `User`, `LessonAttempt`, `UserProgress`, `DailyActivity`, `ReviewItem` for inspection.
- Status lifecycle (enforced for Lesson + Exercise): `draft → in_review → published`,
  plus `archived`. Learner-facing serializers/querysets return **only `published`**.
- Audit: moving to `published` stamps `approved_by` (the acting staff user) and
  `approved_at`. Implement as an admin action ("Mark reviewed & publish") so the stamp
  and status change happen together.
- QF content is **read-only** in admin: a reviewer can see resolved Arabic / translation /
  word-by-word / audio (via the adapter) to verify accuracy, but admin SHALL NOT edit or
  override QF Arabic or translation — only our own fields (title, order, hints, exercise
  config, references by stable ID). This enforces the quran-content-rules content-layer
  separation and immutability.
- Safety: never expose `answer_key` edits in a way that ships to clients; never render or
  log tokens/secrets in admin; destructive bulk actions are off by default.
- This maps the required human-review workflow (quran-content-rules: draft → review →
  QA → publication) onto admin without building new surfaces for the pilot.
