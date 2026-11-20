# Design — Play Console Readiness

## Signing (R1)
`android/key.properties` (gitignored) holds `storeFile`, `storePassword`, `keyAlias`,
`keyPassword`. `app/build.gradle.kts` loads it and defines `signingConfigs.release`;
`buildTypes.release` uses it. If the file is missing, release tasks fail with a clear
message (no fallback to debug). Keystore lives outside the repo (e.g. `~/keys/`).

## Manifest (R2, R4)
- `src/main/AndroidManifest.xml`: add `uses-permission INTERNET`; `android:label="Hudaayah"`.
- Debug-only `network_security_config` remains in `src/debug`.
- Icons: generate with `flutter_launcher_icons` (dev dependency) from an owner-supplied
  1024px source, including adaptive foreground/background.

## Config (R3, R5)
- `AppConfig` gains `privacyPolicyUrl` and `termsUrl` from `String.fromEnvironment`.
- Add `assert`/startup check: in release mode (`kReleaseMode`) if `apiBaseUrl` starts with
  `http://`, show a fatal config error instead of calling the API.
- Add the two URL keys to `dart_defines/prod.json` and `test.json` (gitignored files).

## Legal links (R5)
Add `url_launcher`. Profile tiles and sign-in text spans open the URLs with
`LaunchMode.externalApplication`. Sign-in spans use `TapGestureRecognizer`
(disposed properly, so the text is built in a stateful widget).

## Sign-in (R6)
Hide the Apple button when `defaultTargetPlatform == TargetPlatform.android`.

## Font (R7)
Owner supplies the licensed `.ttf` to `assets/fonts/UthmanicHafs.ttf`; uncomment the
`fonts:` block in `pubspec.yaml`. Add attribution text per the font license.

## Build (R8)
`flutter build appbundle --release --dart-define-from-file=dart_defines/prod.json`
Output: `build/app/outputs/bundle/release/app-release.aab`.
