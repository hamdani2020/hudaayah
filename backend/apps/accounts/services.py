"""Account services: map a verified identity to a User, issue/refresh/revoke."""
from __future__ import annotations

from django.db import transaction

from .models import AuthSession, User
from .providers import VerifiedIdentity


@transaction.atomic
def get_or_create_user(identity: VerifiedIdentity) -> User:
    """Look up by (provider, provider_sub); create if new. Never key on email."""
    defaults = {
        "email": identity.email,
        "display_name": identity.display_name,
        "avatar_url": identity.avatar_url,
    }
    user, created = User.objects.get_or_create(
        provider=identity.provider,
        provider_sub=identity.subject,
        defaults=defaults,
    )
    if not created:
        # Refresh mutable profile fields from the provider on each sign-in.
        changed = False
        if identity.display_name and user.display_name != identity.display_name:
            user.display_name = identity.display_name
            changed = True
        if identity.avatar_url and user.avatar_url != identity.avatar_url:
            user.avatar_url = identity.avatar_url
            changed = True
        if identity.email and user.email != identity.email:
            user.email = identity.email
            changed = True
        if changed:
            user.save(update_fields=["display_name", "avatar_url", "email", "updated_at"])
    return user


def issue_session(user: User) -> dict:
    session, access_raw, refresh_raw = AuthSession.issue(user)
    return _token_payload(session, access_raw, refresh_raw)


def refresh_session(refresh_raw: str) -> dict | None:
    session = AuthSession.find_valid_refresh(refresh_raw)
    if session is None:
        return None
    access_raw, new_refresh_raw = session.rotate()
    return _token_payload(session, access_raw, new_refresh_raw)


def _token_payload(session: AuthSession, access_raw: str, refresh_raw: str) -> dict:
    return {
        "access_token": access_raw,
        "refresh_token": refresh_raw,
        "access_expires_at": session.access_expires_at.isoformat(),
        "refresh_expires_at": session.refresh_expires_at.isoformat(),
    }
