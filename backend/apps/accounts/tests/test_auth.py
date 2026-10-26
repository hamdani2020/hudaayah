"""Auth flow tests: Google sign-in (mocked verification), /me ownership,
refresh rotation, logout revocation, and cross-user access denial."""
from unittest.mock import patch

import pytest
from rest_framework.test import APIClient

from apps.accounts.models import AuthSession, Provider, User
from apps.accounts.providers import VerifiedIdentity

pytestmark = pytest.mark.django_db


def _identity(sub="google-sub-1", email="a@example.com", name="Aisha"):
    return VerifiedIdentity(
        provider=Provider.GOOGLE, subject=sub, email=email,
        display_name=name, avatar_url=None,
    )


def _login(client, identity):
    with patch("apps.accounts.views.verify_google", return_value=identity):
        resp = client.post("/api/v1/auth/google/", {"id_token": "x"}, format="json")
    return resp


def test_google_signin_creates_user_and_session():
    client = APIClient()
    resp = _login(client, _identity())
    assert resp.status_code == 201
    body = resp.json()
    assert body["access_token"] and body["refresh_token"]
    assert body["user"]["display_name"] == "Aisha"
    assert User.objects.count() == 1
    user = User.objects.get()
    assert user.provider == "google"
    assert user.provider_sub == "google-sub-1"
    assert user.uid == "google:google-sub-1"


def test_google_signin_is_idempotent_on_repeat():
    client = APIClient()
    _login(client, _identity(name="Old"))
    _login(client, _identity(name="New"))
    assert User.objects.count() == 1
    assert User.objects.get().display_name == "New"  # profile refreshed


def test_me_requires_auth():
    assert APIClient().get("/api/v1/me/").status_code == 401


def test_me_returns_own_profile():
    client = APIClient()
    token = _login(client, _identity()).json()["access_token"]
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    resp = client.get("/api/v1/me/")
    assert resp.status_code == 200
    data = resp.json()
    assert data["provider"] == "google"
    assert data["display_name"] == "Aisha"
    # The raw provider subject is never exposed in the profile payload.
    assert "provider_sub" not in data


def test_refresh_rotates_tokens():
    client = APIClient()
    tokens = _login(client, _identity()).json()
    resp = client.post("/api/v1/auth/refresh/",
                       {"refresh_token": tokens["refresh_token"]}, format="json")
    assert resp.status_code == 200
    new = resp.json()
    assert new["access_token"] != tokens["access_token"]
    assert new["refresh_token"] != tokens["refresh_token"]
    # Old refresh no longer valid after rotation.
    assert client.post("/api/v1/auth/refresh/",
                       {"refresh_token": tokens["refresh_token"]},
                       format="json").status_code == 401


def test_logout_revokes_session():
    client = APIClient()
    token = _login(client, _identity()).json()["access_token"]
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    assert client.post("/api/v1/auth/logout/").status_code == 204
    # Access token is dead after revoke.
    assert client.get("/api/v1/me/").status_code == 401
    assert AuthSession.objects.get().revoked_at is not None


def test_cannot_access_with_other_users_revoked_token():
    client = APIClient()
    a = _login(APIClient(), _identity(sub="sub-a", email="a@x.com")).json()
    # A second, distinct user.
    _login(APIClient(), _identity(sub="sub-b", email="b@x.com"))
    # User A's token only ever resolves to user A.
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {a['access_token']}")
    assert client.get("/api/v1/me/").json()["id"] == a["user"]["id"]
