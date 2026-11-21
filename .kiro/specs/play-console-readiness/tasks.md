# Tasks — Play Console Readiness

## Kiro tasks (code and config)
- [x] K1 Add release signing config reading `android/key.properties`; fail if missing. (R1)
- [x] K2 Add `INTERNET` permission to main manifest; set app label to "Hudaayah". (R2, R4)
- [x] K3 Add `privacyPolicyUrl` / `termsUrl` to `AppConfig` and the dart-define files. (R5)
- [x] K4 Add `url_launcher`; wire Profile tiles and Sign-in text links. (R5)
- [x] K5 Release guard: refuse cleartext `http://` API base URL in release mode. (R3)
- [x] K6 Hide Apple button on Android. (R6)
- [x] K7 Update `pubspec` description; set up `flutter_launcher_icons` once the icon exists. (R4)
- [x] K8 Register the Quran font in `pubspec.yaml` once the file exists. (R7)
- [x] K9 Run `flutter analyze`, then build the release `.aab` and verify it is signed with
      the upload key (`keytool -printcert -jarfile`). (R1, R8)
- [x] K10 Serve `/privacy/`, `/terms/`, `/delete-account/` from Django (`apps/common`, plain
      templates, no auth, no DB) on `privacy.hudaayah.xyz` via a dedicated nginx server
      block and cert (non-fatal in deploy.sh). Pages verified locally (200, contact email
      present). Still to verify after deploy: HTTPS on the real host. (R5)
- [ ] K11 In-app account deletion (Play requirement for apps with sign-in): add
      `DELETE /api/v1/me/` that removes the user and cascades their data, plus a Profile
      "Delete account" action. The web page `/delete-account/` currently uses an email
      process and can serve as the Play "delete account URL".

## Owner tasks (cannot be done by Kiro)
### Before the first build
- [ ] O1 Generate the upload keystore (`keytool -genkey -v -keystore ~/keys/hudaayah-upload.jks
      -keyalg RSA -keysize 2048 -validity 10000 -alias upload`), back it up, and create
      `android/key.properties`.
- [ ] O2 Decide the final application ID (permanent after first upload).
- [x] O3 Provide a 1024x1024 app icon (and optional adaptive foreground/background).
- [ ] O4 Review and approve the Privacy Policy and Terms text drafted in K10 (host:
      `privacy.hudaayah.xyz`, contact: hamdanialhassangandi2020@gmail.com).
- [ ] O4a DNS: add an A record `privacy.hudaayah.xyz` -> the same Elastic IP as `api`.
- [ ] O4b Add `privacy.hudaayah.xyz` to `DJANGO_ALLOWED_HOSTS` in the SSM parameters
      (CSRF origins derive from it), then deploy.
- [x] O5 Obtain the licensed KFGQPC Uthmanic Hafs `.ttf` and place it in `assets/fonts/`.

### Google Play Console
- [ ] O6 Create/verify the developer account (identity verification, fee).
- [ ] O7 Create the app, enable Play App Signing, upload the `.aab` to Internal or Closed testing.
- [ ] O8 Copy the App signing key SHA-1 and the upload key SHA-1 into Google Cloud as
      Android OAuth clients for the package name (needed for Google Sign-In).
- [ ] O9 Store listing: descriptions, 512px icon, 1024x500 feature graphic, 2+ phone screenshots.
- [ ] O10 App content: data safety form, content rating, target audience, ads declaration,
      privacy policy URL.
- [ ] O11 Testers: create the list or Google Group, share the opt-in link. Check the current
      closed-test requirement (12 testers for 14 days on newer personal accounts).

### Backend and external
- [ ] O12 Confirm `api.hudaayah.xyz` is live over HTTPS, Google client IDs are set server-side,
      and the Al-Fatihah seed is published in production.
- [ ] O13 Test the release build on a real device (sign-in, lesson, audio) before inviting testers.
- [ ] O14 Bump the build number in `pubspec.yaml` for each new upload.
