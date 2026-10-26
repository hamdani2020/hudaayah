"""Assemble a lesson's runtime content from QF references.

Keeps the three content layers explicit and separate (quran-content-rules):
  1. arabic       — sacred Quran text (from QF, immutable)
  2. translation  — attributed translation (from QF, labeled as translation)
  3. (educational content lives on the Lesson/Exercise models, not here)

All QF text comes through the adapter; nothing is stored verse-text-side.
"""
from __future__ import annotations

from apps.quran_content.client import get_client

from .models import Lesson


def build_lesson_content(lesson: Lesson) -> dict:
    """Return per-ayah content for the lesson, fetched live from QF.

    Shape:
      {
        "ayahs": [
          {"verse_key": "1:1", "arabic": "...", "translation": "...",
           "words": [...], "audio_url": "..."},
          ...
        ],
        "attribution": "Quran content provided by Quran Foundation"
      }
    """
    client = get_client()
    translation_id = _ref_int(lesson.translation_source)
    reciter_id = _ref_int(lesson.recitation_source)

    ayahs: list[dict] = []
    for verse_key in lesson.verse_keys:
        entry: dict = {"verse_key": verse_key}

        # Layer 1 — Arabic + word-by-word (sacred; never altered).
        wbw = client.get_word_by_word(verse_key)
        verse = (wbw or {}).get("verse", {})
        entry["arabic"] = verse.get("text_uthmani") or verse.get("text_indopak")
        entry["words"] = _extract_words(verse.get("words", []))

        # Layer 2 — translation (attributed, labeled).
        if translation_id is not None:
            tr = client.get_translation(verse_key, translation_id)
            entry["translation"] = _extract_translation(tr)

        # Audio (recitation) reference.
        if reciter_id is not None:
            audio = client.get_audio(verse_key, reciter_id)
            entry["audio_url"] = _extract_audio_url(audio)

        ayahs.append(entry)

    return {
        "ayahs": ayahs,
        "attribution": _attribution(lesson),
    }


def _ref_int(source) -> int | None:
    if source is None:
        return None
    try:
        return int(source.provider_ref)
    except (TypeError, ValueError):
        return None


def _extract_words(words: list) -> list[dict]:
    out = []
    for w in words or []:
        out.append({
            "arabic": w.get("text_uthmani") or w.get("text"),
            "translation": (w.get("translation") or {}).get("text"),
            "transliteration": (w.get("transliteration") or {}).get("text"),
        })
    return out


def _extract_translation(tr: dict) -> str | None:
    translations = (tr or {}).get("translations") or []
    if translations:
        return translations[0].get("text")
    return (tr or {}).get("text")


def _extract_audio_url(audio: dict) -> str | None:
    from django.conf import settings

    files = (audio or {}).get("audio_files") or []
    if not files:
        return None
    raw = files[0].get("url") or files[0].get("audio_url")
    if not raw:
        return None
    if raw.startswith("http://") or raw.startswith("https://"):
        return raw
    # QF returns a path relative to the audio CDN.
    base = settings.QF_AUDIO_CDN_BASE.rstrip("/")
    return f"{base}/{raw.lstrip('/')}"


def _attribution(lesson: Lesson) -> str:
    parts = ["Quran content provided by Quran Foundation"]
    if lesson.translation_source and lesson.translation_source.attribution:
        parts.append(f"Translation: {lesson.translation_source.attribution}")
    if lesson.recitation_source and lesson.recitation_source.attribution:
        parts.append(f"Recitation: {lesson.recitation_source.attribution}")
    return " · ".join(parts)
