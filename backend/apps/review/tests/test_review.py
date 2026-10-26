"""Review scheduler (trimmed SM-2) + due endpoint + ownership (R6)."""
import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.models import AuthSession, User
from apps.review.scheduler import apply_result, ensure_item

pytestmark = pytest.mark.django_db


def _client(sub="rev"):
    user, _ = User.objects.get_or_create(
        provider="google", provider_sub=sub, defaults={"display_name": sub}
    )
    _, access, _ = AuthSession.issue(user)
    c = APIClient()
    c.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
    return c, user


def test_correct_grows_interval_incorrect_resets():
    _, user = _client()
    item = ensure_item(user, content_ref="root:r-h-m", prompt="?")
    apply_result(item, correct=True)
    assert item.repetitions == 1 and item.interval_days == 1
    apply_result(item, correct=True)
    assert item.repetitions == 2 and item.interval_days == 6
    ease_before = item.ease
    apply_result(item, correct=False)
    assert item.repetitions == 0 and item.interval_days == 1
    assert item.ease < ease_before  # ease nudged down, floor 1.3
    assert item.ease >= 1.3


def test_due_endpoint_lists_only_due_items():
    client, user = _client()
    ensure_item(user, content_ref="root:r-h-m")  # due now
    # One scheduled into the future (not due).
    future = ensure_item(user, content_ref="root:h-m-d")
    apply_result(future, correct=True)  # pushes due_at to tomorrow
    body = client.get("/api/v1/reviews/due/").json()
    refs = [i["content_ref"] for i in body["items"]]
    assert "root:r-h-m" in refs
    assert "root:h-m-d" not in refs


def test_submit_review_reschedules():
    client, user = _client()
    item = ensure_item(user, content_ref="root:r-h-m")
    resp = client.post(f"/api/v1/reviews/{item.id}/review/", {"correct": True},
                       format="json")
    assert resp.status_code == 200
    assert resp.json()["repetitions"] == 1
    item.refresh_from_db()
    assert item.due_at > timezone.now()


def test_cannot_review_another_users_item():
    _, owner = _client(sub="owner")
    item = ensure_item(owner, content_ref="root:r-h-m")
    other, _ = _client(sub="intruder")
    resp = other.post(f"/api/v1/reviews/{item.id}/review/", {"correct": True},
                      format="json")
    assert resp.status_code == 404
