# Tasks — Mobile Deployment with Fastlane (Android)

## Kiro tasks (code and config)
- [ ] F1 Add `mobile/android/Gemfile` pinning fastlane; generate `Gemfile.lock`. (R8)
- [ ] F2 Add `fastlane/Appfile` (package name, JSON key from `PLAY_JSON_KEY_PATH`). (R1, R6)
- [ ] F3 Fastfile preflight: `prod.json` present and HTTPS, `key.properties` complete,
      version name read from `pubspec.yaml`. (R3)
- [ ] F4 Fastfile build-number helper: max version code across all tracks + 1. (R2)
- [ ] F5 Fastfile build + signature check against `UPLOAD_KEY_SHA1`. (R3)
- [ ] F6 Release notes: `changelogs/<N>.txt` with `default.txt` fallback, 500-char check;
      add `default.txt`. (R4)
- [ ] F7 Lanes `internal` and `closed` with `draft` option; upload only AAB + changelog. (R1, R5)
- [ ] F8 Lane `promote` (closed → production) with confirmation. (R1, R5)
- [ ] F9 `.gitignore`: fastlane reports, temp changelogs, JSON keys. (R6)
- [ ] F10 `.github/workflows/mobile-release.yml`: tag + manual triggers, tag/version check,
      secrets to temp files, cleanup, environments `play-testing` / `play-production`. (R6, R7)
- [ ] F11 `mobile/android/fastlane/README.md`: setup, secrets list, lanes, listing import
      steps, troubleshooting. (R8, R10)
- [ ] F14 Lane `listing` with import guard, character limits and `validate` option;
      add it to the CI manual dispatch (no tag trigger, no build/keystore steps). (R10)
- [ ] F12 Verify locally: `bundle exec fastlane closed draft:true` creates a draft release
      with the next build number; delete the draft afterwards. (R1–R5)
- [ ] F13 Verify CI: manual dispatch `internal` with `draft: true` succeeds; logs show no
      secret values. (R6, R7)

## Owner tasks
- [x] O1 Google Cloud: create service account `hudaayah-play-release`, create a JSON key,
      store it outside the repo (e.g. `~/keys/hudaayah-play.json`).
- [x] O2 Play Console → Users and permissions → invite the service account email; grant
      app access to Hudaayah with "Release to testing tracks" (and "Release to production"
      only when you want `promote`).
- [ ] O3 Confirm the closed track's API id (default `alpha`): after the first closed release
      is saved, `google_play_track_version_codes ... track:alpha` returns `[2]`.
- [ ] O4 GitHub → Settings → Environments: create `play-testing` and `play-production`
      (required reviewer: you). Add secrets to each:
      `PLAY_SERVICE_ACCOUNT_JSON`, `ANDROID_UPLOAD_KEYSTORE_BASE64`
      (`base64 -i ~/keys/hudaayah-upload.jks`), `ANDROID_KEYSTORE_PASSWORD`,
      `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS` (`upload`), `DART_DEFINES_PROD_JSON`.
- [x] O5 Install fastlane locally: `brew install fastlane` or `gem install bundler` then
      `bundle install` in `mobile/android`.
- [ ] O6 When the listing is final in Play Console: run `bundle exec fastlane supply init`
      in `mobile/android`, check the downloaded files (no personal data in screenshots),
      commit them, then run `fastlane listing validate:true` once to confirm. From then on,
      edit the listing in git only.
