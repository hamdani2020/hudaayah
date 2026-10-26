"""Trimmed SM-2 scheduling (design §6).

Simplified from full SM-2 (no 0–5 quality grades — just correct/incorrect):
- correct:   repetitions++, interval grows (1 → 6 → round(prev * ease)), ease nudged up.
- incorrect: repetitions reset to 0, interval back to 1 day, ease nudged down (floor 1.3).
"""
from __future__ import annotations

from datetime import timedelta

from django.utils import timezone

from .models import ReviewItem, ReviewItemType

_MIN_EASE = 1.3
_FIRST_INTERVAL = 1
_SECOND_INTERVAL = 6


def ensure_item(user, *, content_ref: str, prompt: str = "",
                item_type: str = ReviewItemType.VOCAB) -> ReviewItem:
    """Create a review item if the user doesn't have it yet (due immediately)."""
    item, _ = ReviewItem.objects.get_or_create(
        user=user,
        item_type=item_type,
        content_ref=content_ref,
        defaults={"prompt": prompt, "due_at": timezone.now()},
    )
    return item


def apply_result(item: ReviewItem, *, correct: bool) -> ReviewItem:
    """Update SM-2 state after a review and reschedule `due_at`."""
    if correct:
        if item.repetitions == 0:
            item.interval_days = _FIRST_INTERVAL
        elif item.repetitions == 1:
            item.interval_days = _SECOND_INTERVAL
        else:
            item.interval_days = max(1, round(item.interval_days * item.ease))
        item.repetitions += 1
        item.ease = item.ease + 0.1
    else:
        item.repetitions = 0
        item.interval_days = _FIRST_INTERVAL
        item.ease = max(_MIN_EASE, item.ease - 0.2)

    item.last_result = correct
    item.due_at = timezone.now() + timedelta(days=item.interval_days)
    item.save(update_fields=[
        "interval_days", "ease", "repetitions", "last_result", "due_at", "updated_at"
    ])
    return item


def due_items(user, *, now=None):
    now = now or timezone.now()
    return (
        ReviewItem.objects.filter(
            user=user, item_type=ReviewItemType.VOCAB, due_at__lte=now
        )
        .order_by("due_at")
    )
