# Releasing the Android app (fastlane)

Spec: `.kiro/specs/mobile-fastlane-deploy/`. Files: `mobile/android/fastlane/`,
`.github/workflows/mobile-release.yml`.

## What each command does

Run from `mobile/android` (Homebrew `fastlane …` or `bundle exec fastlane …`).

| Command | What happens |
| --- | --- |
| `fastlane check` | Preflight checks and shows the next build number. Builds and uploads nothing. |
| `fastlane closed` | Builds, verifies the signature, uploads to the closed test (`alpha`) and rolls it out. |
| `fastlane closed draft:true` | Same, but leaves the release as a draft to review in Play Console. |
| `fastlane internal` | Same as `closed`, for Internal testing. |
| `fastlane promote` | Moves the latest closed-test build to production. Asks first. No rebuild. |
| `fastlane listing validate:true` | Checks the store listing in git with Play, publishes nothing. |
| `fastlane listing` | Uploads the store listing (text, icon, feature graphic, screenshots) from git. |

## Before each release

1. **Version name** (what users see): edit `version:` in `mobile/pubspec.yaml`.
   - Bug fixes: `1.0.1` → `1.0.2`. New features: `1.0.2` → `1.1.0`.
   - The `+N` part is ignored. The build number is set automatically to the highest build
     on Play + 1.
2. **Release notes (required):** add an entry for the new version at the top of
   `mobile/assets/changelog.json` (`version`, `new`, `fixed`). It is the single source:
   - the app shows it in "What's new" (once after updating, and in Profile → What's new);
   - fastlane turns it into the Play "What's new" text. If the full list is over Play's
     500-character limit, Play gets the new items plus "And N fixes. See What's new in
     the app."
   The release stops if the version has no entry. `fastlane check` prints the Play text.
   For a one-off Play text, a hand-written
   `fastlane/metadata/android/en-US/changelogs/<build number>.txt` overrides it.
3. Commit.

## Releasing

- **Automatic (normal way):** merge `develop` into `main`. If the merge changes the app
  (`mobile/**`), GitHub runs `fastlane closed` and testers get the new build.
  Listing-only and `.md`-only changes do not trigger a build.
- **From your Mac:** `cd mobile/android && fastlane closed`
- **Any lane from GitHub:** Actions → *Release Android app* → *Run workflow* → choose the lane.

Remember to bump `version:` in `pubspec.yaml` on `develop` before merging, so testers see
a new version name. (If you forget, the release still works: the build number always
goes up, only the visible version name stays the same.)

## Promoting to production

Only after Play grants production access, and after giving the service account
**Release to production** in Play Console → Users and permissions.

- **Mac:** `fastlane promote` (shows the build and asks for confirmation).
- **GitHub:** Run workflow → `promote`. It waits for your approval in the `play-production`
  environment.

## Store listing

Git is the source of truth for the listing. Edit the files in
`mobile/android/fastlane/metadata/android/en-US/` (not in Play Console), then:

```bash
fastlane listing validate:true   # check
fastlane listing                 # publish
```

Limits: title 30, short description 80, full description 4000 characters. Uploading
screenshots replaces the whole set on Play, so keep every screenshot in the folder.
To re-import from Play Console: `fastlane supply init` (overwrites the local files).

## First-time setup (already done once)

- Service account key at `~/keys/hudaayah-play.json`, invited in Play Console.
- Upload keystore and `mobile/android/key.properties`.
- `mobile/dart_defines/prod.json` with an `https://` `API_BASE_URL`.
- GitHub environments `play-testing` and `play-production` with these secrets:
  `PLAY_SERVICE_ACCOUNT_JSON`, `ANDROID_UPLOAD_KEYSTORE_BASE64`,
  `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`,
  `DART_DEFINES_PROD_JSON`.

## Troubleshooting

| Message | Fix |
| --- | --- |
| `insufficient authentication scopes` | fastlane did not find the key. Check `~/keys/hudaayah-play.json` exists, or set `PLAY_JSON_KEY_PATH`. |
| `The caller does not have permission` | Missing permission for the service account in Play Console → Users and permissions. |
| `Bundle is signed with …, expected the upload key` | `key.properties` points to the wrong keystore. Nothing was uploaded. |
| `Version code N has already been used` | Should not happen: the lookup includes deleted drafts. If it does, another upload happened at the same moment, or the bundle library could not be read (look for "Could not read Play's bundle library" in the log). Run again. |
| `No release notes for X.Y.Z` | Add an entry for that version to `mobile/assets/changelog.json`. |
| Release notes too long | Shorten the "new" items in `changelog.json` (Play limit 500 characters). |

Passwords in `key.properties` must not contain a backslash (`\`), because Java reads it
as an escape character.
