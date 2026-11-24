"""Lesson detail `audio` block: reciter choice, chapter vs per-ayah mode, fallback."""
from unittest.mock import patch

import pytest
from rest_framework.test import APIClient

from apps.accounts.models import AuthSession, User
from apps.common.lifecycle import ContentStatus
from apps.lessons.models import ContentSource, Lesson
from apps.quran_content.client import QFContentError

pytestmark = pytest.mark.django_db

RECITERS = [
    {"id": 6, "name": "Husary", "style": "Murattal", "has_per_ayah_audio": True},
    {"id": 7, "name": "Alafasy", "style": "Murattal", "has_per_ayah_audio": True},
    {"id": 12, "name": "Husary", "style": "Muallim (teaching)", "has_per_ayah_audio": False},
]


def _verse(key, start, end, usable=True):
    return {"verse_key": key, "start_ms": start, "end_ms": end, "duration_ms": end - start,
            "usable": usable, "words": [[1, start, end]] if usable else []}


class _FakeQF:
    def __init__(self, chapters):
        self.chapters = chapters  # {(reciter, chapter): [verses]}

    def get_reciters(self):
        return RECITERS

    def get_chapter_audio(self, reciter_id, chapter, segments=True):
        verses = self.chapters.get((reciter_id, chapter))
        if verses is None:
            raise QFContentError(code="qf_not_found")
        return {"audio_url": f"https://cdn/{reciter_id}/{chapter}.mp3", "verses": verses,
                "has_timings": True, "provenance": {"provider": "quran_foundation"}}

    def get_audio(self, verse_key, reciter_id):
        return {"audio_files": [{"url": f"https://cdn/{reciter_id}/{verse_key}.mp3"}]}

    def get_word_by_word(self, verse_key):
        return {"verse": {"text_qpc_hafs": "x", "words": []}}

    def get_translation(self, verse_key, translation_id):
        return {"translations": [{"text": "t"}]}


def _client(preferences=None):
    user, _ = User.objects.get_or_create(
        provider="google", provider_sub="a", defaults={"display_name": "A"})
    user.preferences = preferences or {}
    user.save()
    _, access, _ = AuthSession.issue(user)
    c = APIClient()
    c.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
    return c


def _lesson(surah=1, start=1, end=2):
    rec, _ = ContentSource.objects.get_or_create(
        resource_type=ContentSource.ResourceType.RECITATION, provider_ref="7",
        defaults={"attribution": "Mishary Rashid Alafasy"})
    return Lesson.objects.create(title="L", surah=surah, ayah_start=start, ayah_end=end,
                                 status=ContentStatus.PUBLISHED, recitation_source=rec)


def _get(chapters, lesson, query="", **client_kw):
    with patch("apps.lessons.services.get_client", return_value=_FakeQF(chapters)):
        return _client(**client_kw).get(f"/api/v1/lessons/{lesson.id}/{query}")


CH1 = [_verse("1:1", 0, 1000), _verse("1:2", 1000, 2500), _verse("1:3", 2500, 4000)]


def test_chapter_mode_clips_to_lesson_range_and_keeps_audio_url():
    body = _get({(7, 1): CH1}, _lesson(1, 2, 3)).json()
    audio = body["audio"]
    assert audio["mode"] == "chapter"
    assert audio["reciter"] == {"id": 7, "name": "Alafasy", "style": "Murattal"}
    assert [v["verse_key"] for v in audio["verses"]] == ["1:2", "1:3"]
    assert (audio["clip_start_ms"], audio["clip_end_ms"]) == (1000, 4000)
    assert audio["has_word_timings"] is True
    assert audio["fallback_from"] is None
    assert body["content"]["ayahs"][0]["audio_url"] == "https://cdn/7/1:2.mp3"
    assert "Alafasy" in body["content"]["attribution"]


def test_unusable_verse_outside_lesson_range_does_not_block_chapter_mode():
    chapters = {(7, 1): [CH1[0], _verse("1:2", 900, 900, usable=False), CH1[2]]}
    assert _get(chapters, _lesson(1, 3, 3)).json()["audio"]["mode"] == "chapter"


def test_unusable_verse_in_lesson_range_falls_to_per_ayah():
    chapters = {(7, 1): [CH1[0], _verse("1:2", 900, 900, usable=False), CH1[2]]}
    audio = _get(chapters, _lesson(1, 1, 2)).json()["audio"]
    assert audio["mode"] == "per_ayah"
    assert audio["chapter_url"] is None
    assert audio["verses"][1] == {"verse_key": "1:2", "audio_url": "https://cdn/7/1:2.mp3"}


def test_reciter_param_beats_preference():
    chapters = {(6, 1): CH1, (7, 1): CH1}
    resp = _get(chapters, _lesson(), "?reciter=6", preferences={"reciter_id": 7})
    assert resp.json()["audio"]["reciter"]["id"] == 6
    resp = _get(chapters, _lesson(), preferences={"reciter_id": 6})
    assert resp.json()["audio"]["reciter"]["id"] == 6
    assert "Husary" in resp.json()["content"]["attribution"]


def test_unavailable_reciter_falls_back_and_says_so():
    # Reciter 12 has no chapter file for this surah and no per-ayah files.
    audio = _get({(7, 1): CH1}, _lesson(), "?reciter=12").json()["audio"]
    assert audio["reciter"]["id"] == 7
    assert audio["fallback_from"] == 12


def test_garbage_reciter_param_is_ignored():
    audio = _get({(7, 1): CH1}, _lesson(), "?reciter=abc").json()["audio"]
    assert audio["reciter"]["id"] == 7 and audio["fallback_from"] is None


def test_no_audio_anywhere_gives_null_block():
    class _NoAudio(_FakeQF):
        def get_audio(self, verse_key, reciter_id):
            return {"audio_files": []}

    lesson = _lesson()
    with patch("apps.lessons.services.get_client", return_value=_NoAudio({})):
        resp = _client().get(f"/api/v1/lessons/{lesson.id}/")
    assert resp.status_code == 200 and resp.json()["audio"] is None
