"""XP, streak, and daily-goal calculation (server-authoritative; R5).

Gamification is limited to XP + streak + daily goal for the MVP (product scope:
no levels/badges). Streak is derived from DailyActivity dates, never stored
denormalized, so it cannot drift.
"""
from __future__ import annotations

from datetime import timedelta

from django.db.models import Sum
from django.utils import timezone

from apps.progress.models import DailyActivity

# A learner meets the daily goal by earning at least this much XP in a day.
DAILY_GOAL_XP = 10


def total_xp(user) -> int:
    agg = DailyActivity.objects.filter(user=user).aggregate(s=Sum("xp_earned"))
    return agg["s"] or 0


def current_streak(user, *, today=None) -> int:
    """Consecutive days (ending today or yesterday) with any activity.

    Counting from today backwards: if there's no activity today but there was
    yesterday, the streak is still alive (today just isn't done yet).
    """
    today = today or timezone.localdate()
    active_days = set(
        DailyActivity.objects.filter(user=user, xp_earned__gt=0)
        .values_list("date", flat=True)
    )
    if not active_days:
        return 0

    # Anchor: today if active, else yesterday if active, else streak is 0.
    if today in active_days:
        anchor = today
    elif (today - timedelta(days=1)) in active_days:
        anchor = today - timedelta(days=1)
    else:
        return 0

    streak = 0
    day = anchor
    while day in active_days:
        streak += 1
        day -= timedelta(days=1)
    return streak


def daily_goal_status(user, *, today=None) -> dict:
    today = today or timezone.localdate()
    earned = (
        DailyActivity.objects.filter(user=user, date=today)
        .aggregate(s=Sum("xp_earned"))["s"]
        or 0
    )
    return {
        "goal_xp": DAILY_GOAL_XP,
        "earned_xp": earned,
        "met": earned >= DAILY_GOAL_XP,
    }


def gamification_summary(user) -> dict:
    return {
        "total_xp": total_xp(user),
        "streak": current_streak(user),
        "daily_goal": daily_goal_status(user),
    }
