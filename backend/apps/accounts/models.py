"""Accounts: multi-provider user + managed session tokens.

Keyed on (provider, provider_sub), never email alone (steering: R1). Session
tokens are opaque random strings stored hashed at rest; logout revokes them.
No passwords — authentication is delegated to Google/Apple.
"""
from __future__ import annotations

import hashlib
import secrets
from datetime import timedelta

from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models
from django.utils import timezone


class Provider(models.TextChoices):
    GOOGLE = "google", "Google"
    APPLE = "apple", "Apple"


class UserManager(BaseUserManager):
    use_in_migrations = True

    def create_user(self, *, provider: str, provider_sub: str, email: str | None = None,
                    display_name: str = "", **extra):
        if not provider or not provider_sub:
            raise ValueError("provider and provider_sub are required")
        email = self.normalize_email(email) if email else None
        user = self.model(
            provider=provider,
            provider_sub=provider_sub,
            email=email,
            display_name=display_name,
            **extra,
        )
        user.set_unusable_password()
        user.save(using=self._db)
        return user

    def create_superuser(self, *, provider: str = "google", provider_sub: str | None = None,
                         email: str | None = None, password: str | None = None, **extra):
        # Superusers are staff for Django admin (content review). Provider defaults
        # let `createsuperuser` work with a synthetic local subject.
        provider_sub = provider_sub or f"local:{secrets.token_hex(8)}"
        extra.setdefault("is_staff", True)
        extra.setdefault("is_superuser", True)
        user = self.create_user(
            provider=provider, provider_sub=provider_sub, email=email, **extra
        )
        if password:
            user.set_password(password)
            user.save(using=self._db)
        return user


class User(AbstractBaseUser, PermissionsMixin):
    provider = models.CharField(max_length=16, choices=Provider.choices)
    provider_sub = models.CharField(max_length=255)

    # Synthetic unique identity "<provider>:<sub>" — required because Django's
    # USERNAME_FIELD must be a single unique field. The (provider, provider_sub)
    # constraint below remains the real composite key.
    uid = models.CharField(max_length=288, unique=True, editable=False)

    email = models.EmailField(null=True, blank=True)
    display_name = models.CharField(max_length=150, blank=True, default="")
    avatar_url = models.URLField(null=True, blank=True)
    preferences = models.JSONField(default=dict, blank=True)

    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = UserManager()

    USERNAME_FIELD = "uid"
    REQUIRED_FIELDS: list[str] = []

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["provider", "provider_sub"], name="uniq_provider_sub"
            )
        ]
        indexes = [models.Index(fields=["provider", "provider_sub"])]

    def save(self, *args, **kwargs):
        # Keep uid in sync with the composite identity.
        self.uid = f"{self.provider}:{self.provider_sub}"
        super().save(*args, **kwargs)

    def __str__(self) -> str:
        return self.uid


def _hash_token(raw: str) -> str:
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


class AuthSession(models.Model):
    """A managed app session: one access token + one refresh token (hashed).

    Access tokens are short-lived; refresh tokens rotate. Revoking a session
    (logout) invalidates both.
    """

    ACCESS_TTL = timedelta(hours=1)
    REFRESH_TTL = timedelta(days=30)

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="sessions")
    access_token_hash = models.CharField(max_length=64, unique=True)
    refresh_token_hash = models.CharField(max_length=64, unique=True)
    access_expires_at = models.DateTimeField()
    refresh_expires_at = models.DateTimeField()
    revoked_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=["access_token_hash"]),
            models.Index(fields=["refresh_token_hash"]),
        ]

    # ── issuing / rotation ────────────────────────────────────────────────────
    @classmethod
    def issue(cls, user: User) -> tuple["AuthSession", str, str]:
        access_raw = secrets.token_urlsafe(32)
        refresh_raw = secrets.token_urlsafe(48)
        now = timezone.now()
        session = cls.objects.create(
            user=user,
            access_token_hash=_hash_token(access_raw),
            refresh_token_hash=_hash_token(refresh_raw),
            access_expires_at=now + cls.ACCESS_TTL,
            refresh_expires_at=now + cls.REFRESH_TTL,
        )
        return session, access_raw, refresh_raw

    def rotate(self) -> tuple[str, str]:
        access_raw = secrets.token_urlsafe(32)
        refresh_raw = secrets.token_urlsafe(48)
        now = timezone.now()
        self.access_token_hash = _hash_token(access_raw)
        self.refresh_token_hash = _hash_token(refresh_raw)
        self.access_expires_at = now + self.ACCESS_TTL
        self.refresh_expires_at = now + self.REFRESH_TTL
        self.save(update_fields=[
            "access_token_hash", "refresh_token_hash",
            "access_expires_at", "refresh_expires_at",
        ])
        return access_raw, refresh_raw

    def revoke(self) -> None:
        self.revoked_at = timezone.now()
        self.save(update_fields=["revoked_at"])

    # ── lookups ───────────────────────────────────────────────────────────────
    @classmethod
    def find_valid_access(cls, raw: str) -> "AuthSession | None":
        try:
            s = cls.objects.select_related("user").get(access_token_hash=_hash_token(raw))
        except cls.DoesNotExist:
            return None
        if s.revoked_at or s.access_expires_at <= timezone.now():
            return None
        return s

    @classmethod
    def find_valid_refresh(cls, raw: str) -> "AuthSession | None":
        try:
            s = cls.objects.select_related("user").get(refresh_token_hash=_hash_token(raw))
        except cls.DoesNotExist:
            return None
        if s.revoked_at or s.refresh_expires_at <= timezone.now():
            return None
        return s
