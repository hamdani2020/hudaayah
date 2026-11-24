"""Lesson endpoint tests: auth required, published-only, QF content assembly
(adapter mocked), and content-layer separation."""
from unittest.mock import patch

import pytest
from rest_framework.test import APIClient

from apps.accounts.models import AuthSession, User
from apps.common.lifecycle import ContentStatus
from apps.lessons.models import ContentSource, Lesson

pytestmark = pytest.mark.django_db


def _auth_client():
    user, _ = User.objects.get_or_create(
        provider="google", provider_sub="reader", defaults={"display_name": "Reader"}
    )
    _, access, _ = AuthSession.issue(user)
    c = APIClient()
    c.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
    return c


def _make_lesson(status=ContentStatus.PUBLISHED):
    tr = ContentSource.objects.create(
        resource_type=ContentSource.ResourceType.TRANSLATION,
        provider_ref="85", attribution="M.A.S. Abdel Haleem",
    )
    rec = ContentSource.objects.create(
        resource_type=ContentSource.ResourceType.RECITATION,
        provider_ref="7", attribution="Mishary Rashid Alafasy",
    )
    return Lesson.objects.create(
        title="Surah Al-Fatihah", surah=1, ayah_start=1, ayah_end=1,
        status=status, translation_source=tr, recitation_source=rec,
    )


# A fake QF client returning deterministic shapes.
class _FakeQF:
    def get_word_by_word(self, verse_key):
        return {"verse": {"text_uthmani": "بِسْمِ ٱللَّهِ",
                          "words": [{"position": 1, "char_type_name": "word",
                                     "text_uthmani": "بِسْمِ",
                                     "translation": {"text": "In (the) name"},
                                     "transliteration": {"text": "bis'mi"}},
                                    {"position": 2, "char_type_name": "end",
                                     "text_uthmani": "١"}]}}

    def get_translation(self, verse_key, translation_id):
        return {"translations": [{"text": "In the name of God..."}]}

    def get_audio(self, verse_key, reciter_id):
        return {"audio_files": [{"url": "Alafasy/mp3/001001.mp3"}]}

    def get_reciters(self):
        return [{"id": 7, "name": "Alafasy", "style": "Murattal", "has_per_ayah_audio": True}]

    def get_chapter_audio(self, reciter_id, chapter, segments=True):
        from apps.quran_content.client import QFContentError
        raise QFContentError(code="qf_not_found")


def test_lesson_requires_auth():
    assert APIClient().get("/api/v1/lessons/1/").status_code == 401


def test_published_lesson_returns_assembled_content():
    lesson = _make_lesson()
    with patch("apps.lessons.services.get_client", return_value=_FakeQF()):
        resp = _auth_client().get(f"/api/v1/lessons/{lesson.id}/")
    assert resp.status_code == 200
    body = resp.json()
    ayah = body["content"]["ayahs"][0]
    # Layer separation: sacred arabic + attributed translation both present & distinct.
    assert ayah["arabic"] == "بِسْمِ ٱللَّهِ"
    assert ayah["translation"] == "In the name of God..."
    assert ayah["audio_url"].startswith("https://")
    # Word position is 1-based (matches audio word_index); end marker is skipped.
    assert [w["position"] for w in ayah["words"]] == [1]
    assert "Quran Foundation" in body["content"]["attribution"]


def test_draft_lesson_is_not_served():
    lesson = _make_lesson(status=ContentStatus.DRAFT)
    resp = _auth_client().get(f"/api/v1/lessons/{lesson.id}/")
    assert resp.status_code == 404
    assert resp.json()["error"]["code"] == "lesson_not_available"


def test_mark_published_stamps_audit():
    lesson = _make_lesson(status=ContentStatus.DRAFT)
    staff = User.objects.create_user(provider="google", provider_sub="staff-1",
                                     display_name="Staff")
    lesson.mark_published(by=staff)
    lesson.refresh_from_db()
    assert lesson.status == ContentStatus.PUBLISHED
    assert lesson.approved_by_id == staff.id
    assert lesson.approved_at is not None


# --- reader-display D2: word chips and ayah-number detection ---------------------

def _word(pos, char_type, text="كلمة"):
    return {"position": pos, "char_type_name": char_type, "text_qpc_hafs": text,
            "translation": {"text": "t"}, "transliteration": {"text": "tr"}}


class _QFWithText:
    """Fake QF returning a chosen verse text/fields, as the two QF text types do."""

    def __init__(self, verse):
        self._verse = verse

    def get_word_by_word(self, verse_key):
        return {"verse": self._verse}

    def get_translation(self, verse_key, translation_id):
        return {"translations": [{"text": "x"}]}

    def get_audio(self, verse_key, reciter_id):
        return {"audio_files": [{"url": "Alafasy/mp3/001001.mp3"}]}

    def get_reciters(self):
        return []


def _fetch_ayah(verse):
    lesson = _make_lesson()
    with patch("apps.lessons.services.get_client", return_value=_QFWithText(verse)):
        resp = _auth_client().get(f"/api/v1/lessons/{lesson.id}/")
    assert resp.status_code == 200
    return resp.json()["content"]["ayahs"][0]


def test_qpc_hafs_text_with_marker_is_flagged():
    ayah = _fetch_ayah({"text_qpc_hafs": "بِسْمِ ٱللَّهِ\u00a0١", "words": []})
    assert ayah["arabic"] == "بِسْمِ ٱللَّهِ\u00a0١"  # text untouched
    assert ayah["text_has_ayah_number"] is True


def test_qpc_hafs_text_with_sign_and_eastern_digit_is_flagged():
    ayah = _fetch_ayah({"text_qpc_hafs": "بِسْمِ\u00a0\u06dd۲ ", "words": []})
    assert ayah["text_has_ayah_number"] is True


def test_uthmani_text_without_marker_is_not_flagged():
    ayah = _fetch_ayah({"text_uthmani": "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ", "words": []})
    assert ayah["arabic"] == "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ"
    assert ayah["text_has_ayah_number"] is False


def test_non_word_entries_are_dropped_and_positions_kept():
    ayah = _fetch_ayah({
        "text_uthmani": "x",
        "words": [_word(1, "word"), _word(2, "pause"), _word(3, "word"),
                  _word(4, "sajdah"), _word(5, "rub-el-hizb"), _word(6, "end", "١")],
    })
    assert [w["position"] for w in ayah["words"]] == [1, 3]
