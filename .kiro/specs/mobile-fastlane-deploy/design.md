# Design — Mobile Deployment with Fastlane (Android)

## Overview

```
developer / merge to main
        │
        ▼
fastlane <lane>            (mobile/android/fastlane/Fastfile)
  1. preflight             prod.json present + HTTPS, key.properties present, notes ≤ 500
  2. next build number     max(version codes on all Play tracks) + 1
  3. flutter build         appbundle --release --build-number=N (version name from pubspec)
  4. verify signature      bundle SHA-1 == UPLOAD_KEY_SHA1
  5. upload_to_play_store  track, aab, changelog N, release_status
        │
        ▼
Google Play (internal / closed / production)
```

## Files

| Path | Purpose |
| --- | --- |
| `mobile/android/Gemfile` (+ `Gemfile.lock`) | Pins fastlane for local and CI use. |
| `mobile/android/fastlane/Appfile` | `package_name("foundation.hudaayah.hudaayah")`, `json_key_file(ENV["PLAY_JSON_KEY_PATH"])`. |
| `mobile/android/fastlane/Fastfile` | Lanes `internal`, `closed`, `promote` and private helper lanes. |
| `mobile/android/fastlane/metadata/android/en-US/changelogs/default.txt` | Fallback release notes. |
| `mobile/android/fastlane/README.md` | Setup and usage. |
| `.github/workflows/mobile-release.yml` | CI release on merge to main / manual dispatch. |
| `.gitignore` additions | `mobile/android/fastlane/report.xml`, `README` auto-gen output, `*.json` key files, `fastlane/play-key.json`. |

## Configuration (environment variables)

| Variable | Default | Used for |
| --- | --- | --- |
| `PLAY_JSON_KEY_PATH` | required | Service account JSON key path. |
| `PLAY_CLOSED_TRACK` | `alpha` | Play API id of the closed test track (default closed track is `alpha`; custom tracks use their own name). |
| `UPLOAD_KEY_SHA1` | `99:C7:D1:23:E0:2A:5D:1C:32:3D:DA:E7:16:04:76:26:D7:E0:D3:BC` | Signature check (public value). |
| `DART_DEFINES_FILE` | `dart_defines/prod.json` | Build config. |

## Lanes

### `internal` / `closed` (shared private lane `release_to(track:, draft:)`)
1. **Preflight**
   - `../dart_defines/prod.json` exists; parse JSON; `API_BASE_URL` starts with `https://`.
   - `../android/key.properties` exists and has all four keys (the Gradle guard also enforces this).
   - Read version name from `../pubspec.yaml` (`version: X.Y.Z+N` → `X.Y.Z`).
2. **Build number**: `google_play_track_version_codes` for `internal`, `PLAY_CLOSED_TRACK`,
   `beta`, `production`; ignore tracks that do not exist; `N = max(all) + 1`
   (`1` if none).
3. **Release notes**: `changelogs/N.txt`, else copy `default.txt` to `N.txt` for this run
   (temporary, not committed). Fail if > 500 characters.
4. **Build**: from `mobile/`:
   `flutter build appbundle --release --dart-define-from-file=$DART_DEFINES_FILE --build-number=N --build-name=X.Y.Z`.
5. **Verify**: `keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab`;
   compare SHA-1 with `UPLOAD_KEY_SHA1` (case/colon-insensitive). Mismatch → `UI.user_error!`.
6. **Upload**: `upload_to_play_store(track:, aab:, version_code: N, release_status: draft ? "draft" : "completed",
   skip_upload_metadata: true, skip_upload_images: true, skip_upload_screenshots: true,
   skip_upload_changelogs: false, metadata_path: "fastlane/metadata/android")`.
7. Print summary: `Released X.Y.Z (N) to <track> [draft]`.

### `promote`
- Read latest version code on `PLAY_CLOSED_TRACK`.
- Locally: `UI.confirm("Promote X.Y.Z (N) to production?")`; in CI the protected
  environment is the confirmation (`FL_PROMOTE_CONFIRMED=1`).
