# Pinned to an immutable digest (multi-arch index). Dependabot proposes updates.
FROM python:3.13-slim@sha256:7249d5587b78209a006dc4a3b5340678f84ea729239193aa559962cd8c1fce50

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# `apt-get upgrade` pulls Debian security fixes released after the base image was
# built (e.g. libzstd1 deb13u1).
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends build-essential libpq-dev curl \
    && rm -rf /var/lib/apt/lists/*

ARG REQUIREMENTS=development
COPY requirements/ ./requirements/
# The base image ships setuptools 70.3.0 (CVE-2025-47273); upgrade it with pip.
RUN pip install --upgrade pip "setuptools>=78.1.1" \
    && pip install -r requirements/${REQUIREMENTS}.txt

COPY . .

RUN chmod +x ./entrypoint.sh

RUN DJANGO_SETTINGS_MODULE=config.settings.production \
    DJANGO_SECRET_KEY=build-time-dummy \
    DJANGO_ALLOWED_HOSTS=localhost \
    DJANGO_SECURE_SSL_REDIRECT=false \
    python manage.py collectstatic --noinput

EXPOSE 8000

ENTRYPOINT ["bash", "./entrypoint.sh"]
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
