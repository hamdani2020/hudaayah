"""Spaced-repetition review items (trimmed SM-2).

Design §6: track interval + ease per item; correct grows the interval, incorrect
resets to a short interval. The model supports both vocab and ayah_recall types;
only `vocab` is surfaced in the pilot UI (R6).
"""
from __future__ import annotations

from django.conf import settings
from django.db import models


class ReviewItemType(models.TextChoices):
    VOCAB = "vocab", "Vocabulary"
    AYAH_RECALL = "ayah_recall", "Ayah recall"


class ReviewItem(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="review_items"
    )
    item_type = models.CharField(
        max_length=16, choices=ReviewItemType.choices, default=ReviewItemType.VOCAB
    )
    # Stable reference to the thing being reviewed, e.g. a QF word/root key.
    content_ref = models.CharField(max_length=128)
    # Human-facing prompt/label (our educational content, not QF text).
    prompt = models.CharField(max_length=255, blank=True, default="")

    # SM-2 state.
    interval_days = models.PositiveIntegerField(default=0)
    ease = models.FloatField(default=2.5)
    repetitions = models.PositiveIntegerField(default=0)
    due_at = models.DateTimeField()
    last_result = models.BooleanField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["user", "item_type", "content_ref"],
                name="uniq_user_review_item",
            )
        ]
        indexes = [models.Index(fields=["user", "due_at"])]

    def __str__(self) -> str:
        return f"{self.item_type}:{self.content_ref} (user {self.user_id})"
