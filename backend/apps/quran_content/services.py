"""Reciter listing for the picker, built on the QF adapter."""
from __future__ import annotations

import logging

from apps.common.errors import AppError

from .client import get_client

logger = logging.getLogger(__name__)


def list_reciters(surahs: list[int]) -> list[dict]:
    """`[{id, name, style, has_timings}]` for reciters with audio for every given surah.

    A reciter is kept if, for each surah, it has a chapter file or per-ayah audio.
    `has_timings` is true only if every surah's chapter file has usable word timings.
    Results are cached by the adapter (<= 1 week).
    """
    client = get_client()
    result = []
    for reciter in client.get_reciters():
        has_timings = bool(surahs)
        available = True
        for surah in surahs:
            try:
                audio = client.get_chapter_audio(reciter["id"], surah)
            except AppError:
                # No chapter file; keep the reciter only if per-ayah files exist.
                has_timings = False
                if not reciter["has_per_ayah_audio"]:
                    available = False
                    break
                continue
            if not audio["has_timings"]:
                has_timings = False
        if not available:
            continue
        result.append(
            {
                "id": reciter["id"],
                "name": reciter["name"],
                "style": reciter["style"],
                "has_timings": has_timings,
            }
        )
    return result
