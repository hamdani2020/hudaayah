"""Development settings — used by the Docker `web` service for local dev."""
from .base import *  # noqa: F401,F403
from .base import env

DEBUG = env.bool("DJANGO_DEBUG", default=True)

ALLOWED_HOSTS = env.list(
    "DJANGO_ALLOWED_HOSTS",
    # 10.0.2.2 = Android emulator's alias for the host machine.
    default=["localhost", "127.0.0.1", "0.0.0.0", "web", "10.0.2.2"],
)

# Verbose, structured-ish logging in dev. Never log tokens/secrets.
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "simple": {"format": "[{levelname}] {name}: {message}", "style": "{"},
    },
    "handlers": {
        "console": {"class": "logging.StreamHandler", "formatter": "simple"},
    },
    "root": {"handlers": ["console"], "level": "INFO"},
}
