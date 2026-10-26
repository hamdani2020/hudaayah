"""Exercise definitions + server-side grading.

The `answer_key` is server-only and MUST NOT be serialized to clients before
submission (django-conventions, R4). Grading happens on the server; the client
submits an answer and receives only `{correct, feedback}`.
"""
from __future__ import annotations

from django.db import models

from apps.common.lifecycle import PublishableModel
from apps.lessons.models import Lesson


class ExerciseType(models.TextChoices):
    MULTIPLE_CHOICE = "multiple_choice", "Multiple choice"
    WORD_ORDER = "word_order", "Word order"
    LISTENING_RECALL = "listening_recall", "Listening recall"


class Exercise(PublishableModel):
    lesson = models.ForeignKey(
        Lesson, on_delete=models.CASCADE, related_name="exercises"
    )
    type = models.CharField(max_length=24, choices=ExerciseType.choices)
    position = models.PositiveIntegerField(default=0)

    # Client-safe presentation data (prompt, options/tokens WITHOUT the answer).
    config = models.JSONField(default=dict, blank=True)
    # QF resource references used by the exercise (by stable ID), never text.
    content_references = models.JSONField(default=dict, blank=True)
    # Server-only. Never include in any client-facing serializer.
    answer_key = models.JSONField(default=dict, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["lesson_id", "position", "id"]
        indexes = [models.Index(fields=["lesson", "position"])]

    def __str__(self) -> str:
        return f"{self.get_type_display()} #{self.position} (lesson {self.lesson_id})"
