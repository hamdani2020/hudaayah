# Google Sign-In Setup (Hudaayah)

How Google authentication is wired for the Al-Fatihah MVP, and the gotchas we hit.
Apple Sign-In is deferred to task 6.1.

## How it works (flow)

```
Flutter app (google_sign_in)                 Django backend
 1. GoogleSignIn.initialize(serverClientId=WEB client id)
 2. authenticate() -> Google Credential Manager -> ID token (JWT)
 3. POST /api/v1/auth/google/ { id_token }  ───────▶ verify_google():
                                                       - signature via Google JWKS
                                                       - iss in accounts.google.com
                                                       - aud ∈ GOOGLE_CLIENT_IDS
                                                       - exp not passed
 4. ◀───── { user, access_token, refresh_token } ── issue AuthSession
 5. tokens stored in platform-secure storage; Bearer on subsequent calls
```

The backend only **verifies** the ID token — it never runs a browser OAuth flow.

## OAuth clients (Google Cloud Console → Credentials)

Project number: `351213424423`. Consent screen: **External**, currently **Testing**.

| Client type | Client ID (…suffix omitted) | Role |
|---|---|---|
| **Web application** (name "backend") | `351213424423-aeicjvu1do70e17lugh4a7r597r5bbd5` | **serverClientId** in the app **and** backend `aud` |
| **Android** | `351213424423-6cfdu4bescb2jibefiii5b2id4qfmiql` | authorizes package + SHA-1; not passed to the app |

- Android client: package `foundation.hudaayah.hudaayah`, **debug** SHA-1
  `9E:6F:3F:B5:9E:F9:BF:E7:9E:43:1E:A5:80:57:49:CB:E9:7D:5F:78`.
- Web client needs **no** JavaScript origins or redirect URIs for this use.
- Client IDs are **not secrets** (they ship in the app). Client secrets are unused.

## Where each value lives

- App `serverClientId`: `mobile/dart_defines/dev.json` → `GOOGLE_SERVER_CLIENT_ID`,
  and the default in `mobile/lib/core/config/app_config.dart`. **Must be the WEB id.**
- Backend allow-list: `.env` → `GOOGLE_CLIENT_IDS` (comma-separated). Lists **both**
  Web and Android ids so whichever `aud` the token carries is accepted.
- Backend verification: `backend/apps/accounts/providers.py` (`verify_google`).

## Running the app

Android emulator (bare run works via committed dev defaults):
```
cd mobile
flutter run
```
Explicit / overridable:
```
flutter run --dart-define-from-file=dart_defines/dev.json
```
iOS simulator needs `API_BASE_URL=http://localhost:8000/api/v1` (not 10.0.2.2).

## Local dev prerequisites

- Backend up: `docker compose up -d` (web on :8000).
- `ALLOWED_HOSTS` includes `10.0.2.2` (emulator's host alias) — set in `.env` and the
  dev settings default.
- Android debug cleartext to `10.0.2.2`/`localhost` is allowed via
  `mobile/android/app/src/debug/res/xml/network_security_config.xml` (debug source set
  only; release builds disallow cleartext).
- Emulator must be a **Google Play** image with a Google account added that is listed as
  a **Test user** on the consent screen.

## Gotchas we actually hit (in order)

1. **Error 28444 "Developer console is not set up correctly."**
   Cause: the **Android** client id was passed as `serverClientId`. Fix: use the **Web**
   client id. (SHA-1/package were correct — verified the APK signing digest matched.)
2. **HTTP 400 `DisallowedHost: '10.0.2.2:8000'`.**
   Cause: `10.0.2.2` missing from `ALLOWED_HOSTS`. Fix: add it (env + dev default).
3. `--dart-define` values are read at **build time** — a hot restart does **not** pick up
   changes. Fully stop and `flutter run` again after changing them.

## Before pilot (see spec Phase 6)

- Add all ~10 pilot testers as **Test users**, or **Publish** the consent screen
  (basic scopes `email`/`profile`/`openid` publish without Google verification).
- Add the **release** keystore SHA-1 as another Android OAuth client (or Play App Signing
  SHA-1) before a store build.
- Production uses HTTPS (no cleartext config) and its own `ALLOWED_HOSTS`.
