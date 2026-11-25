"""Assemble a user's progress summary (per-lesson + gamification)."""
from __future__ import annotations

from apps.gamification.services import gamification_summary
from apps.lessons.models import Lesson
from apps.lessons.services import lesson_states

from .models import DailyActivity, UserProgress


def progress_summary(user) -> dict:
    """One entry per published lesson (ordered), whether or not the user started it."""
    states = lesson_states(user)
    lessons_by_id = {
        lesson.id: lesson
        for lesson in Lesson.objects.filter(id__in=[s["lesson_id"] for s in states])
    }
    progress = {p.lesson_id: p for p in UserProgress.objects.filter(user=user)}
    lessons = []
    previous_title = None
    for entry in states:
        lesson = lessons_by_id[entry["lesson_id"]]
        p = progress.get(lesson.id)
        completed_at = entry["completed_at"]
        lessons.append({
            "lesson_id": lesson.id,
            "title": lesson.title,
            "surah": lesson.surah,
            "ayah_start": lesson.ayah_start,
            "ayah_end": lesson.ayah_end,
            "order": lesson.order,
            "surah_name_en": lesson.surah_name_en,
            "surah_name_ar": lesson.surah_name_ar,
            "surah_meaning": lesson.surah_meaning,
            "state": entry["state"],
            "best_result": p.best_result if p else {},
            "completed_at": completed_at.isoformat() if completed_at else None,
            "exercises_total": entry["exercises_total"],
            "exercises_answered": entry["exercises_answered"],
            "previous_title": previous_title,
        })
        previous_title = lesson.title
    return {
        "lessons": lessons,
        **gamification_summary(user),
    }


def daily_activity(user, *, limit: int = 30) -> list[dict]:
    rows = (
        DailyActivity.objects.filter(user=user)
        .order_by("-date")[:limit]
    )
    return [
        {
            "date": r.date.isoformat(),
            "xp_earned": r.xp_earned,
            "lessons_completed": r.lessons_completed,
        }
        for r in rows
    ]
