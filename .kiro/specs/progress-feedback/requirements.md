# Requirements — Progress Feedback (streak celebration + learning journey)

Release: 1.1.0. Fixes tester bugs 2 and 5. Server stays the source of truth for
streak, XP, completion and unlocking (steering).

## R1 Progress updates immediately after completing a lesson (bug 2)
- As soon as the server confirms a lesson completion, Home, Read, Profile (streak chip,
  Weekly Discipline, XP, lessons) and the Learn tab's due reviews show the new values,
  with no manual refresh.

## R2 Streak celebration (bug 2)
- When a completion **raises the streak** (the first completed lesson of the day), a
  full-screen celebration appears before the completion summary:
  - flame and the new count, e.g. "3-day streak";
  - the current week's days (Mon–Sun) with today newly filled;
  - one encouraging line, e.g. "You're building a beautiful habit. See you tomorrow,
    in shaa Allah."; for a first streak: "You started your streak!";
  - a **Continue** button to the completion summary.
- It does not appear for later completions the same day, or when the streak did not change.
- It appears once per completion, even if the completion request is retried.
- Adab: no pressure or loss framing ("don't lose your streak"), no comparison with
  other users.

## R3 Learning Journey shows the real path (bug 5)
- Lists **every published lesson** in learning order, not only lessons already started.
- Each lesson shows one state:
  - **Completed**, with the completion date;
  - **In progress**, with "N of M exercises";
  - **Up next**: the first unlocked, not-started lesson, with a **Start** action;
  - **Locked**: "Complete <previous lesson> to unlock", with a lock icon.
- Tapping a completed, in-progress or up-next lesson opens it. Tapping a locked lesson
  shows the unlock message (gentle wording), and does not open it.
- The Home "Today's Sacred Habit" card uses the same order: the in-progress lesson,
  else Up next, else the last completed lesson (Review).
- The Read tab list shows the same lock state on each lesson.

## R4 Lessons unlock in order (enforced by the server)
- The first published lesson is always unlocked.
- A lesson unlocks when the previous published lesson is completed.
- A lesson the learner has already started or completed stays unlocked (so current
  testers are not locked out if the order changes).
- Opening a locked lesson (reading or practice) is refused by the server with error
  code `lesson_locked` and a gentle message; the app shows that message.