- `upload_to_play_store(track: PLAY_CLOSED_TRACK, track_promote_to: "production",
  version_code: N, skip_upload_aab/apk/metadata/images/screenshots: true,
  release_status: "completed")`.

### `listing` (store listing from git, R10)
Prerequisite (owner, once): listing finished in Play Console, then
`bundle exec fastlane supply init` in `mobile/android` (uses `Appfile` key + package)
downloads into `fastlane/metadata/android/<locale>/`:
`title.txt`, `short_description.txt`, `full_description.txt`, `video.txt`,
`images/icon.png`, `images/featureGraphic.png`, `images/phoneScreenshots/*`,
plus existing `changelogs/`. Commit the result.

Lane steps:
1. **Guard**: for `en-US`, the three text files exist and are non-empty; otherwise
   `UI.user_error!("Run 'fastlane supply init' after the listing is final in Play Console.")`.
2. **Limits**: title ≤ 30, short description ≤ 80, full description ≤ 4000 characters.
3. **Upload**: `upload_to_play_store(skip_upload_aab: true, skip_upload_apk: true,
   skip_upload_changelogs: true, skip_upload_metadata: false, skip_upload_images: false,
   skip_upload_screenshots: false, validate_only: validate, metadata_path: "fastlane/metadata/android")`.
4. Print which locales and assets were uploaded (or validated).

Note: uploading screenshots replaces the existing set of that type in Play, so the git
folder must always hold the full set.

## CI workflow (`mobile-release.yml`)

Triggers: `push` to `main` with paths `mobile/**` (minus listing files and `.md`); `workflow_dispatch` with input `lane`
(`internal|closed|promote|listing`), `draft` (bool, release lanes) and `validate`
(bool, `listing`). `listing` skips the Flutter build steps and the keystore secrets.

Job `release` (`ubuntu-latest`, `concurrency: mobile-release`, `environment:` set to
`play-production` only when lane is `promote`, otherwise `play-testing`):
1. Checkout.
2. `actions/setup-java` (Temurin 17), `subosito/flutter-action` pinned to Flutter 3.41.9.
3. `ruby/setup-ruby` with `bundler-cache: true`, `working-directory: mobile/android`.
5. Write secrets to `$RUNNER_TEMP` with `umask 077`:
   - `ANDROID_UPLOAD_KEYSTORE_BASE64` → `upload.jks`
   - `key.properties` from `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`,
     `ANDROID_KEY_ALIAS`, `storeFile=$RUNNER_TEMP/upload.jks`
   - `PLAY_SERVICE_ACCOUNT_JSON` → `play-key.json`
   - `DART_DEFINES_PROD_JSON` → `mobile/dart_defines/prod.json`
   Values are passed via `env:`, never echoed; add `::add-mask::` for derived values.
6. `flutter pub get`, then `bundle exec fastlane <lane>`.
7. `if: always()` step deletes the keystore, `key.properties`, JSON key and `prod.json`.

Secrets live at environment level (`play-testing`, `play-production`), so production
credentials are only exposed after approval.

## Decisions
- Version name stays manual in `pubspec.yaml` (it reflects the kind of change); the build
  number is automatic (it only needs to go up).
- Play is the source of truth for the build number (works from any machine, never collides).
- The store listing is managed by fastlane only after a one-time `supply init`, and only
  through the separate `listing` lane, so a code release can never overwrite listing
  edits or resubmit the listing for review.
- Merges to main go to the closed track while the 14-day test is running; production only
  via the manual, approved `promote` lane.

## Risks
- The service account must be invited in Play Console before the first run; Play can take
  up to 24h to apply new permissions.
- `PLAY_CLOSED_TRACK` must match the track's API id; a wrong id makes the build-number
  lookup skip it (it would still be safe because other tracks are included, but upload fails).
- CI runners build ~60 MB bundles; first run downloads Gradle/Flutter caches (slow).
