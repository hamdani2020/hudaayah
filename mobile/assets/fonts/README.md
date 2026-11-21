# Quran font (Uthmanic Hafs)

`UthmanicHafs.ttf` is **KFGQPC Uthmanic Script HAFS, version 18**
(`UthmanicHafs1Ver18.ttf`), copyright King Fahd Glorious Quran Printing Complex.

- Source: Quran Foundation's font host, as documented in the QF font-rendering guide
  https://api-docs.quran.foundation/docs/tutorials/fonts/font-rendering/
  (`https://verses.quran.foundation/fonts/quran/hafs/uthmanic_hafs/UthmanicHafs1Ver18.ttf`)
- SHA-256: `a0636e68e375af9552470d67773936f54d536e6586ce2608311b2fe7f9cbec3a`
- Registered in `mobile/pubspec.yaml` as family `UthmanicHafs`.

## Text pairing
This font is designed for QF's `text_qpc_hafs` field. The backend requests
`text_qpc_hafs` (falling back to `text_uthmani`) in
`backend/apps/quran_content/client.py` and `backend/apps/lessons/services.py`.
If you change the font version, re-check the pairing; mismatched versions can
render some marks incorrectly.

## Rules
- Do not modify, subset or re-encode the font file.
- Keep the KFGQPC credit (shown in the app's attribution / About section).
- Bundling is permitted per project steering (tech.md) with attribution and an
  active Quran Foundation Developer Console account.
