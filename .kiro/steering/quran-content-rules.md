# Quran Content Rules — Hudaayah (CRITICAL)

This file encodes hard rules for handling Quran Foundation (QF) content and sacred text.
Treat every rule here as a guardrail, not a guideline.

## Source of truth
- Quran Arabic text, translations, word-by-word, and audio come from QF at runtime.
- Do NOT hardcode Quran verse text into source or seed files. Seed files reference QF
  resources by stable IDs; the text is fetched through the backend adapter.
- Do NOT invent, alter, paraphrase, or "correct" any Quran verse, translation, or
  transliteration. The Quran text must not be modified in any way.

## QF Developer Terms compliance (verified 2026-10-11 terms)
- Cache QF content at most 1 week. For durable/offline copies use Content Sync APIs only.
- `client_secret` backend-only; never in the mobile bundle.
- Do not sell, sublicense, or redistribute QF content or raw API data as data.
- Do not use QF content to train or fine-tune ML models (no written consent).
- Credit Quran Foundation accessibly in the app.
- Publish a Privacy Policy + Terms of Use before launch.
- Report suspected breaches to QF within 24 hours.

## Provenance (every externally sourced item)
Track: provider, resource_type, stable provider ID, language/translation/reciter ID,
version/sync metadata, attribution text, storage/caching policy reference, retrieved_at.

## Content separation (never blur these layers)
1. Quran Arabic text (sacred, immutable).
2. Translation (attributed, immutable, clearly labeled as translation).
3. Original educational content (our prompts, hints, exercise questions).
A translation or explanation must NEVER be presented as if it were the Quran itself.

## Adab (respect) in UX
- No "you failed" framing on Quran recall. Encourage gently.
- No gamification implying one user's faith/standing is superior to another's.
- Do not arrange/display verse snippets in a way that alters or misrepresents meaning.
- Render Arabic with correct RTL + diacritics; never auto-translate the Arabic.

## Content production workflow
QF/approved source -> curriculum design -> lesson draft -> exercise generation ->
HUMAN REVIEW by a qualified reviewer -> content QA -> publication.
AI may draft exercises but is never the source of truth for Quranic content.
No content is production-approved until its applicable terms + accuracy are reviewed.
