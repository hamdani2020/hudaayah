"""Assemble a lesson's runtime content from QF references.

Keeps the three content layers explicit and separate (quran-content-rules):
  1. arabic       — sacred Quran text (from QF, immutable)
  2. translation  — attributed translation (from QF, labeled as translation)
  3. (educational content lives on the Lesson/Exercise models, not here)

All QF text comes through the adapter; nothing is stored verse-text-side.
"""
from __future__ import annotations

from apps.common.errors import AppError
from apps.quran_content.client import DEFAULT_RECITER_ID, get_client

from .models import Lesson


def published_surahs() -> list[int]:
    """Distinct surah numbers of published lessons, ascending."""
    return sorted(set(Lesson.objects.published().values_list("surah", flat=True)))


def build_lesson_content(lesson: Lesson, audio: dict | None = None) -> dict:
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
    chosen = (audio or {}).get("reciter")
    if chosen:
        # Per-ayah `audio_url` (older apps) follows the chosen reciter when that
        # reciter has per-ayah files; otherwise it keeps the lesson default.
        by_id = {r["id"]: r for r in client.get_reciters()}
        if by_id.get(chosen["id"], {}).get("has_per_ayah_audio"):
            reciter_id = chosen["id"]

    ayahs: list[dict] = []
    for verse_key in lesson.verse_keys:
        entry: dict = {"verse_key": verse_key}

        # Layer 1 — Arabic + word-by-word (sacred; never altered).
        wbw = client.get_word_by_word(verse_key)
        verse = (wbw or {}).get("verse", {})
        # Prefer QPC Hafs text: it is encoded for the bundled UthmanicHafs font.
        entry["arabic"] = (
            verse.get("text_qpc_hafs")
            or verse.get("text_uthmani")
            or verse.get("text_indopak")
        )
        entry["words"] = _extract_words(verse.get("words", []))

        # Layer 2 — translation (attributed, labeled).
        if translation_id is not None:
            tr = client.get_translation(verse_key, translation_id)
            entry["translation"] = _extract_translation(tr)

        # Audio (recitation) reference.
        if reciter_id is not None:
            entry["audio_url"] = _extract_audio_url(client.get_audio(verse_key, reciter_id))

        ayahs.append(entry)

    return {
        "ayahs": ayahs,
        "attribution": _attribution(lesson, chosen),
    }


def resolve_reciter_id(requested, user) -> int | None:
    """The learner's explicit choice: `?reciter=` first, then the saved preference.

    Anything that is not a positive integer is ignored.
    """
    for raw in (requested, (getattr(user, "preferences", None) or {}).get("reciter_id")):
        if isinstance(raw, bool):
            continue
        try:
            value = int(raw)
        except (TypeError, ValueError):
            continue
        if value > 0:
            return value
    return None


def build_lesson_audio(lesson: Lesson, explicit_reciter_id: int | None = None) -> dict | None:
    """The lesson's `audio` block, or None if no reciter has audio for it.

    Reciter order: the learner's choice, the lesson's default recitation, then the
    app default. The first reciter with usable audio wins. `fallback_from` is the
    learner's choice when a different reciter had to be used.

    Mode: `chapter` when the reciter's chapter file has a usable timing for every verse
    of THIS lesson's range; otherwise `per_ayah` if the reciter has per-ayah files.
    """
    client = get_client()
    try:
        reciters = {r["id"]: r for r in client.get_reciters()}
    except AppError:
        return None
    verse_keys = lesson.verse_keys
    if not verse_keys:
        return None

    candidates: list[int] = []
    for rid in (explicit_reciter_id, _ref_int(lesson.recitation_source), DEFAULT_RECITER_ID):
        if rid is not None and rid in reciters and rid not in candidates:
            candidates.append(rid)

    for rid in candidates:
        block = _audio_for_reciter(client, lesson, verse_keys, reciters[rid])
        if block is None:
            continue
        block["fallback_from"] = (
            explicit_reciter_id
            if explicit_reciter_id is not None and explicit_reciter_id != rid
            else None
        )
        return block
    return None


def _audio_for_reciter(client, lesson: Lesson, verse_keys: list[str], reciter: dict) -> dict | None:
    head = {
        "reciter": {"id": reciter["id"], "name": reciter["name"], "style": reciter["style"]},
    }
    try:
        chapter = client.get_chapter_audio(reciter["id"], lesson.surah)
    except AppError:
        chapter = None

    if chapter:
        by_key = {v["verse_key"]: v for v in chapter["verses"]}
        lesson_verses = [by_key.get(k) for k in verse_keys]
        if all(v is not None and v["usable"] for v in lesson_verses):
            return {
                **head,
                "mode": "chapter",
                "chapter_url": chapter["audio_url"],
                "clip_start_ms": min(v["start_ms"] for v in lesson_verses),
                "clip_end_ms": max(v["end_ms"] for v in lesson_verses),
                "has_word_timings": any(v["words"] for v in lesson_verses),
                "verses": [
                    {
                        "verse_key": v["verse_key"],
                        "start_ms": v["start_ms"],
                        "end_ms": v["end_ms"],
                        "words": v["words"],
                    }
                    for v in lesson_verses
                ],
                "provenance": chapter["provenance"],
            }

    if reciter.get("has_per_ayah_audio"):
        verses = []
        try:
            for key in verse_keys:
                url = _extract_audio_url(client.get_audio(key, reciter["id"]))
                if not url:
                    return None
                verses.append({"verse_key": key, "audio_url": url})
        except AppError:
            return None
        return {
            **head,
            "mode": "per_ayah",
            "chapter_url": None,
            "has_word_timings": False,
            "verses": verses,
        }
    return None

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
        # The end-of-ayah marker has no audio segment; skip it. QF `position` is
        # 1-based and equals the segment `word_index` (see reader-audio design).
        if w.get("char_type_name") == "end":
            continue
        out.append({
            "position": w.get("position"),
            "arabic": w.get("text_qpc_hafs") or w.get("text_uthmani") or w.get("text"),
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


def _attribution(lesson: Lesson, reciter: dict | None = None) -> str:
    parts = ["Quran content provided by Quran Foundation"]
    if lesson.translation_source and lesson.translation_source.attribution:
        parts.append(f"Translation: {lesson.translation_source.attribution}")
    if reciter and reciter.get("name"):
        parts.append(f"Recitation: {reciter['name']}")
    elif lesson.recitation_source and lesson.recitation_source.attribution:
        parts.append(f"Recitation: {lesson.recitation_source.attribution}")
    return " · ".join(parts)
