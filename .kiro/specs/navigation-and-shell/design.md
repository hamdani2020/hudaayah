# Design — Navigation and Shell Fixes

## Cause of bug 4
Every navigation uses `context.go(...)`, which **replaces** the location, so full-screen
routes (`/reader/:id`, `/lesson/:id/practice`, `/lesson/:id/complete`) have nothing
underneath. Android back then pops the only route and the app exits. Tabs live in a
`StatefulShellRoute`, and back on a non-Home tab also exits.

## Navigation rules
| From | Action | Call |
| --- | --- | --- |
| Home card, Journey tile, Read list, Resume banner | open reader | `context.push('/reader/$id')` |
| Reader | Practice this lesson | `context.push('/lesson/$id/practice')` |
| Practice | finished | `context.pushReplacement('/lesson/$id/complete', extra: summary)` |
| Practice | exit / back | confirm dialog → `context.pop()` |
| Completion | close, Continue to Dashboard, back | `context.go('/home')` |
| Completion | Review Lesson Notes | `context.go('/home')` then `context.push('/reader/$id')` |
| Home | Review N words | `context.go('/review')` (switch tab, unchanged) |
| Reader app-bar back | | `context.canPop() ? pop() : go('/surah')` (unchanged) |

- `HomeShell` wraps its body in `PopScope(canPop: currentIndex == 0, onPopInvokedWithResult:
  ...)`; when not on Home, back calls `navigationShell.goBranch(0)`.
- `ExerciseScreen` wraps in `PopScope(canPop: false)`; back shows the confirm dialog.
- `LessonCompletionScreen` wraps in `PopScope(canPop: false)`; back → `go('/home')`.
- `SignInScreen` wraps in `PopScope(canPop: false)`; back → `go('/onboarding')`.

## Bell → reminder sheet
- New widget `ReminderSheet` (profile feature, `presentation/widgets/reminder_sheet.dart`)
  built on the existing `reminderControllerProvider`: switch + "Time" row (time picker).
- Profile's reminder logic (`_setReminderEnabled`, `_pickReminderTime`,
  `_showReminderResult`) moves into a small helper used by both Profile and the sheet,
  so messages stay identical.
- `HudaayahTopBar` becomes a `ConsumerWidget`: default `onBellTap` opens the sheet
  (`showModalBottomSheet`); icon `notifications_active` when enabled, else
  `notifications_none`. Screens no longer pass `onBellTap`.

## Logo
- Asset `assets/images/logo.png` (+ `2.0x/`, `3.0x/` variants) generated from
  `assets/icon/app_icon.png` at 40/80/120 px, registered in `pubspec.yaml`.
- Top bar: `ClipRRect(radius: radiusLg)` → `Image.asset(..., width: 40, height: 40,
  semanticLabel: 'Hudaayah')`.

## In-app legal pages
- Dependency: `webview_flutter` (pick a version compatible with AGP 8.11 / compileSdk 36;
  check before adding, as with flutter_local_notifications).
- Route `/legal/:page` (`privacy`, `terms`, `delete-account`), top-level (outside the
  shell), allowed when signed out (add to the router's public locations).
- `LegalPageScreen(page)`: app bar title (Privacy Policy / Terms of Use / Delete
  account), `WebViewController` with `JavaScriptMode.disabled`, `NavigationDelegate`:
  - `onNavigationRequest`: allow if host == `Uri.parse(AppConfig.privacyPolicyUrl).host`;
    otherwise `launchUrl(external)` and `NavigationDecision.prevent`.
  - `onProgress` / `onPageFinished` → loading bar; `onWebResourceError` (main frame) →
    error view with Try again (`controller.reload()`).
- URLs built from the existing `AppConfig.privacyPolicyUrl` / `termsUrl` (add
  `deleteAccountUrl` the same way).
- Profile tiles and the sign-in text links call `context.push('/legal/privacy')` etc.
  `openExternalLink` stays for non-legal links.

## Risks
- `PopScope` + `StatefulShellRoute` back handling must be checked on Android 14+
  predictive back (`android:enableOnBackInvokedCallback` is not set, so classic back).
- WebView adds to app size (~1–2 MB). Acceptable.
