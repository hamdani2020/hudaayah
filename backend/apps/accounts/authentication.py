"""DRF authentication backed by opaque access tokens (AuthSession).

Reads `Authorization: Bearer <access_token>`, validates it against a non-revoked,
non-expired session, and sets request.user. Tokens are never logged.
"""
from __future__ import annotations

from rest_framework import authentication

from .models import AuthSession


class BearerTokenAuthentication(authentication.BaseAuthentication):
    keyword = "Bearer"

    def authenticate(self, request):
        header = authentication.get_authorization_header(request).decode("utf-8")
        if not header:
            return None
        parts = header.split()
        if len(parts) != 2 or parts[0] != self.keyword:
            return None

        session = AuthSession.find_valid_access(parts[1])
        if session is None:
            return None  # fall through to Anonymous; permission layer denies

        request.auth_session = session
        return (session.user, session)

    def authenticate_header(self, request):
        return self.keyword
