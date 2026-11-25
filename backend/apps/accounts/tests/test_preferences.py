"""PATCH /me/preferences/: reciter validated against the adapter list, owner-only."""
from unittest.mock import patch

import pytest
from rest_framework.test import APIClient

from apps.accounts.models import AuthSession, User
from apps.common.errors import UpstreamError

pytestmark = pytest.mark.django_db

URL = "/api/v1/me/preferences/"


class _FakeQF:
    def get_reciters(self):
        return [{"id": 6}, {"id": 7}, {"id": 12}]  # 173 hidden by the adapter


@pytest.fixture(autouse=True)
def _qf():
    with patch("apps.accounts.views.get_client", return_value=_FakeQF()):
        yield


def _user(sub, **kw):
    user = User.objects.create_user(provider="google", provider_sub=sub, display_name=sub, **kw)
    _, access, _ = AuthSession.issue(user)
    c = APIClient()
    c.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")
    return user, c


def test_requires_auth():
    assert APIClient().patch(URL, {"reciter_id": 7}, format="json").status_code == 401


def test_saves_reciter_and_keeps_other_preferences():
    user, c = _user("a", preferences={"theme": "dark"})
    resp = c.patch(URL, {"reciter_id": 12}, format="json")
    assert resp.status_code == 200
    assert resp.json()["preferences"] == {"theme": "dark", "reciter_id": 12}
    user.refresh_from_db()
    assert user.preferences == {"theme": "dark", "reciter_id": 12}


@pytest.mark.parametrize("rid", [173, 999])
def test_unknown_or_hidden_reciter_rejected(rid):
    user, c = _user("a")
    resp = c.patch(URL, {"reciter_id": rid}, format="json")
    assert resp.status_code == 400
    assert resp.json()["error"]["code"] == "invalid_reciter"
    user.refresh_from_db()
    assert "reciter_id" not in user.preferences


@pytest.mark.parametrize("body", [{}, {"reciter_id": "7"}, {"reciter_id": True},
                                  {"reciter_id": None}, {"reciter_id": 7.5}, {"reciter_id": 0}])
def test_malformed_body_rejected(body):
    _, c = _user("a")
    resp = c.patch(URL, body, format="json")
    assert resp.status_code == 400
    assert resp.json()["error"]["code"] == "invalid_preferences"


def test_only_changes_own_preferences():
    owner, c = _user("owner")
    other, _ = _user("other", preferences={"reciter_id": 6})
    # A user id in the body is ignored; the caller's own record is the only one touched.
    c.patch(URL, {"reciter_id": 7, "user": str(other.pk), "id": str(other.pk)}, format="json")
    owner.refresh_from_db()
    other.refresh_from_db()
    assert owner.preferences["reciter_id"] == 7
    assert other.preferences == {"reciter_id": 6}


def test_upstream_failure_uses_error_envelope():
    _, c = _user("a")

    class _Down:
        def get_reciters(self):
            raise UpstreamError()

    with patch("apps.accounts.views.get_client", return_value=_Down()):
        resp = c.patch(URL, {"reciter_id": 7}, format="json")
    assert resp.status_code == 502
    assert resp.json()["error"]["code"] == "upstream_unavailable"
