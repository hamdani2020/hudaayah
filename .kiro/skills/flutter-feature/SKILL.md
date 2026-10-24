---
name: flutter-feature
description: Flutter feature conventions for the Hudaayah mobile app — Riverpod state, GoRouter navigation, Dio repositories, secure token storage, Arabic RTL rendering, and exercise widgets. Use when adding or modifying any mobile feature, screen, or widget.
---

# Flutter Feature Conventions — Hudaayah

## Structure (feature-first)
Each feature under `lib/features/<feature>/` with:
- `presentation/` widgets + screens (presentational only)
- `application/` Riverpod providers/controllers (state, side effects)
- `data/` repositories + DTOs (Dio calls live here)

Shared infra in `lib/core/` (Dio client, config, error mapping, secure storage).

## State & navigation
- Riverpod for state and DI. GoRouter for navigation. Dio for HTTP.
- No progression/scoring/XP logic in widgets — the server owns that. Widgets render
  server responses and submit user input.

## Networking
- All API calls behind repositories. Attach app access token via a Dio interceptor.
- Handle loading / timeout / offline states explicitly.
- Store session tokens in platform-secure storage (flutter_secure_storage). Never log tokens.
- Do not mark a lesson complete until the backend confirms it.
- Do not blindly retry writes that could duplicate progress/XP.

## Arabic / Quran rendering
- RTL direction, correct diacritics. Bundle a Quran font (e.g. KFGQPC Uthmanic Hafs).
- Never auto-translate the Arabic. Keep Arabic, translation, and our educational text
  visually and semantically distinct.
- Audio: ayah-level play, repeat/loop (A–B), replay — core to memorization.

## Exercise widgets (MVP: 3 types)
- `multiple_choice`: render prompt + options; submit selected option id.
- `word_order`: render shuffled tokens; submit ordered token ids.
- `listening_recall`: play audio; user reveals/attempts; submit self-marked result.
Each submits to the backend and renders server-returned correctness + gentle feedback.
Never show the answer key before submission.

## Adab
No "you failed" language on Quran recall. Encourage gently. Show QF attribution.
