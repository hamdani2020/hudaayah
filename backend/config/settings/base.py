"""Base settings shared across environments (Hudaayah backend)."""
from pathlib import Path

import environ

# backend/ root (config/settings/base.py -> parents[2] == backend/)
BASE_DIR = Path(__file__).resolve().parents[2]

env = environ.Env(
    DEBUG=(bool, False),
)

# Read a .env if present (Compose also injects env; env vars win).
_env_file = BASE_DIR.parent / ".env"
if _env_file.exists():
    environ.Env.read_env(str(_env_file))

SECRET_KEY = env("DJANGO_SECRET_KEY", default="insecure-dev-key-change-me")
DEBUG = env.bool("DJANGO_DEBUG", default=False)
ALLOWED_HOSTS = env.list("DJANGO_ALLOWED_HOSTS", default=["localhost", "127.0.0.1"])

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    # third-party
    "rest_framework",
    # local apps
    "apps.common",
    "apps.accounts",
    "apps.quran_content",
    "apps.lessons",
    "apps.exercises",
    "apps.progress",
    "apps.review",
    "apps.gamification",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    # WhiteNoise serves static files directly (must be right after SecurityMiddleware).
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"

# Postgres via Compose service "db" (overridable by env).
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": env("POSTGRES_DB", default="hudaayah"),
        "USER": env("POSTGRES_USER", default="hudaayah"),
        "PASSWORD": env("POSTGRES_PASSWORD", default="hudaayah"),
        "HOST": env("POSTGRES_HOST", default="db"),
        "PORT": env("POSTGRES_PORT", default="5432"),
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

LANGUAGE_CODE = "en-us"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

AUTH_USER_MODEL = "accounts.User"

API_PREFIX = "api/v1/"

REST_FRAMEWORK = {
    "DEFAULT_RENDERER_CLASSES": [
        "rest_framework.renderers.JSONRenderer",
    ],
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 20,
    "EXCEPTION_HANDLER": "apps.common.exception_handler.api_exception_handler",
}

# ── Quran Foundation (backend-only; never shipped to the client) ──────────────
# QF_ENV selects pre-live vs production hosts; credentials from env/secret store.
QF_ENV = env("QF_ENV", default="prelive")
QF_CLIENT_ID = env("QF_CLIENT_ID", default="")
QF_CLIENT_SECRET = env("QF_CLIENT_SECRET", default="")
QF_CACHE_MAX_SECONDS = env.int("QF_CACHE_MAX_SECONDS", default=60 * 60 * 24 * 7)  # ≤ 1 week

_QF_HOSTS = {
    "prelive": {
        "auth": "https://prelive-oauth2.quran.foundation",
        "api": "https://apis-prelive.quran.foundation",
    },
    "production": {
        "auth": "https://oauth2.quran.foundation",
        "api": "https://apis.quran.foundation",
    },
}
QF_AUTH_BASE = _QF_HOSTS.get(QF_ENV, _QF_HOSTS["prelive"])["auth"]
QF_API_BASE = _QF_HOSTS.get(QF_ENV, _QF_HOSTS["prelive"])["api"]

# QF audio files are returned as paths relative to this CDN host.
QF_AUDIO_CDN_BASE = env("QF_AUDIO_CDN_BASE", default="https://verses.quran.foundation")

# ── Social auth (verification is server-side; these are public client IDs) ────
# The expected `aud` of Google ID tokens. Comma-separated to allow web/iOS/Android
# client IDs that may differ per platform.
GOOGLE_CLIENT_IDS = env.list("GOOGLE_CLIENT_IDS", default=[])
# Apple is wired later (task 6.1); placeholder config kept for the provider layer.
APPLE_CLIENT_IDS = env.list("APPLE_CLIENT_IDS", default=[])

# Simple in-process cache is fine for the single-container MVP (token caching).
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
        "LOCATION": "hudaayah-local",
    }
}
