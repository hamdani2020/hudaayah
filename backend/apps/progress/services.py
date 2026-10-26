"""Attempt lifecycle: start, submit+grade an answer, complete (idempotent).

Server owns grading/XP/completion (R5). Completion + reward run in a single
transaction and are idempotent via the attempt's idempotency_key.
"""
from __future__ import annotations

from django.db import transaction
from django.utils import timezone

from apps.exercises.grading import grade
from apps.exercises.models import Exercise
from apps.lessons.models import Lesson

from .models import (
    AttemptStatus,
    DailyActivity,
    ExerciseAnswer,
    LessonAttempt,
    ProgressState,
    UserProgress,
)

# Base XP for completing a lesson (full XP/streak logic lands in Phase 5).
LESSON_COMPLETION_XP = 10


def start_attempt(*, user, lesson: Lesson) -> LessonAttempt:
    return LessonAttempt.objects.create(user=user, lesson=lesson)


def submit_answer(*, attempt: LessonAttempt, exercise: Exercise, submitted: dict):
    """Grade server-side and record the answer. Returns (answer, GradeResult)."""
    result = grade(exercise, submitted)
    answer = ExerciseAnswer.objects.create(
        attempt=attempt,
        exercise=exercise,
        submitted=submitted,
        correct=result.correct,
    )
    return answer, result


@transaction.atomic
def complete_attempt(*, attempt: LessonAttempt, idempotency_key: str) -> dict:
    """Complete an attempt exactly once; award XP + update progress atomically.

    Idempotent: a repeat call with the same key (or an already-completed attempt)
    returns the existing summary without double-awarding.
    """
    # Lock the attempt row to serialize concurrent completion attempts.
    attempt = LessonAttempt.objects.select_for_update().get(pk=attempt.pk)

    if attempt.status == AttemptStatus.COMPLETED:
        return attempt.score_summary

    answers = list(attempt.answers.all())
    total = len(answers)
    correct = sum(1 for a in answers if a.correct)
    summary = {
        "total": total,
        "correct": correct,
        "xp_earned": LESSON_COMPLETION_XP,
    }

    attempt.status = AttemptStatus.COMPLETED
    attempt.completed_at = timezone.now()
    attempt.score_summary = summary
    attempt.idempotency_key = idempotency_key
    attempt.save(update_fields=[
        "status", "completed_at", "score_summary", "idempotency_key"
    ])

    # Upsert per-lesson progress (best result = highest correct count).
    progress, _ = UserProgress.objects.get_or_create(
        user=attempt.user, lesson=attempt.lesson
    )
    best = progress.best_result or {}
    if correct >= best.get("correct", -1):
        progress.best_result = summary
    progress.state = ProgressState.COMPLETED
    progress.completed_at = attempt.completed_at
    progress.save(update_fields=["best_result", "state", "completed_at", "last_activity"])

    # Daily activity rollup (one row per user/day).
    today = timezone.localdate()
    activity, _ = DailyActivity.objects.get_or_create(user=attempt.user, date=today)
    activity.xp_earned += LESSON_COMPLETION_XP
    activity.lessons_completed += 1
    activity.save(update_fields=["xp_earned", "lessons_completed"])

    # Seed vocab review items for this lesson (idempotent per user+ref).
    _ensure_vocab_reviews(attempt)

    return summary


def _ensure_vocab_reviews(attempt: LessonAttempt) -> None:
    """Create vocab review items from the lesson's exercises (R6).

    Vocab is declared in an exercise's `config['vocab']` as a list of
    {content_ref, prompt}. Creation is idempotent via the scheduler.
    """
    from apps.review.scheduler import ensure_item

    for exercise in attempt.lesson.exercises.all():
        for vocab in (exercise.config or {}).get("vocab", []):
            ref = vocab.get("content_ref")
            if ref:
                ensure_item(
                    attempt.user,
                    content_ref=ref,
                    prompt=vocab.get("prompt", ""),
                )
