# Requirements — Mobile Deployment with Fastlane (Android)

Goal: build, sign and upload the Hudaayah Android app to Google Play with one command,
from the developer's Mac or from GitHub Actions, without editing version numbers by hand
and without ever committing secrets.

Out of scope: iOS / App Store, backend deployment (`.github/workflows/deploy.yml`).

Store listing: edited in Play Console until it is final, then imported once with
`fastlane supply init` and managed from git with a separate `listing` lane (R10). Release
lanes never upload the listing.

## R1 One-command release
- `fastlane internal` builds the release bundle and uploads it to Internal testing.
- `fastlane closed` does the same for the closed test track.
- `fastlane promote` moves the latest closed-test release to production, without
  rebuilding. It is only usable once Play has granted production access.
- Each lane prints the version name, build number and track it released.

## R2 Automatic build number
- The build number is the highest version code anywhere on Play plus 1, read at release
  time: every track (internal, closed, open, production) **and** the bundle library, which
  still holds builds from deleted drafts (Play never frees a used version code).
- `pubspec.yaml` is the source of the **version name** only (e.g. `1.0.1`). The `+N`
  in `pubspec.yaml` is ignored by releases.
- A release never reuses or lowers a build number.

## R3 Correct release build
- Built with `flutter build appbundle --release --dart-define-from-file=dart_defines/prod.json`.
- Signed with the upload key from `android/key.properties`. The lane verifies the bundle's
  signing SHA-1 equals the expected upload key SHA-1 before uploading, and stops if not.
- The build fails (no upload) if `prod.json` is missing or its `API_BASE_URL` is not HTTPS.

## R4 Release notes
- Notes come from `fastlane/metadata/android/en-US/changelogs/<build number>.txt`, falling
  back to `default.txt`. Max 500 characters (Play limit); the lane fails if longer.
- Release lanes (`internal`, `closed`, `promote`) upload only release notes. Store listing
  text, images and screenshots are handled only by the `listing` lane (R10).

## R5 Release status
- Default: the release is uploaded and rolled out to the track (`completed`).
- Optional `draft:true` uploads it as a draft to review in Play Console first.
- `promote` can run from either place, and always requires an explicit confirmation:
  - **Mac:** `fastlane promote` shows the version and build and asks for confirmation.
  - **GitHub:** manual dispatch with `lane: promote`, in the `play-production`
    environment, which waits for the owner's approval as required reviewer.
- The service account gets "Release to production" only when the owner is ready to
  promote; until then `promote` fails with a permission error and changes nothing.

## R6 Secrets
- Never committed: Play service account JSON key, upload keystore, `key.properties`,
  `dart_defines/prod.json`.
- In CI they come from GitHub Secrets, are written to the runner's temp directory, and
  are removed at the end of the job. They are never printed to logs.
- The Play service account has the least permissions needed: release to testing tracks
  for `internal`/`closed`; production release only if `promote` is used.

## R7 CI release on merge to main
- `develop` is the working branch; `main` is only updated to deploy.
- Every push/merge to `main` that changes `mobile/**` (or the workflow) runs
  `fastlane closed` in GitHub Actions, so testers get each deployment.
- Listing-only changes (`fastlane/metadata/*/*.txt`, `images/`) and `.md` files do not
  trigger a build; the listing is published with the manual `listing` lane.
- No tag trigger (it would release the same commit twice).
- `workflow_dispatch` allows running `internal`, `closed` or `promote` manually.
- `promote` runs only in a GitHub environment that requires the owner's approval.
- Flutter and Java versions in CI match the local toolchain (Flutter 3.41.x, Java 17).

## R8 Local use
- Works on the owner's Mac with Homebrew-installed or Bundler-managed fastlane.
- A short README explains first-time setup and the three lanes.

## R10 Store listing from git
- **Import (once, by the owner):** when the listing is final in Play Console, run
  `fastlane supply init` in `mobile/android` to download title, short and full
  description, icon, feature graphic and screenshots into `fastlane/metadata/android/`,
  then commit them.
- **Source of truth after import:** the files in git. Listing edits are made in those
  files, not in Play Console (console edits would be overwritten by the next `listing` run).
- **`fastlane listing`** uploads only the listing (text, images, screenshots); never an
  app bundle or release notes. It runs only when asked, never as part of a release.
- **Guard:** `listing` refuses to run unless the import has happened (required files exist
  for `en-US`: `title.txt`, `short_description.txt`, `full_description.txt`) and Play's
  limits are met (title ≤ 30, short description ≤ 80, full description ≤ 4000 characters).
- **Validate first:** `fastlane listing validate:true` checks the listing with Play
  without publishing it.
- **CI:** `listing` is available from manual dispatch only, in the `play-testing`
  environment. It never runs automatically on merge to main.
- Committed listing files contain no personal data (screenshots without personal emails
  or copyrighted avatars).

## R9 Owner-only setup (not code)
Create the Google Cloud service account and JSON key; invite it in Play Console with
release permissions; add GitHub Secrets; create the protected `play-production`
environment.
