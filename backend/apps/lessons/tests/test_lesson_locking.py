"""Locked lessons are refused by lesson detail and start-attempt (R4)."""
import pytest
from rest_framework.test import APIClient

from apps.accounts.models import AuthSession, User
from apps.common.lifecycle import ContentStatus
from apps.lessons.models import Lesson

pytestmark = pytest.mark.django_db

MESSAGE = "This lesson opens after you complete the one before it."


def _setup():
    user = User.objects.create(provider="google", provider_sub="lock", display_name="L")
    _, access, _ = AuthSession.issue(user)
    client = APIClient()
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
    first = Lesson.objects.create(title="One", surah=1, ayah_start=1, ayah_end=3,
                                  order=1, status=ContentStatus.PUBLISHED)
    second = Lesson.objects.create(title="Two", surah=1, ayah_start=4, ayah_end=7,
                                   order=2, status=ContentStatus.PUBLISHED)
    return client, first, second


def _assert_locked(resp):
    assert resp.status_code == 403
    err = resp.json()["error"]
    assert err["code"] == "lesson_locked"
    assert err["message"] == MESSAGE


def test_detail_of_locked_lesson_is_forbidden():
    client, _, second = _setup()
    _assert_locked(client.get(f"/api/v1/lessons/{second.id}/"))


def test_start_attempt_on_locked_lesson_is_forbidden():
    client, _, second = _setup()
    _assert_locked(client.post(f"/api/v1/lessons/{second.id}/attempts/"))


def test_first_lesson_can_start():
    client, first, _ = _setup()
    assert client.post(f"/api/v1/lessons/{first.id}/attempts/").status_code == 201
