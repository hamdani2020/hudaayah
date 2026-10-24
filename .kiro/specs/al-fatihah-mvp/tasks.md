# Tasks — Al-Fatihah MVP

Sequenced for a solo developer, ~6 build weeks + 2 pilot weeks. Each task maps to
requirements (Rn) in requirements.md.

## Phase 1 — Foundation (Week 1)
- [ ] 1.1 Scaffold Django (settings split, apps, requirements pinned, venv). (R-tech)
- [ ] 1.2 Configure PostgreSQL + initial migrations. (R5)
- [ ] 1.3 Implement `QuranFoundationClient` adapter: token cache, headers, 401 retry,
      error mapping, ≤1wk cache; hit pre-live `/chapters`. (R2)
- [ ] 1.4 Scaffold Flutter (Riverpod, GoRouter, Dio, theme, bundled Quran font). (R-tech)
- [ ] Exit: QF token works; `/chapters` returns Al-Fatihah via Django.

## Phase 2 — Auth (Week 2)
- [ ] 2.1 `User` model (multi-provider), migrations. (R1)
- [ ] 2.2 Google ID-token verification + session issue/refresh/logout + `GET /me/`. (R1)
- [ ] 2.3 Flutter Google Sign-In, secure token storage, Dio auth interceptor, profile. (R1)
- [ ] Exit: sign in on a real device, fetch own profile.

## Phase 3 — Content + reader (Week 3)
- [ ] 3.1 Seed loader for Al-Fatihah (references only, no verse text). (R2)
- [ ] 3.2 `GET /lessons/{id}/` returning verse/translation/word-by-word/audio refs. (R2,R3)
- [ ] 3.3 Flutter Quran reader: Arabic RTL + translation + audio repeat/loop +
      QF attribution. (R2,R3,R8)
- [ ] Exit: Al-Fatihah renders correctly with audio on device.

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
- [ ] Exit: pilot checklist clean, no critical issues.

## Phase 7 — Pilot (Weeks 7–8)
- [ ] 7.1 Ship to ~10 real learners. Measure Day-1/Day-2/Day-7 return rate.
- [ ] 7.2 Fix what retention data reveals before expanding scope.
