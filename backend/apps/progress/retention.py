"""Day-1 / Day-2 / Day-7 return rates (the pilot's key metric, product steering).

A learner's cohort is the day they signed up (`User.created_at`, server date). They
"returned on Day N" when they were active on signup day + N. Two definitions:

- ``lesson``: completed a lesson that day (``DailyActivity`` with XP). Available for the
  whole pilot.
- ``open``: opened the app that day (``AppOpenDay``), or completed a lesson (which
  implies an open). Only recorded from app 1.1.1 on, so earlier days undercount.

A learner counts toward Day N only once Day N has fully passed (signup + N < today),
so today's numbers are never half-finished. Staff accounts are excluded.
"""
from __future__ import annotations

from collections import defaultdict
from dataclasses import dataclass, field
from datetime import date, timedelta

from django.contrib.auth import get_user_model
from django.utils import timezone

from .models import AppOpenDay, DailyActivity

DAYS = (1, 2, 7)
METRICS = ("lesson", "open")


@dataclass
class DayRate:
    eligible: int = 0
    returned: int = 0

    @property
    def percent(self) -> float | None:
        return round(100 * self.returned / self.eligible, 1) if self.eligible else None


@dataclass
class CohortRow:
    signup_date: date | None  # None for the "all" row
    signups: int = 0
    rates: dict[int, DayRate] = field(default_factory=lambda: {d: DayRate() for d in DAYS})


def _active_days(metric: str, user_ids: list[int]) -> dict[int, set[date]]:
    days: dict[int, set[date]] = defaultdict(set)
    lessons = DailyActivity.objects.filter(user_id__in=user_ids, xp_earned__gt=0)
    for uid, d in lessons.values_list("user_id", "date"):
        days[uid].add(d)
    if metric == "open":
        opens = AppOpenDay.objects.filter(user_id__in=user_ids)
        for uid, d in opens.values_list("user_id", "date"):
            days[uid].add(d)
    return days


def retention(metric: str = "lesson", *, since: date | None = None,
              today: date | None = None) -> list[CohortRow]:
    """Rows per signup date (oldest first), then an "all" row (signup_date=None)."""
    if metric not in METRICS:
        raise ValueError(f"metric must be one of {METRICS}")
    today = today or timezone.localdate()

    users = get_user_model().objects.filter(is_staff=False)
    signups = {
        u.pk: timezone.localtime(u.created_at).date()
        for u in users.only("pk", "created_at")
    }
    if since:
        signups = {uid: d for uid, d in signups.items() if d >= since}
    active = _active_days(metric, list(signups))

    rows: dict[date, CohortRow] = {}
    total = CohortRow(signup_date=None)
    for uid, signup in signups.items():
        row = rows.setdefault(signup, CohortRow(signup_date=signup))
        row.signups += 1
        total.signups += 1
        for n in DAYS:
            day = signup + timedelta(days=n)
            if day >= today:
                continue  # Day N not finished yet
            came_back = day in active.get(uid, set())
            for target in (row, total):
                target.rates[n].eligible += 1
                target.rates[n].returned += int(came_back)
    return [rows[d] for d in sorted(rows)] + [total]
