"""Server-side verification of third-party identity tokens.

Returns a normalized identity; the caller maps it to a (provider, provider_sub)
user. Google is implemented now; Apple is added in task 6.1 behind the same shape.

Rules (steering R1 / django-conventions): verify signature, issuer, audience,
and expiry server-side; use the stable subject (`sub`), never email alone.
"""
from __future__ import annotations

from dataclasses import dataclass

from django.conf import settings
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token

from apps.common.errors import AppError

from .models import Provider


class InvalidIdentityToken(AppError):
    code = "invalid_identity_token"
    message = "Sign-in could not be verified. Please try again."
    http_status = 401


@dataclass(frozen=True)
class VerifiedIdentity:
    provider: str
    subject: str
    email: str | None
    display_name: str
    avatar_url: str | None


_GOOGLE_ISSUERS = {"accounts.google.com", "https://accounts.google.com"}


def verify_google(id_token_str: str) -> VerifiedIdentity:
    if not settings.GOOGLE_CLIENT_IDS:
        # Misconfiguration is a server problem, not a client auth failure.
        raise InvalidIdentityToken(code="google_not_configured")

    try:
        # google-auth validates signature (via Google JWKS), aud, and exp.
        claims = google_id_token.verify_oauth2_token(
            id_token_str,
            google_requests.Request(),
        )
    except ValueError:
        raise InvalidIdentityToken()

    if claims.get("iss") not in _GOOGLE_ISSUERS:
        raise InvalidIdentityToken()

    # Explicit audience check against our allowed client IDs.
    if claims.get("aud") not in set(settings.GOOGLE_CLIENT_IDS):
        raise InvalidIdentityToken(code="audience_mismatch")

    sub = claims.get("sub")
    if not sub:
        raise InvalidIdentityToken()

    email = claims.get("email")
    # Only trust the email if Google says it is verified.
    if email and not claims.get("email_verified", False):
        email = None

    return VerifiedIdentity(
        provider=Provider.GOOGLE,
        subject=sub,
        email=email,
        display_name=claims.get("name", "") or "",
        avatar_url=claims.get("picture"),
    )
