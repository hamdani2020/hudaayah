# Tasks — Progress Feedback

## Kiro tasks — backend
- [x] P1 `lesson_states(user)` + `is_lesson_unlocked(user, lesson)` with the unlock rule. (R3, R4)
- [x] P2 Enforce unlocking in `LessonDetailView` and `StartAttemptView` (`lesson_locked`). (R4)
- [x] P3 `progress_summary` returns every published lesson with state and exercise counts. (R3)
- [x] P4 Completion response adds `streak` (current/previous/increased), `week`, `total_xp`;
      stored for idempotent replay. (R2)
- [x] P5 Tests: unlock order, grandfathering, locked errors, summary lists all lessons,
      streak `increased` only on the first completion of the day, replay returns the
      same block, cross-user isolation. (R2–R4)

## Kiro tasks — app
- [-] P6 Invalidate progress, lessons and due-review providers after completion. (R1)
- [ ] P7 `StreakCelebrationScreen` + `/lesson/:id/streak` route; shown only when
      `increased`; once per attempt. Extract the week-day circle widget. (R2)
- [ ] P8 Models: lesson state, counts, previous title, streak change. (R2, R3)
- [ ] P9 Journey tiles for completed / in progress / up next / locked; Home focus card rule. (R3)
- [ ] P10 Read tab shows lock state; `lesson_locked` message in reader and practice. (R3, R4)
- [ ] P11 `flutter analyze`, tests, release build. (R1–R4)

## Owner checks
- [ ] O1 Review the celebration and lock wording (adab).
- [ ] O2 With a fresh account: only lesson 1 is open; completing it shows the
      celebration and unlocks lesson 2; a second completion the same day shows no
      celebration; Home and Profile update without refreshing.
