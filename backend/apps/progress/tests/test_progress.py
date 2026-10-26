"""Progress summary, XP/streak, and duplicate-submission durability (R5, 5.4)."""
from datetime import timedelta

import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.models import AuthSession, User
from apps.common.lifecycle import ContentStatus
from apps.exercises.models import Exercise, ExerciseType
from apps.gamification.services import current_streak
from apps.lessons.models import Lesson
from apps.progress.models import DailyActivity, LessonAttempt

pytestmark = pytest.mark.django_db


def _client(sub="p5"):
    user, _ = User.objects.get_or_create(
        provider="google", provider_sub=sub, defaults={"display_name": sub}
    )
    _, access, _ = AuthSession.issue(user)
    c = APIClient()
    c.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
    return c, user


def _lesson():
    lesson = Lesson.objects.create(
        title="Al-Fatihah", surah=1, ayah_start=1, ayah_end=1,
        status=ContentStatus.PUBLISHED,
    )
    ex = Exercise.objects.create(
        lesson=lesson, type=ExerciseType.MULTIPLE_CHOICE, position=1,
        status=ContentStatus.PUBLISHED,
        config={"options": [{"id": "a"}]}, answer_key={"correct_option_id": "a"},
    )
    return lesson, ex


def _complete(client, lesson, ex, key):
    aid = client.post(f"/api/v1/lessons/{lesson.id}/attempts/").json()["id"]
    client.post(f"/api/v1/attempts/{aid}/answers/",
                {"exercise_id": ex.id, "submitted": {"selected_option_id": "a"}},
                format="json")
    client.post(f"/api/v1/attempts/{aid}/complete/",
                {"idempotency_key": key}, format="json")
    return aid


def test_progress_summary_reflects_completion():
    lesson, ex = _lesson()
    client, _ = _client()
    _complete(client, lesson, ex, "k1")
    body = client.get("/api/v1/progress/").json()
    assert body["total_xp"] == 10
    assert body["streak"] == 1
    assert body["daily_goal"]["met"] is True
    assert body["lessons"][0]["state"] == "completed"


def test_progress_is_user_scoped():
    lesson, ex = _lesson()
    a, _ = _client(sub="a")
    _complete(a, lesson, ex, "ka")
    b, _ = _client(sub="b")  # different user, no activity
    body = b.get("/api/v1/progress/").json()
    assert body["total_xp"] == 0
    assert body["lessons"] == []


def test_duplicate_completion_does_not_double_award():
    lesson, ex = _lesson()
    client, user = _client()
    aid = client.post(f"/api/v1/lessons/{lesson.id}/attempts/").json()["id"]
    client.post(f"/api/v1/attempts/{aid}/answers/",
                {"exercise_id": ex.id, "submitted": {"selected_option_id": "a"}},
                format="json")
    # Complete the same attempt three times.
    for _ in range(3):
        client.post(f"/api/v1/attempts/{aid}/complete/",
                    {"idempotency_key": "dup"}, format="json")
    activity = DailyActivity.objects.get(user=user)
    assert activity.xp_earned == 10
    assert activity.lessons_completed == 1
    assert LessonAttempt.objects.get(pk=aid).status == "completed"


def test_streak_counts_consecutive_days():
    _, user = _client()
    today = timezone.localdate()
    for d in (today, today - timedelta(days=1), today - timedelta(days=2)):
        DailyActivity.objects.create(user=user, date=d, xp_earned=10, lessons_completed=1)
    # A gap breaks older days.
    DailyActivity.objects.create(
        user=user, date=today - timedelta(days=4), xp_earned=10, lessons_completed=1
    )
    assert current_streak(user, today=today) == 3


def test_streak_alive_if_yesterday_but_not_today():
    _, user = _client()
    today = timezone.localdate()
    DailyActivity.objects.create(
        user=user, date=today - timedelta(days=1), xp_earned=10, lessons_completed=1
    )
    assert current_streak(user, today=today) == 1
