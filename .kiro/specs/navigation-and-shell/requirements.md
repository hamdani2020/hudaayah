# Requirements — Navigation and Shell Fixes

Release: 1.1.0. Fixes tester bugs 3, 4, 6 and 7.

## R1 Phone back button returns to the previous screen (bug 4)
- Opening a lesson in the reader, its practice, or a full-screen flow puts it **on top**
  of the current screen. The back button (and the app-bar back arrow) returns to the
  screen it was opened from.
- On the Read, Learn or Profile tab, back switches to the **Home** tab.
- On the Home tab, back closes the app (Android default).
- During practice, back asks: "Leave this lesson? Your answers so far won't be saved."
  with **Keep practising** / **Leave**. Leave returns to the screen practice was opened from.
- After a lesson is completed, back from the completion screen goes to Home (it never
  returns to the finished exercise).
- On the sign-in screen, back returns to onboarding.

## R2 Bell icon opens the daily reminder (bug 6)
- Tapping the bell on any tab's top bar opens a bottom sheet with the Daily Reminder
  switch and time, using the same setting as the Profile row (one source of truth).
- The bell shows a filled/active icon when the reminder is on, outlined when off.
- Permission handling and messages are the same as on the Profile screen.

## R3 Hudaayah logo in the top bar (bug 7)
- The top bar shows the Hudaayah app icon (the "هى" logo) instead of the typed "هد" text.
- Crisp on all screen densities; accessible label "Hudaayah".

## R4 Privacy Policy and Terms open inside the app (bug 3)
- Privacy Policy, Terms of Use and Delete account pages open in an **in-app screen**
  (WebView) with the Hudaayah app bar, a title and a back arrow. The user never leaves
  the app.
- Content is still served by Django at `privacy.hudaayah.xyz` (no copy in the app).
- Opened from Profile and from the sign-in screen (works when signed out).
- Shows a loading indicator, and a gentle error with **Try again** when offline.
- Only pages on `privacy.hudaayah.xyz` load inside the screen. Any other link (e.g.
  `quran.foundation`, `mailto:`) opens outside the app with the system handler.
- JavaScript is disabled (the pages do not need it).
