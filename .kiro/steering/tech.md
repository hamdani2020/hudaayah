# Tech Steering — Hudaayah

## Stack (agreed)
- Mobile: Flutter + Dart (Flutter 3.41.x, Dart 3.11.x). Riverpod (state), GoRouter
  (navigation), Dio (HTTP).
- Backend: Django + Django REST Framework. API prefix `/api/v1/`.
- Database: PostgreSQL.
- Auth: Google Sign-In + Apple Sign-In. Django-managed application session.
- Quran source: Quran Foundation Content API, accessed only from Django.
- Architecture: modular monolith. No microservices/Kubernetes for MVP.
- CI/CD: GitHub Actions. Background jobs (Celery/Redis) only when a real need arises.

## Non-negotiable integration rules (from QF Developer Terms + quickstart)
- QF `client_secret` is **backend-only**. Never ship it in the Flutter bundle.
- Content API auth = OAuth2 **client_credentials**, `scope=content`. No refresh token.
- Access token lifetime ~3600s. Cache it; re-request before expiry; on HTTP 401 clear
  token, re-request once, retry once.
- Every content request sends headers `x-auth-token` and `x-client-id`.
- Pre-live base URLs: auth `https://prelive-oauth2.quran.foundation`,
  API `https://apis-prelive.quran.foundation`, content path `/content/api/v4/...`.
- Pre-live contains ONLY surah 1 (Al-Fatihah) and surah 2 (Al-Baqarah). Perfect for MVP.
- Production (`apis.quran.foundation` / `oauth2.quran.foundation`) needs separate
  approval; only required when expanding beyond Al-Baqarah.
- Never mix pre-live and production credentials/hosts/tokens.
- Cache QF content **at most 1 week**. Durable offline requires Content Sync APIs
  (deferred post-MVP), not a homegrown mirror.
- Fonts and Mushaf images MAY be bundled in the app (with attribution + active
  Developer Console account).
- Do NOT use QF content to train/fine-tune ML models. RAG retrieval is distinct but
  stored embeddings that reconstruct content still count as stored QF content.
- TLS 1.2+, encryption at rest, least-privilege, secret rotation.
- Report suspected breaches to QF within 24 hours.

## Backend conventions
- Settings split: `config/settings/{base,development,production}.py`.
- All QF access goes through a single `QuranFoundationClient` adapter in
  `apps/quran_content/`. No other module calls QF directly.
- Server is the source of truth for grading, XP, streak, completion.
- Use DB transactions for lesson completion + reward updates. Make rewards idempotent.
- Enforce object-level ownership on every user-owned endpoint.
- Never log tokens, secrets, or raw provider errors. Use stable error codes + request IDs.

## Mobile conventions
- Feature-first folders under `lib/features/`. API calls behind repositories/services.
- Widgets stay presentational; no progression/scoring logic in widgets.
- Store session tokens in platform-secure storage.
- Arabic text: RTL, correct diacritics, bundled Quran font (e.g. KFGQPC Uthmanic Hafs).
  Never auto-translate Quran Arabic.

## Local toolchain (verified 2026-10-24)
Python 3.13.7, pip 25.2, Flutter 3.41.9, Dart 3.11.5, Node 24.11.1, git 2.50.1.
Django is not yet installed — pin it in backend/requirements and use a venv.
