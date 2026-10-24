---
name: qf-content-adapter
description: How to implement and use the Quran Foundation Content API adapter in the Django backend — OAuth2 client_credentials, token caching, required headers, pre-live vs production, caching limits. Use when writing or reviewing any code that fetches Quran content.
---

# Quran Foundation Content Adapter

All QF access flows through a single adapter in `apps/quran_content/`. No other module
calls QF directly.

## Auth flow (client_credentials, no refresh token)
1. `POST {AUTH_BASE}/oauth2/token` with HTTP Basic (`client_id:client_secret`),
   body `grant_type=client_credentials&scope=content`, header
   `Content-Type: application/x-www-form-urlencoded`.
2. Response has `access_token` + `expires_in` (~3600s). Cache it.
3. Re-request a new token shortly before expiry. There is NO refresh token.

## Content requests
`GET {API_BASE}/content/api/v4/<resource>` with BOTH headers:
- `x-auth-token: <access_token>`
- `x-client-id: <client_id>`

## Environments
- Pre-live: AUTH `https://prelive-oauth2.quran.foundation`,
  API `https://apis-prelive.quran.foundation`. Contains only surah 1 and 2.
- Production: AUTH `https://oauth2.quran.foundation`,
  API `https://apis.quran.foundation`. Requires approval.
- Never mix pre-live and production credentials/hosts/tokens.

## Error handling
- 400/422: fix params/headers; do not retry unchanged.
- 401: clear cached token, re-request once, retry once.
- 403: check client id, environment, scope=content, approved permissions; do not loop.
- 429: respect rate limits; bounded exponential backoff + jitter.
- 5xx: bounded backoff, then surface a clean error.
Never leak provider errors or secrets to the client. Use a stable internal error code.

## Caching
Cache responses at most 1 week. For durable/offline copies, use Content Sync APIs only
(deferred post-MVP). Do not build an offline mirror from normal responses.

## Reference adapter interface (map to real v4 resources)
```python
class QuranFoundationClient:
    def get_chapter(self, chapter_id: int): ...
    def get_verses(self, chapter_id: int, page: int = 1): ...
    def get_translation(self, verse_key: str, translation_id: int): ...
    def get_word_by_word(self, verse_key: str): ...
    def get_audio(self, verse_key: str, reciter_id: int): ...
```

## Secrets
`QF_CLIENT_ID`, `QF_CLIENT_SECRET`, `QF_ENV` from backend env/secret manager only.
Never in Flutter, logs, or committed files.

## SDK note
QF has an official Python SDK (`quran-foundation-api`) and JS/TS SDK (`@quranjs/api`),
but NO official MCP server. For the MVP a thin raw-HTTP adapter is preferred for control
and minimal dependencies; the Python SDK is an acceptable alternative.
