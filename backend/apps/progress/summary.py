"""Assemble a user's progress summary (per-lesson + gamification)."""
from __future__ import annotations

from apps.gamification.services import gamification_summary

from .models import DailyActivity, UserProgress


def progress_summary(user) -> dict:
    lessons = [
        {
            "lesson_id": p.lesson_id,
            "title": p.lesson.title,
            "surah": p.lesson.surah,
            "ayah_start": p.lesson.ayah_start,
            "ayah_end": p.lesson.ayah_end,
            "order": p.lesson.order,
            "surah_name_en": p.lesson.surah_name_en,
            "surah_name_ar": p.lesson.surah_name_ar,
            "surah_meaning": p.lesson.surah_meaning,
            "state": p.state,
            "best_result": p.best_result,
            "completed_at": p.completed_at.isoformat() if p.completed_at else None,
        }
        for p in (
            UserProgress.objects.filter(user=user)
            .select_related("lesson")
            .order_by("lesson__order", "lesson_id")
        )
    ]
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
