# Tasks — Al-Fatihah MVP

Sequenced for a solo developer, ~6 build weeks + 2 pilot weeks. Each task maps to
requirements (Rn) in requirements.md.

## Phase 1 — Foundation (Week 1)
- [x] 1.1 Scaffold Django (settings split, apps, requirements pinned) **in Docker**:
      `backend/Dockerfile` + `docker-compose.yml` (`web` + `db`), env via gitignored
      `.env`. No host venv. (R-tech)
- [x] 1.2 Add PostgreSQL as the Compose `db` service (`postgres:16`, named volume);
      run initial migrations via `docker compose exec web python manage.py migrate`. (R5)
- [x] 1.3 Implement `QuranFoundationClient` adapter: token cache, headers, 401 retry,
      error mapping, ≤1wk cache; hit pre-live `/chapters`. (R2)
- [x] 1.4 Scaffold Flutter (Riverpod, GoRouter, Dio, theme, bundled Quran font). (R-tech)
- [x] Exit: `docker compose up` boots web+db; QF token works; `/chapters` returns
      Al-Fatihah via Django.

## Phase 2 — Auth (Week 2)
- [ ] 2.1 `User` model (multi-provider), migrations. (R1)
- [ ] 2.2 Google ID-token verification + session issue/refresh/logout + `GET /me/`. (R1)
- [ ] 2.3 Flutter Google Sign-In, secure token storage, Dio auth interceptor, profile. (R1)
- [ ] Exit: sign in on a real device, fetch own profile.

## Phase 3 — Content + reader (Week 3)
- [ ] 3.1 Seed loader for Al-Fatihah (references only, no verse text). (R2)
- [ ] 3.2 `GET /lessons/{id}/` returning verse/translation/word-by-word/audio refs,
      serving **published-only** content. (R2,R3,R9)
- [ ] 3.3 Flutter Quran reader: Arabic RTL + translation + audio repeat/loop +
      QF attribution. (R2,R3,R8)
- [ ] 3.4 Content admin (Django admin): add `status` lifecycle
      (`draft|in_review|published|archived`) + `approved_by`/`approved_at` to Lesson &
      Exercise; register models; "Mark reviewed & publish" admin action that stamps the
      audit fields; QF fields rendered read-only. (R9)
- [ ] Exit: Al-Fatihah renders correctly with audio on device; only published lessons are
      served; a staff user can publish via admin and the audit stamp is recorded.

## Phase 4 — Exercises + grading (Week 4)
- [ ] 4.1 Exercise model + seed for 3 types. (R4)
- [ ] 4.2 Attempt endpoints + server-side grading + gentle feedback. (R4)
- [ ] 4.3 Completion transaction + idempotency key. (R5)
- [ ] 4.4 Flutter renderers for multiple_choice, word_order, listening_recall. (R4)
- [ ] Exit: complete one lesson end-to-end; result persists after reopening.

## Phase 5 — Progress + habit (Week 5)
- [ ] 5.1 Progress summary, XP, streak, daily activity. (R5)
- [ ] 5.2 Vocab review scheduler (trimmed SM-2) + `GET /reviews/due/`. (R6)
- [ ] 5.3 Flutter home/progress screen (streak + daily goal) + review session. (R5,R6)
- [ ] 5.4 Duplicate-submission + transaction tests. (R5)
- [ ] Exit: progress durable, user-specific, retry-safe.

## Phase 6 — Pilot readiness (Week 6)
- [ ] 6.1 Apple Sign-In (iOS requirement alongside Google). (R1)
- [ ] 6.2 Privacy Policy + ToU screens/pages; QF attribution review. (R8)
- [ ] 6.3 Rate limits, structured logging + request IDs, monitoring, DB backups. (R7,R8)
- [ ] 6.4 Device/accessibility pass; explicit loading/timeout/offline states. (R7)
- [ ] 6.5 Admin hardening: confirm only `is_staff` reaches admin, learner accounts never
      staff, no secrets/tokens rendered or logged in admin, destructive bulk actions off,
      `answer_key` not client-exposed. (R9)
- [ ] Exit: pilot checklist clean, no critical issues.

## Phase 7 — Pilot (Weeks 7–8)
- [ ] 7.1 Ship to ~10 real learners. Measure Day-1/Day-2/Day-7 return rate.
- [ ] 7.2 Fix what retention data reveals before expanding scope.

## Post-pilot backlog (not in MVP)
- Custom content-authoring / reviewer portal for non-developer reviewers (beyond Django
  admin), with guided QF preview and richer review states.
- Support/ops tooling and retention/analytics dashboards.
- Reviewer (non-superuser) role with scoped permissions and per-surah assignment.
