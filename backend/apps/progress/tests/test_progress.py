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
    assert [(l["lesson_id"], l["state"]) for l in body["lessons"]] == [
        (lesson.id, "available")]


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


def test_week_activity_is_current_calendar_week():
    from datetime import date

    from apps.gamification.services import week_activity

    _, user = _client()
    wednesday = date(2026, 11, 18)  # a Wednesday
    # Active Monday and Wednesday of this week; last Sunday belongs to the previous week.
    for d in (date(2026, 11, 16), wednesday, date(2026, 11, 15)):
        DailyActivity.objects.create(user=user, date=d, xp_earned=10, lessons_completed=1)
    week = week_activity(user, today=wednesday)
    assert [d["date"] for d in week] == [
        "2026-11-16", "2026-11-17", "2026-11-18", "2026-11-19",
        "2026-11-20", "2026-11-21", "2026-11-22",
    ]
    assert [d["active"] for d in week] == [True, False, True, False, False, False, False]
    assert [d["is_today"] for d in week] == [False, False, True, False, False, False, False]


def test_week_activity_is_user_scoped_and_in_summary():
    lesson, ex = _lesson()
    a, _ = _client(sub="wa")
    _complete(a, lesson, ex, "kw")
    b, _ = _client(sub="wb")
    week_b = b.get("/api/v1/progress/").json()["week"]
    assert len(week_b) == 7
    assert not any(d["active"] for d in week_b)
    week_a = a.get("/api/v1/progress/").json()["week"]
    assert any(d["active"] and d["is_today"] for d in week_a)


def test_summary_lists_every_published_lesson_with_state():
    from apps.progress.summary import progress_summary
    _, user = _client("p3")
    first, _ex = _lesson()
    second = Lesson.objects.create(
        title="Al-Baqarah 1-5", surah=2, ayah_start=1, ayah_end=5, order=2,
        status=ContentStatus.PUBLISHED,
    )
    Lesson.objects.create(title="Draft", surah=3, ayah_start=1, ayah_end=2, order=3)
    lessons = progress_summary(user)["lessons"]
    assert [(l["lesson_id"], l["state"]) for l in lessons] == [
        (first.id, "available"), (second.id, "locked")]
    assert lessons[0]["exercises_total"] == 1
    assert lessons[0]["exercises_answered"] == 0
    assert lessons[0]["previous_title"] is None
    assert lessons[1]["previous_title"] == "Al-Fatihah"


def test_completion_response_has_streak_week_total_and_replays_identically():
    lesson, ex = _lesson()
    client, user = _client(sub="p4")
    DailyActivity.objects.create(
        user=user, date=timezone.localdate() - timedelta(days=1),
        xp_earned=10, lessons_completed=1,
    )
    aid = client.post(f"/api/v1/lessons/{lesson.id}/attempts/").json()["id"]
    client.post(f"/api/v1/attempts/{aid}/answers/",
                {"exercise_id": ex.id, "submitted": {"selected_option_id": "a"}},
                format="json")
    url = f"/api/v1/attempts/{aid}/complete/"
    first = client.post(url, {"idempotency_key": "k"}, format="json").json()
    assert first["streak"] == {"current": 2, "previous": 1, "increased": True}
    assert first["total_xp"] == 20
    assert len(first["week"]) == 7
    again = client.post(url, {"idempotency_key": "k"}, format="json").json()
    assert again == first


def test_streak_increased_only_on_first_completion_of_the_day():
    lesson, ex = _lesson()
    second = Lesson.objects.create(
        title="Two", surah=1, ayah_start=2, ayah_end=2, order=2,
        status=ContentStatus.PUBLISHED,
    )
    ex2 = Exercise.objects.create(
        lesson=second, type=ExerciseType.MULTIPLE_CHOICE, position=1,
        status=ContentStatus.PUBLISHED,
        config={"options": [{"id": "a"}]}, answer_key={"correct_option_id": "a"},
    )
    client, _ = _client(sub="streak-day")
    bodies = []
    for les, e, key in ((lesson, ex, "k1"), (second, ex2, "k2")):
        aid = client.post(f"/api/v1/lessons/{les.id}/attempts/").json()["id"]
        client.post(f"/api/v1/attempts/{aid}/answers/",
                    {"exercise_id": e.id, "submitted": {"selected_option_id": "a"}},
                    format="json")
        bodies.append(client.post(f"/api/v1/attempts/{aid}/complete/",
                                  {"idempotency_key": key}, format="json").json())
    assert bodies[0]["streak"] == {"current": 1, "previous": 0, "increased": True}
    assert bodies[1]["streak"] == {"current": 1, "previous": 1, "increased": False}
