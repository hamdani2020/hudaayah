"""Attempts, answers, per-user progress, and daily activity.

Integrity (design §2 / R5): object-level ownership, completion+reward in a
transaction, idempotency_key prevents double-award.
"""
from __future__ import annotations

from django.conf import settings
from django.db import models

from apps.exercises.models import Exercise
from apps.lessons.models import Lesson


class AttemptStatus(models.TextChoices):
    IN_PROGRESS = "in_progress", "In progress"
    COMPLETED = "completed", "Completed"


class LessonAttempt(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="attempts"
    )
    lesson = models.ForeignKey(Lesson, on_delete=models.CASCADE, related_name="attempts")
    status = models.CharField(
        max_length=16, choices=AttemptStatus.choices, default=AttemptStatus.IN_PROGRESS
    )
    started_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    score_summary = models.JSONField(default=dict, blank=True)
    # Set once on completion; unique so a retried completion can't double-award.
    idempotency_key = models.CharField(
        max_length=64, null=True, blank=True, unique=True
    )

    class Meta:
        indexes = [
            models.Index(fields=["user", "lesson"]),
            models.Index(fields=["user", "status"]),
        ]

    def __str__(self) -> str:
        return f"Attempt {self.id} (user {self.user_id}, lesson {self.lesson_id})"


class ExerciseAnswer(models.Model):
    attempt = models.ForeignKey(
        LessonAttempt, on_delete=models.CASCADE, related_name="answers"
    )
    exercise = models.ForeignKey(Exercise, on_delete=models.CASCADE, related_name="+")
    submitted = models.JSONField(default=dict, blank=True)
    correct = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [models.Index(fields=["attempt", "exercise"])]

    def __str__(self) -> str:
        return f"Answer {self.id} (attempt {self.attempt_id}, correct={self.correct})"


class ProgressState(models.TextChoices):
    NOT_STARTED = "not_started", "Not started"
    IN_PROGRESS = "in_progress", "In progress"
    COMPLETED = "completed", "Completed"


class UserProgress(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="progress"
    )
    lesson = models.ForeignKey(Lesson, on_delete=models.CASCADE, related_name="+")
    state = models.CharField(
        max_length=16, choices=ProgressState.choices, default=ProgressState.NOT_STARTED
    )
    best_result = models.JSONField(default=dict, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    last_activity = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["user", "lesson"], name="uniq_user_lesson_progress"
            )
        ]
        indexes = [models.Index(fields=["user", "lesson"])]


class DailyActivity(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="daily_activity"
    )
    date = models.DateField()
    xp_earned = models.PositiveIntegerField(default=0)
    lessons_completed = models.PositiveIntegerField(default=0)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["user", "date"], name="uniq_user_date")
        ]
        indexes = [models.Index(fields=["user", "date"])]
