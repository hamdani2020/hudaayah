"""Single adapter for all Quran Foundation (QF) Content API access.

No other module may call QF directly. Auth is OAuth2 client_credentials
(scope=content, no refresh token). Access tokens (~3600s) are cached and
re-requested before expiry; on 401 the token is cleared and the request retried once.

Hard rules (steering: tech / quran-content-rules / qf-content-adapter skill):
- client_secret is backend-only; never shipped, logged, or committed.
- Every content request sends headers `x-auth-token` and `x-client-id`.
- Cache QF responses at most 1 week.
- Never leak provider errors or secrets to the client; use stable internal codes.
"""
from __future__ import annotations

import logging
import numbers

import requests
from django.conf import settings
from django.core.cache import cache
from django.utils import timezone

from apps.common.errors import AppError, UpstreamError

logger = logging.getLogger(__name__)

_TOKEN_CACHE_KEY = "qf:access_token"
_TOKEN_SKEW_SECONDS = 60  # refresh a minute before expiry
_HTTP_TIMEOUT = (5, 15)  # (connect, read) seconds


# Owner decisions (reader-audio A0): reciter 173 (Afasy Streaming) is hidden from the
# picker; reciter 12 is listed as "Muallim (teaching)". Reciter 7 stays the default.
HIDDEN_RECITER_IDS = frozenset({173})
RECITER_STYLE_OVERRIDES = {12: "Muallim (teaching)"}
DEFAULT_RECITER_ID = 7
_CHAPTER_AUDIO_CACHE_VERSION = "v1"


def _is_number(value) -> bool:
    return isinstance(value, numbers.Real) and not isinstance(value, bool)


def _to_ms(value) -> int:
    return int(round(value))


def _text(value) -> str:
    """Return a plain string from a QF field that may be a string or {name: ...}."""
    if isinstance(value, dict):
        value = value.get("name")
    return value.strip() if isinstance(value, str) else ""


def _verse_number(verse_key: str) -> int:
    try:
        return int(str(verse_key).split(":")[1])
    except (IndexError, ValueError):
        return 0


def normalize_segments(raw_segments, start_ms: int, end_ms: int) -> list[list[int]]:
    """Clean word segments: keep only `[word_index, start, end]` triples of numbers,
    round to whole ms and clamp into the verse range. Words may be missing."""
    words: list[list[int]] = []
    for seg in raw_segments or []:
        if not isinstance(seg, (list, tuple)) or len(seg) != 3:
            continue
        if not all(_is_number(n) for n in seg):
            continue
        index, w_start, w_end = _to_ms(seg[0]), _to_ms(seg[1]), _to_ms(seg[2])
        if index < 1:
            continue
        w_start = min(max(w_start, start_ms), end_ms)
        w_end = min(max(w_end, start_ms), end_ms)
        if w_end < w_start:
            continue
        words.append([index, w_start, w_end])
    return words


def normalize_timestamps(raw_timestamps) -> list[dict]:
    """Normalise per-verse timings. Verse `duration` from QF is ignored (reciter 6
    sends negatives); it is recomputed as end - start.

    A verse is `usable` only if it has positive length and does not start before an
    earlier verse ends. Unusable verses carry no word timings.
    """
    entries = []
    for t in raw_timestamps or []:
        if not isinstance(t, dict) or not t.get("verse_key"):
            continue
        if not (_is_number(t.get("timestamp_from")) and _is_number(t.get("timestamp_to"))):
            continue
        entries.append(t)
    entries.sort(key=lambda t: _verse_number(t["verse_key"]))

    verses: list[dict] = []
    previous_end = None
    for t in entries:
        start, end = _to_ms(t["timestamp_from"]), _to_ms(t["timestamp_to"])
        duration = end - start
        overlaps = previous_end is not None and start < previous_end
        usable = duration > 0 and not overlaps
        verses.append(
            {
                "verse_key": t["verse_key"],
                "start_ms": start,
                "end_ms": end,
                "duration_ms": duration,
                "usable": usable,
                "words": normalize_segments(t.get("segments"), start, end) if usable else [],
            }
        )
        if duration > 0:
            previous_end = end if previous_end is None else max(previous_end, end)
    return verses


class QFConfigError(AppError):
    code = "qf_not_configured"
    message = "Quran content is temporarily unavailable."
    http_status = 503


class QFContentError(AppError):
    code = "qf_content_error"
    message = "Could not load Quran content."
    http_status = 502


