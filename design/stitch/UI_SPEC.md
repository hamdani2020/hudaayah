# Hudaayah UI Spec — pulled from Google Stitch (2026-10-26)

Source of truth: the raw Stitch HTML exports in `design/stitch/html/`. This file
summarizes the shared design system that every screen uses. When rebuilding the
Flutter UI, match the HTML exactly (layout, spacing, colors, typography, radii).

Stitch project: "Hudaayah Quran Learning App" (projects/8483347196154126326).
All screens are MOBILE, 390–420px logical width, light mode.

## Screens (file → route/feature)
1. `01-welcome-onboarding.html`   → onboarding (UPDATED 2026-10-26): minimal image-centric
   Welcome. Centered "Hudaayah" wordmark (headline-md), a large hero illustration
   (~50% of height, radial-gradient feathered mask, ambient bloom behind), headline
   "Your journey with the Quran." + subtitle "Build a beautiful daily habit, one verse
   at a time.", a full-width pill "Get started" button (h-14, rounded-full,
   primary-container bg, trailing arrow_forward), and a "Already have an account? Sign in"
   text link. Screen bg is a soft vertical gradient #fbfaf7 → #f4f8f6. Hero art asset:
   `design/stitch/screenshots/onboarding-hero.jpg` (open Quran on a carved wooden rehal,
   golden light, emerald/cream ribbons). The earlier card-carousel onboarding was deleted
   in Stitch and must NOT be used.
2. `02-signin-authentication.html`→ authentication (Google + Apple only, privacy card)
3. `03-surah-verse-selection.html`→ learning_path / surah selection (bottom nav: Read)
4. `04-home-dashboard.html`       → home dashboard (bottom nav: Home)
5. `05-quiz-exercise.html`        → exercises (MCQ with feedback drawer, +XP)
6. `06-quran-reader.html`         → quran_reader (audio strip, ayah cards, floating controls)
7. `07-lesson-completion.html`    → lesson completion / progress celebration
8. `08-profile-history.html`      → profile (bottom nav: Profile)

## Color tokens (hex) — use these exact values
- primary:                 #002721
- primary-container:       #0f3e36
- on-primary:              #ffffff
- on-primary-container:    #7ca99e
- primary-fixed:           #bdece0
- primary-fixed-dim:       #a2d0c4
- on-primary-fixed:        #00201b
- on-primary-fixed-variant:#224e46
- secondary:               #904d00   (NOTE: the onboarding/signin configs use secondary=#fe932c as the warm amber; the shared M3 config uses secondary=#904d00 with secondary-container=#fe932c. Treat the warm amber #fe932c as the accent color and #904d00 as its dark text variant.)
- secondary-container:     #fe932c   (warm amber accent)
- secondary-fixed:         #ffdcc3
- secondary-fixed-dim:     #ffb77d
- on-secondary-fixed:      #2f1500
- on-secondary-fixed-variant:#6e3900
- secondary-dark:          #904d00
- tertiary:                #00281a
- tertiary-container:      #00402d
- tertiary-fixed:          #80f9c8
- tertiary-fixed-dim:      #62dcad
- on-tertiary-container:   #34b488
- surface / background:    #effcf9
- surface-bright:          #effcf9
- surface-container-lowest:#ffffff
- surface-container-low:   #e9f7f3
- surface-container:       #e3f1ed
- surface-container-high:  #ddebe8
- surface-container-highest:#d8e5e2
- surface-variant:         #d8e5e2
- surface-dim:             #cfddd9
- surface-card-border:     #d0e7e1
- on-surface:              #121e1c
- on-surface-variant:      #404846
- outline:                 #717976
- outline-variant:         #c0c8c5
- inverse-surface:         #273331
- inverse-on-surface:      #e6f4f0
- inverse-primary:         #a2d0c4
- error:                   #ba1a1a
- error-container:         #ffdad6
- on-error:                #ffffff
- on-error-container:      #93000a

