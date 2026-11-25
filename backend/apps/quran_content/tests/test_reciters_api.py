"""GET /reciters/: auth, shape, has_timings and per-surah availability (adapter faked)."""
from unittest.mock import patch

import pytest
from rest_framework.test import APIClient

from apps.accounts.models import AuthSession, User
from apps.common.lifecycle import ContentStatus
from apps.lessons.models import Lesson
from apps.quran_content.client import QFContentError

pytestmark = pytest.mark.django_db

URL = "/api/v1/reciters/"


class _FakeQF:
    def get_reciters(self):
        return [
            {"id": 6, "name": "Husary", "style": "Murattal", "has_per_ayah_audio": True},
            {"id": 7, "name": "Alafasy", "style": "Murattal", "has_per_ayah_audio": True},
            {"id": 12, "name": "Husary", "style": "Muallim (teaching)", "has_per_ayah_audio": False},
        ]

    def get_chapter_audio(self, reciter_id, chapter, segments=True):
        if reciter_id == 6 and chapter == 2:
            return {"has_timings": False}
        if reciter_id == 7 and chapter == 2:
            raise QFContentError(code="qf_not_found")  # per-ayah fallback only
        if reciter_id == 12 and chapter == 2:
            raise QFContentError(code="qf_not_found")  # no fallback -> dropped
        return {"has_timings": True}


@pytest.fixture(autouse=True)
def _qf():
    with patch("apps.quran_content.services.get_client", return_value=_FakeQF()):
        yield


def _auth():
    user = User.objects.create_user(provider="google", provider_sub="r", display_name="R")
    _, access, _ = AuthSession.issue(user)
    c = APIClient()
    c.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
    return c


def _lesson(surah, status=ContentStatus.PUBLISHED):
    return Lesson.objects.create(title=f"S{surah}", surah=surah, status=status)


def test_requires_auth():
    assert APIClient().get(URL).status_code == 401


def test_lists_reciters_with_timings_flag():
    _lesson(1)
    resp = _auth().get(URL)
    assert resp.status_code == 200
    assert resp.json() == [
        {"id": 6, "name": "Husary", "style": "Murattal", "has_timings": True},
        {"id": 7, "name": "Alafasy", "style": "Murattal", "has_timings": True},
        {"id": 12, "name": "Husary", "style": "Muallim (teaching)", "has_timings": True},
    ]


def test_surah_without_chapter_audio_drops_or_unflags():
    _lesson(1)
    _lesson(2)
    resp = _auth().get(URL)
    assert resp.status_code == 200
    # 6: chapter file without usable timings; 7: per-ayah only; 12: no audio -> dropped.
    assert resp.json() == [
        {"id": 6, "name": "Husary", "style": "Murattal", "has_timings": False},
        {"id": 7, "name": "Alafasy", "style": "Murattal", "has_timings": False},
    ]


def test_unpublished_lessons_ignored():
    _lesson(1)
    _lesson(2, status=ContentStatus.DRAFT)
    assert len(_auth().get(URL).json()) == 3
