# Design — Progress Feedback

## Causes
- Bug 2: after `POST /attempts/{id}/complete/` the app never invalidates
  `progressSummaryProvider`, `lessonsListProvider` or `dueReviewsProvider`, so screens
  keep the cached values until pull-to-refresh.
- Bug 5: `progress_summary()` builds `lessons` from the user's `UserProgress` rows only,
  and the app shows each as completed or not. New users see nothing; nothing is "next".

## Backend

### Unlock rule (new `apps/lessons/services.py: lesson_states(user)`)
Input: published lessons ordered by `(order, id)`, the user's `UserProgress` rows and
in-progress attempts. Output per lesson:
`{lesson_id, state, exercises_total, exercises_answered, completed_at}` where state is
`completed | in_progress | available | locked`:
- `completed`: progress state completed.
- `in_progress`: an in-progress attempt exists (count distinct answered exercises), or
  progress state in_progress.
- `available`: first lesson, or previous lesson completed, or the user has any progress
  on it (grandfathered).
- `locked`: otherwise.
`exercises_total` = published exercises of the lesson.

Helper `is_lesson_unlocked(user, lesson)` used by:
- `LessonDetailView.get_object` → raise `LessonLocked` (`lesson_locked`, 403,
  "This lesson opens after you complete the one before it.").
- `StartAttemptView` → same error.

### Progress summary
`progress_summary(user)["lessons"]` becomes one entry **per published lesson** (existing
fields + `state`, `order`, `exercises_total`, `exercises_answered`, `previous_title`
for the lock message). Existing fields stay, so older app versions keep working
(`state` values `completed` / `in_progress` already exist; `available`/`locked` are new).

### Completion response
`complete_attempt()` computes `current_streak(user)` before and after updating
`DailyActivity` and adds:
```json
"streak": {"current": 3, "previous": 2, "increased": true},
"week": [ ...same shape as the summary week... ],
"total_xp": 50
```
`increased` = `current > previous`. The block is stored in the attempt's
`score_summary` at first completion, so an idempotent replay returns the same values.

## App
- `ExerciseController` (or wherever completion succeeds): after a successful complete,
  `ref.invalidate(progressSummaryProvider)`, `lessonsListProvider`, `dueReviewsProvider`.
- Route flow: practice → (if `streak.increased`) `/lesson/:id/streak` (full screen,
  `extra` = summary) → completion screen. Otherwise straight to completion.
  `StreakCelebrationScreen` shows flame animation (implicit scale/fade, no new
  package), count, week row (reuse `_DaySlot` style, extracted to a shared widget),
  message, Continue → `pushReplacement` completion.
  Shown once per attempt id (kept in memory for the session).
- Models: `LessonProgress` gains `order`, `exercisesTotal`, `exercisesAnswered`,
  `previousTitle`; `isLocked`, `isUpNext` getters. Completion summary model gains
  `StreakChange`.
- `LessonJourneyTile` gains states: completed / in progress ("N of M exercises") /
  up next (Start) / locked (lock icon, muted, message on tap via SnackBar).
- Home: journey list from `summary.lessons` (now complete); focus card per R3.
- Read tab: use `state` from the summary for each catalog item; locked rows show the
  lock and message.
- `ApiException` code `lesson_locked` → show its message (reader and practice).

## Data and dates
Dates still use the server's local date (UTC). Ghana is UTC, so days match; other time
zones may see a completion near midnight counted on the neighbouring day (known, out of
scope).
