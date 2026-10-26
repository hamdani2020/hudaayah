"""Shared content publication lifecycle + audit fields.

Lessons and exercises move draft -> in_review -> published (plus archived).
Only `published` content is served to learners. Publishing stamps who approved
it and when (quran-content-rules: human review before publication; R9).
"""
from __future__ import annotations

from django.conf import settings
from django.db import models
from django.utils import timezone


class ContentStatus(models.TextChoices):
    DRAFT = "draft", "Draft"
    IN_REVIEW = "in_review", "In review"
    PUBLISHED = "published", "Published"
    ARCHIVED = "archived", "Archived"


class PublishableQuerySet(models.QuerySet):
    def published(self):
        return self.filter(status=ContentStatus.PUBLISHED)


class PublishableModel(models.Model):
    """Abstract base adding a status lifecycle + approval audit trail."""

    status = models.CharField(
        max_length=16,
        choices=ContentStatus.choices,
        default=ContentStatus.DRAFT,
    )
    approved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="+",
    )
    approved_at = models.DateTimeField(null=True, blank=True)

    objects = PublishableQuerySet.as_manager()

    class Meta:
        abstract = True

    @property
    def is_published(self) -> bool:
        return self.status == ContentStatus.PUBLISHED

    def mark_published(self, *, by) -> None:
        """Publish and stamp the audit fields in one step."""
        self.status = ContentStatus.PUBLISHED
        self.approved_by = by
        self.approved_at = timezone.now()
        self.save(update_fields=["status", "approved_by", "approved_at"])
