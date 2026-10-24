# UI/UX Design — Google Stitch Ingestion

## Status: INGESTED (2026-10-24)
Connected to Stitch via the Stitch MCP server (OAuth). Project
**"Hudaayah Quran Learning App"** (`projects/8483347196154126326`), 10 screens.

- Per-screen HTML pulled via `download_file` → `design/stitch/screens/*.html`.
- Mapped to MVP features, routes, and Flutter theme in `design/stitch/ui-spec.md`.
- See the ⚠️ scope-reconciliation table in `ui-spec.md`: the designs include
  out-of-scope features (Tajweed, tafsir, bookmarks, email login, levels) to defer.

### Refreshing from Stitch
Stitch MCP uses OAuth with an access token that expires ~hourly. In `~/.zshrc`:
```
export STITCH_PROJECT_ID="$(gcloud config get-value project)"
export STITCH_ACCESS_TOKEN="$(gcloud auth application-default print-access-token)"
```
Open a new terminal, launch `kiro-cli chat --agent hudaayah`, then use the stitch tools
(`list_screens`, `get_screen`, `download_file`) for project `8483347196154126326`.

## Screens expected for the Al-Fatihah MVP (map Stitch screens to these)
- Onboarding / welcome
- Sign in (Google + Apple)
- Home (today's lesson, streak, daily goal, XP)
- Quran reader (Al-Fatihah: Arabic RTL, translation, audio repeat/loop, QF attribution)
- Lesson flow (Listen → Read → Understand → Practice → Recall)
- Exercise screens: multiple_choice, word_order, listening_recall
- Review session (vocab)
- Progress
- Profile / settings (attribution, privacy policy, terms, logout, account deletion)

## Design rules to preserve from steering
- Arabic rendered RTL with correct diacritics; bundled Quran font; never auto-translated.
- Quran text, translation, and educational text visually distinct.
- Visible Quran Foundation attribution.
- Encouraging tone on recall; no "failed" framing; no religious-superiority ranking.

## How to point the agent at a Stitch link later
Run the Hudaayah agent and paste the share URL, or drop exports in `design/stitch/` and
ask the agent to generate `ui-spec.md`.
