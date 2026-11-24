# Tasks — Navigation and Shell Fixes

## Kiro tasks
- [x] N1 Replace `context.go` with `push` / `pushReplacement` per the design table
      (home, surah selection, reader, exercise, completion). (R1)
- [x] N2 `PopScope` in `HomeShell` (non-Home tab → Home), `ExerciseScreen` (confirm dialog),
      `LessonCompletionScreen` (→ Home), `SignInScreen` (→ onboarding). (R1)
- [x] N3 Extract reminder actions into a shared helper; add `ReminderSheet`. (R2)
- [x] N4 `HudaayahTopBar` opens the sheet; icon reflects reminder on/off. (R2)
- [x] N5 Generate `logo.png` (1x/2x/3x) from the app icon; register asset; use in the top bar. (R3)
- [x] N6 Add `webview_flutter` (version compatible with AGP 8.11 / compileSdk 36). (R4)
- [x] N7 `LegalPageScreen` + `/legal/:page` route (public), host allow-list, external links,
      loading and error states, JS disabled. (R4)
- [x] N8 Profile tiles and sign-in links open `/legal/...`; add `deleteAccountUrl`. (R4)
- [x] N9 `flutter analyze`, update the widget test for new routes, release build check. (R1–R4)

## Owner checks (on a phone)
- [~] O1 Back from reader / practice / completion / each tab behaves as in R1.
- [~] O2 Bell opens the reminder sheet; changing it there updates Profile.
- [~] O3 Logo looks sharp in the top bar.
- [~] O4 Privacy / Terms / Delete account open inside the app, signed in and signed out;
      the Quran Foundation link opens the browser; offline shows Try again.