class QuranFoundationClient:
    """Thin raw-HTTP adapter around the QF v4 Content API."""

    def __init__(self):
        self.client_id = settings.QF_CLIENT_ID
        self.client_secret = settings.QF_CLIENT_SECRET
        self.auth_base = settings.QF_AUTH_BASE.rstrip("/")
        self.api_base = settings.QF_API_BASE.rstrip("/")
        self.cache_ttl = min(settings.QF_CACHE_MAX_SECONDS, 60 * 60 * 24 * 7)

    # ── token handling ────────────────────────────────────────────────────────
    def _request_token(self) -> str:
        if not (self.client_id and self.client_secret):
            raise QFConfigError()
        try:
            resp = requests.post(
                f"{self.auth_base}/oauth2/token",
                auth=(self.client_id, self.client_secret),
                data={"grant_type": "client_credentials", "scope": "content"},
                headers={"Content-Type": "application/x-www-form-urlencoded"},
                timeout=_HTTP_TIMEOUT,
            )
        except requests.RequestException:
            logger.warning("QF token request failed (network).")
            raise UpstreamError()

        if resp.status_code != 200:
            # Do not log the body — it may echo credentials.
            logger.warning("QF token request returned %s", resp.status_code)
            raise UpstreamError()

        payload = resp.json()
        token = payload.get("access_token")
        expires_in = int(payload.get("expires_in", 3600))
        if not token:
            raise UpstreamError()

        cache.set(_TOKEN_CACHE_KEY, token, timeout=max(expires_in - _TOKEN_SKEW_SECONDS, 30))
        return token

    def _get_token(self, *, force_refresh: bool = False) -> str:
        if not force_refresh:
            cached = cache.get(_TOKEN_CACHE_KEY)
            if cached:
                return cached
        return self._request_token()

    # ── content requests ──────────────────────────────────────────────────────
    def _content_get(self, path: str, params: dict | None = None) -> dict:
        """GET a v4 content resource with the dual QF headers and 401 retry-once."""
        url = f"{self.api_base}/content/api/v4/{path.lstrip('/')}"

        def _do(token: str) -> requests.Response:
            return requests.get(
                url,
                params=params or {},
                headers={"x-auth-token": token, "x-client-id": self.client_id},
                timeout=_HTTP_TIMEOUT,
            )

        try:
            token = self._get_token()
            resp = _do(token)
            if resp.status_code == 401:
                # Clear cached token, re-request once, retry once.
                cache.delete(_TOKEN_CACHE_KEY)
                resp = _do(self._get_token(force_refresh=True))
        except requests.RequestException:
            logger.warning("QF content request failed (network): %s", path)
            raise UpstreamError()

        return self._handle_response(resp, path)

    def _handle_response(self, resp: requests.Response, path: str) -> dict:
        status = resp.status_code
        if status == 200:
            return resp.json()
        # Map upstream statuses to stable internal errors; never leak provider body.
        logger.warning("QF content %s -> %s", path, status)
        if status in (400, 422):
            raise QFContentError("Invalid Quran content request.", code="qf_bad_request")
        if status == 403:
            raise QFContentError(code="qf_forbidden")
        if status == 404:
            raise QFContentError("Requested Quran content was not found.", code="qf_not_found")
        if status == 429:
            raise UpstreamError("Quran content is rate-limited. Please try again shortly.")
        raise UpstreamError()

    def _cached_get(self, cache_key: str, path: str, params: dict | None = None) -> dict:
        hit = cache.get(cache_key)
        if hit is not None:
            return hit
        data = self._content_get(path, params)
        cache.set(cache_key, data, timeout=self.cache_ttl)
        return data

    # ── public interface (map to real v4 resources) ───────────────────────────
    def get_chapters(self, language: str = "en") -> dict:
        return self._cached_get(f"qf:chapters:{language}", "chapters", {"language": language})

    def get_chapter(self, chapter_id: int, language: str = "en") -> dict:
        return self._cached_get(
            f"qf:chapter:{chapter_id}:{language}", f"chapters/{chapter_id}", {"language": language}
        )

    def get_verses(self, chapter_id: int, page: int = 1) -> dict:
        return self._cached_get(
            f"qf:verses:{chapter_id}:{page}",
            f"verses/by_chapter/{chapter_id}",
            {"page": page},
        )

    def get_translation(self, verse_key: str, translation_id: int) -> dict:
        return self._cached_get(
            f"qf:tr:{translation_id}:{verse_key}",
            f"translations/{translation_id}/by_ayah/{verse_key}",
        )

    def get_word_by_word(self, verse_key: str) -> dict:
        return self._cached_get(
            # v2: adds text_qpc_hafs, the QF text that matches the bundled
            # UthmanicHafs font (QF font-rendering guide). New key so old cache
            # entries without the field are not reused.
            f"qf:wbw:v2:{verse_key}",
            f"verses/by_key/{verse_key}",
            {
                "words": "true",
                "fields": "text_qpc_hafs,text_uthmani",
                "word_fields": "text_qpc_hafs,text_uthmani,transliteration",
            },
        )

    def get_audio(self, verse_key: str, reciter_id: int) -> dict:
        return self._cached_get(
            f"qf:audio:{reciter_id}:{verse_key}",
            f"recitations/{reciter_id}/by_ayah/{verse_key}",
        )

    def get_reciters(self) -> list[dict]:
        """Reciters for the picker: `[{id, name, style, has_per_ayah_audio}]`.

        Merges `resources/chapter_reciters` (chapter files) with `resources/recitations`
        (per-ayah files). Hidden reciters are removed. Cached 1 week.
        """
        key = "qf:reciters:v1"
        hit = cache.get(key)
        if hit is not None:
            return hit

        chapter = self._content_get("resources/chapter_reciters")
        per_ayah = self._content_get("resources/recitations")

        merged: dict[int, dict] = {}
        for r in chapter.get("reciters") or []:
            rid = r.get("id")
            if not isinstance(rid, int):
                continue
            merged[rid] = {
                "id": rid,
                "name": _text(r.get("translated_name")) or _text(r.get("name")),
                "style": _text(r.get("style")),
                "has_per_ayah_audio": False,
            }
        for r in per_ayah.get("recitations") or []:
            rid = r.get("id")
            if not isinstance(rid, int):
                continue
            entry = merged.setdefault(
                rid,
                {
                    "id": rid,
                    "name": _text(r.get("reciter_name")),
                    "style": _text(r.get("style")),
                    "has_per_ayah_audio": False,
                },
            )
            entry["has_per_ayah_audio"] = True
            entry["name"] = entry["name"] or _text(r.get("reciter_name"))
            entry["style"] = entry["style"] or _text(r.get("style"))

        result = []
        for rid in sorted(merged):
            if rid in HIDDEN_RECITER_IDS:
                continue
            entry = merged[rid]
            if rid in RECITER_STYLE_OVERRIDES:
                entry["style"] = RECITER_STYLE_OVERRIDES[rid]
            result.append(entry)
        cache.set(key, result, timeout=self.cache_ttl)
        return result

    def get_chapter_audio(self, reciter_id: int, chapter: int, segments: bool = True) -> dict:
        """Chapter audio file plus normalised verse/word timings. Cached 1 week.

        Returns `{reciter_id, chapter, audio_url, clip_start_ms, clip_end_ms, verses,
        has_timings, provenance}`. `clip_end_ms` is the last verse's `timestamp_to`
        (QF `duration` is rounded to whole seconds). `has_timings` means at least one
        usable verse has word timings; callers check `usable` for their own verse range.
        """
        key = f"qf:chapter_audio:{_CHAPTER_AUDIO_CACHE_VERSION}:{reciter_id}:{chapter}:{int(bool(segments))}"
        hit = cache.get(key)
        if hit is not None:
            return hit

        params = {"segments": "true"} if segments else None
        raw = self._content_get(f"chapter_recitations/{reciter_id}/{chapter}", params)
        audio = raw.get("audio_file") if isinstance(raw, dict) else None
        if not isinstance(audio, dict) or not audio.get("audio_url"):
            raise QFContentError(code="qf_not_found")

        verses = normalize_timestamps(audio.get("timestamps")) if segments else []
        data = {
            "reciter_id": reciter_id,
            "chapter": chapter,
            "audio_url": audio["audio_url"],
            "clip_start_ms": verses[0]["start_ms"] if verses else None,
            "clip_end_ms": verses[-1]["end_ms"] if verses else None,
            "verses": verses,
            "has_timings": any(v["usable"] and v["words"] for v in verses),
            "provenance": {
                "provider": "quran_foundation",
                "resource_type": "chapter_recitation",
                "provider_ref": f"{reciter_id}:{chapter}",
                "retrieved_at": timezone.now().isoformat(),
                "caching_policy_ref": "qf_max_1_week",
            },
        }
        cache.set(key, data, timeout=self.cache_ttl)
        return data


_client: QuranFoundationClient | None = None


def get_client() -> QuranFoundationClient:
    """Process-level singleton accessor."""
    global _client
    if _client is None:
        _client = QuranFoundationClient()
    return _client
