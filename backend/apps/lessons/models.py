"""Lesson definitions + content provenance.

CRITICAL (quran-content-rules): lessons reference QF resources by stable IDs.
No Quran Arabic text, translation text, or audio bytes are stored here — the text
is fetched at runtime through the QF adapter and cached ≤ 1 week.
"""
from __future__ import annotations

from django.db import models

from apps.common.lifecycle import PublishableModel


class ContentSource(models.Model):
    """Provenance for an externally sourced item (quran-content-rules: Provenance).

    One row per (provider resource) the app relies on, e.g. a translation or a
    reciter. Tracks attribution + caching policy + retrieval metadata. Holds NO
    verse text.
    """

    class ResourceType(models.TextChoices):
        TRANSLATION = "translation", "Translation"
        RECITATION = "recitation", "Recitation (audio)"
        WORD_BY_WORD = "word_by_word", "Word-by-word"
        CHAPTER = "chapter", "Chapter metadata"

    provider = models.CharField(max_length=64, default="quran_foundation")
    resource_type = models.CharField(max_length=32, choices=ResourceType.choices)
    # Stable provider identifier (e.g. translation_id / reciter_id as a string).
    provider_ref = models.CharField(max_length=128)
    language = models.CharField(max_length=16, blank=True, default="")
    # Human-readable attribution shown/credited in the app.
    attribution = models.CharField(max_length=255, blank=True, default="")
    version = models.CharField(max_length=64, blank=True, default="")
    # Reference to the caching policy that governs this item (≤ 1 week for QF).
    caching_policy_ref = models.CharField(max_length=64, default="qf_max_1_week")
    retrieved_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["provider", "resource_type", "provider_ref"],
                name="uniq_content_source",
            )
        ]

    def __str__(self) -> str:
        return f"{self.provider}:{self.resource_type}:{self.provider_ref}"


class Lesson(PublishableModel):
    """A lesson over an ayah range of a surah, with QF resource references only."""

    title = models.CharField(max_length=150)
    order = models.PositiveIntegerField(default=0)
    objectives = models.JSONField(default=list, blank=True)

    surah = models.PositiveIntegerField(default=1)  # pilot: Al-Fatihah
    ayah_start = models.PositiveIntegerField(default=1)
    ayah_end = models.PositiveIntegerField(default=7)

    # QF resource references (stable IDs), NOT text.
    translation_source = models.ForeignKey(
        ContentSource, on_delete=models.PROTECT, null=True, blank=True,
        related_name="lessons_translation",
        limit_choices_to={"resource_type": ContentSource.ResourceType.TRANSLATION},
    )
    recitation_source = models.ForeignKey(
        ContentSource, on_delete=models.PROTECT, null=True, blank=True,
        related_name="lessons_recitation",
        limit_choices_to={"resource_type": ContentSource.ResourceType.RECITATION},
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["order", "id"]

    def __str__(self) -> str:
        return f"{self.title} (surah {self.surah}:{self.ayah_start}-{self.ayah_end})"

    @property
    def verse_keys(self) -> list[str]:
        """QF verse keys covered, e.g. ['1:1', ..., '1:7']."""
        return [f"{self.surah}:{a}" for a in range(self.ayah_start, self.ayah_end + 1)]
