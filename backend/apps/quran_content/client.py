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

import requests
from django.conf import settings
from django.core.cache import cache

from apps.common.errors import AppError, UpstreamError

logger = logging.getLogger(__name__)

_TOKEN_CACHE_KEY = "qf:access_token"
_TOKEN_SKEW_SECONDS = 60  # refresh a minute before expiry
_HTTP_TIMEOUT = (5, 15)  # (connect, read) seconds


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
            f"qf:wbw:{verse_key}",
            f"verses/by_key/{verse_key}",
            {
                "words": "true",
                "fields": "text_uthmani",
                "word_fields": "text_uthmani,transliteration",
            },
        )

    def get_audio(self, verse_key: str, reciter_id: int) -> dict:
        return self._cached_get(
            f"qf:audio:{reciter_id}:{verse_key}",
            f"recitations/{reciter_id}/by_ayah/{verse_key}",
        )


_client: QuranFoundationClient | None = None


def get_client() -> QuranFoundationClient:
    """Process-level singleton accessor."""
    global _client
    if _client is None:
        _client = QuranFoundationClient()
    return _client
