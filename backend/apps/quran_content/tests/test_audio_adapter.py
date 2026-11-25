"""Adapter tests for reciters and chapter audio (QF responses mocked at _content_get)."""
from unittest.mock import patch

import pytest
from django.core.cache import cache

from apps.quran_content.client import QuranFoundationClient


@pytest.fixture(autouse=True)
def _clear_cache():
    cache.clear()
    yield
    cache.clear()


@pytest.fixture
def client(settings):
    settings.QF_CLIENT_ID = "id"
    settings.QF_CLIENT_SECRET = "secret"
    settings.QF_AUTH_BASE = "https://auth.invalid"
    settings.QF_API_BASE = "https://api.invalid"
    settings.QF_CACHE_MAX_SECONDS = 60 * 60 * 24 * 30  # above 1 week; must be capped
    return QuranFoundationClient()


def _reciters_responses(path, params=None):
    if path == "resources/chapter_reciters":
        return {"reciters": [
            {"id": 6, "name": "Husary", "style": "Murattal"},
            {"id": 7, "name": "Alafasy", "style": "Murattal"},
            {"id": 12, "name": "Husary", "style": "Muallim"},
            {"id": 173, "name": "Alafasy", "style": "Streaming"},
        ]}
    return {"recitations": [{"id": 6, "reciter_name": "Husary"}, {"id": 7, "reciter_name": "Alafasy"}]}


def test_reciters_hide_173_label_12_and_cache(client):
    with patch.object(client, "_content_get", side_effect=_reciters_responses) as m:
        first = client.get_reciters()
        second = client.get_reciters()
    assert [r["id"] for r in first] == [6, 7, 12]
    assert next(r for r in first if r["id"] == 12)["style"] == "Muallim (teaching)"
    assert {r["id"]: r["has_per_ayah_audio"] for r in first} == {6: True, 7: True, 12: False}
    assert second == first
    assert m.call_count == 2  # one call per list, second get_reciters is cached


def _chapter(timestamps, duration=48000):
    return {"audio_file": {"audio_url": "https://dl.invalid/1.mp3", "duration": duration,
                           "timestamps": timestamps}}


def test_chapter_audio_normalises_data_problems(client):
    ts = [
        # reciter-7 style: malformed segment dropped, early start clamped, floats rounded
        {"verse_key": "1:1", "timestamp_from": 100, "timestamp_to": 1000, "duration": -900,
         "segments": [[1, 35, 400.4], [2, 400.6, 700], [3, 700], [4, 1, 2, 3], [5, "a", 1, 2]]},
        # overlap with 1:2 (starts before 1:1 ends) -> unusable
        {"verse_key": "1:2", "timestamp_from": 900, "timestamp_to": 2000, "duration": 1100,
         "segments": [[1, 900, 1000]]},
        # zero length -> unusable
        {"verse_key": "1:3", "timestamp_from": 2000.0, "timestamp_to": 2000.0, "duration": 0,
         "segments": [[1, 2000, 2000]]},
        {"verse_key": "1:4", "timestamp_from": 2000, "timestamp_to": 3000.6, "duration": 5,
         "segments": [[1, 2000, 3500]]},
    ]
    with patch.object(client, "_content_get", return_value=_chapter(ts)) as m:
        data = client.get_chapter_audio(7, 1)
    assert m.call_args.args[0] == "chapter_recitations/7/1"
    assert m.call_args.args[1] == {"segments": "true"}
    v = {x["verse_key"]: x for x in data["verses"]}
    assert v["1:1"]["words"] == [[1, 100, 400], [2, 401, 700]]
    assert v["1:1"]["duration_ms"] == 900 and v["1:1"]["usable"]
    assert not v["1:2"]["usable"] and v["1:2"]["words"] == []
    assert not v["1:3"]["usable"] and v["1:3"]["duration_ms"] == 0
    assert v["1:4"]["words"] == [[1, 2000, 3001]] and v["1:4"]["end_ms"] == 3001
    assert data["clip_end_ms"] == 3001  # last timestamp_to, not duration (48000)
    assert data["clip_start_ms"] == 100
    assert data["has_timings"] is True
    assert data["provenance"]["provider"] == "quran_foundation"
    assert data["provenance"]["caching_policy_ref"] == "qf_max_1_week"


def test_chapter_audio_cached_and_ttl_capped(client):
    ts = [{"verse_key": "1:1", "timestamp_from": 0, "timestamp_to": 10, "segments": [[1, 0, 10]]}]
    with patch.object(client, "_content_get", return_value=_chapter(ts)) as m, \
            patch("apps.quran_content.client.cache.set", wraps=cache.set) as cs:
        client.get_chapter_audio(7, 1)
        client.get_chapter_audio(7, 1)
    assert m.call_count == 1
    assert cs.call_args.kwargs["timeout"] == 60 * 60 * 24 * 7


def test_chapter_audio_without_segments_omits_param_and_timings(client):
    with patch.object(client, "_content_get", return_value=_chapter([])) as m:
        data = client.get_chapter_audio(6, 2, segments=False)
    assert m.call_args.args[1] is None
    assert data["verses"] == [] and data["has_timings"] is False and data["clip_end_ms"] is None
