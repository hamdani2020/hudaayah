"""Unlock order, grandfathering and cross-user isolation of lesson_states (R3, R4)."""
import pytest
from rest_framework.test import APIClient

from apps.accounts.models import AuthSession, User
from apps.common.lifecycle import ContentStatus
from apps.exercises.models import Exercise, ExerciseType
from apps.lessons.models import Lesson
from apps.lessons.services import is_lesson_unlocked, lesson_states
from apps.progress.models import ProgressState, UserProgress

pytestmark = pytest.mark.django_db


def _user(sub):
    return User.objects.create(provider="google", provider_sub=sub, display_name=sub)


def _lessons(n=3):
    out = []
    for i in range(1, n + 1):
        lesson = Lesson.objects.create(
            title=f"L{i}", surah=1, ayah_start=i, ayah_end=i, order=i,
            status=ContentStatus.PUBLISHED,
        )
        Exercise.objects.create(
            lesson=lesson, type=ExerciseType.MULTIPLE_CHOICE, position=1,
            status=ContentStatus.PUBLISHED,
            config={"options": [{"id": "a"}]}, answer_key={"correct_option_id": "a"},
        )
        out.append(lesson)
    return out


def _states(user):
    return [s["state"] for s in lesson_states(user)]


def _mark(user, lesson, state):
    UserProgress.objects.create(user=user, lesson=lesson, state=state)


def test_fresh_user_only_first_lesson_is_open():
    _lessons()
    user = _user("fresh")
    assert _states(user) == ["available", "locked", "locked"]


def test_completing_a_lesson_unlocks_only_the_next():
    one, two, three = _lessons()
    user = _user("order")
    _mark(user, one, ProgressState.COMPLETED)
    assert _states(user) == ["completed", "available", "locked"]
    assert is_lesson_unlocked(user, two)
    assert not is_lesson_unlocked(user, three)


def test_started_lesson_stays_unlocked_even_if_previous_is_incomplete():
    _, two, three = _lessons()
    user = _user("grandfather")
    _mark(user, two, ProgressState.IN_PROGRESS)
    assert _states(user) == ["available", "in_progress", "locked"]
    assert is_lesson_unlocked(user, two)
    assert not is_lesson_unlocked(user, three)


def test_completed_lesson_stays_unlocked_when_previous_is_incomplete():
    _, two, _ = _lessons()
    user = _user("grandfather2")
    _mark(user, two, ProgressState.COMPLETED)
    assert _states(user) == ["available", "completed", "available"]


def test_unlocking_is_isolated_between_users():
    one, two, _ = _lessons()
    a, b = _user("iso-a"), _user("iso-b")
    _mark(a, one, ProgressState.COMPLETED)
    assert _states(a) == ["completed", "available", "locked"]
    assert _states(b) == ["available", "locked", "locked"]
    assert is_lesson_unlocked(a, two)
    assert not is_lesson_unlocked(b, two)


def test_other_users_completion_does_not_open_lesson_over_http():
    one, two, _ = _lessons()
    a, b = _user("http-a"), _user("http-b")
    _mark(a, one, ProgressState.COMPLETED)
    _, access, _ = AuthSession.issue(b)
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
    resp = client.get(f"/api/v1/lessons/{two.id}/")
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "lesson_locked"