## Typography (families + scale)
Fonts (Google Fonts):
- Body / UI / labels:  "Plus Jakarta Sans" (400,500,600,700)
- Headlines / display / transliteration (serif): "Newsreader"
- Arabic ayah text:    "Noto Serif" in the M3 screens; onboarding uses "Amiri".
  For the real app, use the bundled KFGQPC Uthmanic Hafs font for Quran Arabic
  (per tech steering) and never auto-translate Arabic. Noto/Amiri are Stitch
  placeholders for the sacred Arabic style.

Type scale (name → size / line-height / weight / tracking):
- display-lg:        36 / 44 / 600 / -0.02em  (Newsreader)
- display-lg-mobile: 28 / 36 / 600 / -0.01em  (Newsreader)
- headline-md:       24 / 32 / 500 / -0.01em  (Newsreader)
- headline-sm:       18 / 24 / 600 / —         (Plus Jakarta Sans)
- transliteration-md:15 / 24 / 400 / 0.01em    (Newsreader, italic)
- body-lg:           16 / 26 / 400             (Plus Jakarta Sans)
- body-md:           14 / 22 / 400             (Plus Jakarta Sans)
- label-md:          12 / 16 / 600 / 0.04em    (Plus Jakarta Sans)
- label-sm:          11 / 14 / 500 / 0.02em    (Plus Jakarta Sans)
- arabic-ayah-lg:    30 / 68 / 500             (Noto Serif / Uthmanic)
- arabic-ayah-sm:    24 / 54 / 500             (Noto Serif / Uthmanic)

## Shape / radii
- Card / surface containers: rounded-xl = 12px
- Buttons: rounded-lg = 8px (primary CTAs), rounded-xl on option cards
- Pills / chips / avatars: rounded-full = 9999px
- Icon tiles: rounded-lg / rounded-xl (8–12px)
- borderRadius tokens: DEFAULT 4, lg 8, xl 12, full 9999

## Spacing tokens
- space-xs 4, space-sm 8, space-md 16, space-lg 24, space-xl 36
- margin (screen horizontal padding) = 20px (1.25rem)
- gutter 16

## Shared structural patterns
- App background: surface #effcf9.
- Fixed top header (h-14/h-16), surface/90 + backdrop blur, subtle shadow.
- Bottom nav (home/read/learn/profile) on the 3 tabbed screens: fixed, surface/95
  + backdrop blur, top border outline-variant/20, 4 items with Material Symbols
  icons (explore=Home, menu_book=Read, school=Learn, person=Profile), active item
  text-primary + font-semibold.
- Cards: bg surface-container-lowest (#fff), rounded-xl, soft shadow (shadow-sm),
  often a 1px border surface-card-border on the onboarding screen.
- Primary CTA button: bg primary (#002721) or primary-container (#0f3e36),
  text on-primary (#fff), min-height 52, rounded-lg, with trailing arrow_forward
  in a translucent circle.
- Chips/badges: rounded-full, small label-sm text, tonal backgrounds
  (primary-fixed, secondary-fixed, surface-container-high).
- Icons: Google Material Symbols Outlined; some filled via FILL axis.
- Warm amber (#fe932c / secondary-container) is the single accent used sparingly
  for streaks, highlights, "today", correct answers.

## Adab / content rules (keep, per steering)
- Arabic rendered RTL with full diacritics; never auto-translated.
- Translation/transliteration always visually distinct from the Arabic ayah.
- Gentle encouragement language (e.g. "Mā shā' Allāh! Correct", "Alhamdulillah!"),
  never "you failed".
- Visible "Quran content provided by Quran Foundation" attribution on content screens.
- Quran verse text is fetched from the backend (QF) at runtime, NOT hardcoded.
  The Arabic shown in these HTML mocks is placeholder; the Flutter widgets must
  render verse text supplied by the backend/repository layer.
