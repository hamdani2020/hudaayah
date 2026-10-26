"""Server-side grading for the three MVP exercise types.

Rules:
- Grading is authoritative and server-side (R4). The answer key never leaves here.
- Feedback uses gentle, encouraging language — no "failed" framing (adab).
- listening_recall is self-marked and graded leniently (feeds the review scheduler).
"""
from __future__ import annotations

from dataclasses import dataclass

from .models import Exercise, ExerciseType


@dataclass(frozen=True)
class GradeResult:
    correct: bool
    feedback: str


_CORRECT_FEEDBACK = "MashaAllah — that's right!"
_GENTLE_RETRY = "Not quite yet — keep going, you're learning. Give it another try."
_RECALL_ACK = "Thank you for practising. Every repetition helps it settle in your heart."


def grade(exercise: Exercise, submitted: dict) -> GradeResult:
    key = exercise.answer_key or {}
    if exercise.type == ExerciseType.MULTIPLE_CHOICE:
        return _grade_multiple_choice(key, submitted)
    if exercise.type == ExerciseType.WORD_ORDER:
        return _grade_word_order(key, submitted)
    if exercise.type == ExerciseType.LISTENING_RECALL:
        return _grade_listening_recall(submitted)
    # Unknown type — treat as incorrect without leaking internals.
    return GradeResult(correct=False, feedback=_GENTLE_RETRY)


def _grade_multiple_choice(key: dict, submitted: dict) -> GradeResult:
    correct = submitted.get("selected_option_id") == key.get("correct_option_id")
    return GradeResult(correct, _CORRECT_FEEDBACK if correct else _GENTLE_RETRY)


def _grade_word_order(key: dict, submitted: dict) -> GradeResult:
    correct = list(submitted.get("ordered_token_ids") or []) == list(
        key.get("correct_order") or []
    )
    return GradeResult(correct, _CORRECT_FEEDBACK if correct else _GENTLE_RETRY)


def _grade_listening_recall(submitted: dict) -> GradeResult:
    # Lenient: the learner self-marks whether they recalled it. We record it and
    # always acknowledge gently; the review scheduler uses the self-mark later.
    recalled = bool(submitted.get("self_marked_correct"))
    feedback = _CORRECT_FEEDBACK if recalled else _RECALL_ACK
    return GradeResult(recalled, feedback)
