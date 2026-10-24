# Product Steering — Hudaayah

## What Hudaayah is
A Duolingo-style, **Quran-only** learning app that helps Muslims build a consistent
daily habit of engaging with the Quran through short, interactive lessons.

Core principle (do not violate):
> **Quran Foundation provides the Quran content; Hudaayah provides the learning experience.**

The competitive advantage is the quality of curriculum, exercises, memorization,
spaced repetition, and UX — NOT owning a Quran database.

## Audience
All Muslims who want to make Quran learning a daily habit. Mixed Arabic literacy:
support both meaning-focused learners and memorization-focused learners.

## MVP scope (pilot)
- One surah: **Al-Fatihah** (7 ayahs), end-to-end learning loop.
- Three exercise types only: `multiple_choice`, `word_order`, `listening_recall`.
- Google + Apple Sign-In.
- Server-side grading, XP, streak, daily goal.
- Vocabulary spaced-repetition reviews active at pilot (ayah-recall review modeled but
  not required in pilot UI).
- Online-first. No offline sync in MVP.

## Explicitly out of scope for MVP
Hadith, tafsir, Seerah, Fiqh, Aqeedah, AI tutor, speech/Tajweed scoring, social
features, leaderboards, teacher/classroom, family dashboards, offline downloads,
multiple learning paths, levels/badges beyond XP+streak.

## Success metric that matters
Day-1 → Day-2 → Day-7 learner return rate. Everything else is secondary at pilot.

## Monetization
Free for now. Donations/subscriptions are allowed later under QF terms (no selling or
redistributing QF content or raw API data as data).

## Tone and adab (respect) rules
- Never frame Quran recall failures as "you failed." Use gentle, encouraging language.
- Never display gamification that implies religious superiority between users.
- Never fragment or rearrange ayah text in a way that alters or misrepresents meaning.
- Always visibly credit Quran Foundation.
- Keep original educational content clearly separated from Quran source text and translation.
