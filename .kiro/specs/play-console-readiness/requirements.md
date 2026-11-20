# Requirements — Play Console Readiness (Android)

Goal: produce a signed release App Bundle that can be uploaded to a Google Play
closed/internal test track and works for testers.

## R1 Release signing
- Release builds are signed with an upload keystore, never the debug key.
- Keystore and `key.properties` are never committed. Build fails clearly if absent.

## R2 Release network access
- Release manifest declares `INTERNET`.
- Release builds allow HTTPS only (no cleartext). Debug cleartext config stays debug-only.

## R3 Release configuration
- Release is built with `--dart-define-from-file=dart_defines/prod.json`.
- A release build must not silently fall back to the `http://10.0.2.2` default API URL.

## R4 App identity
- App label is "Hudaayah". `pubspec` description is meaningful.
- Launcher icon (including adaptive icon) replaces the Flutter default.
- Application ID is confirmed by the owner before first upload (permanent).

## R5 Legal links
- Privacy Policy and Terms of Use open in an external browser from Profile and Sign-in.
- URLs come from `AppConfig`, set via dart-define.

## R6 Sign-in surface
- Disabled "Apple (coming soon)" button is hidden on Android release builds.

## R7 Quran font
- Licensed KFGQPC Uthmanic Hafs font is bundled and registered, with attribution.

## R8 Versioning
- Each upload increments the build number (`+N` in `pubspec.yaml`).

## R9 Owner-only items (out of code scope)
Tracked in tasks.md under "Owner tasks": Play account, Play App Signing SHA-1 in Google
Cloud, store listing, data safety, content rating, tester setup, hosted legal pages,
backend production verification.
