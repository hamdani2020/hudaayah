FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# System deps: build headers for psycopg if needed; curl for healthchecks.
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential libpq-dev curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python deps first (layer caching). REQUIREMENTS defaults to development.
ARG REQUIREMENTS=development
COPY requirements/ ./requirements/
RUN pip install --upgrade pip && pip install -r requirements/${REQUIREMENTS}.txt

COPY . .

RUN chmod +x ./entrypoint.sh

# Collect static files into STATIC_ROOT at build time so the WhiteNoise manifest
# (staticfiles.json) exists before gunicorn boots. collectstatic only needs settings
# to import — not the real secret/DB — so dummy values satisfy production.py's
# env requirements; the collected output is identical regardless of their values.
# This is a no-op when REQUIREMENTS=development (dev settings), which is harmless.
RUN DJANGO_SETTINGS_MODULE=config.settings.production \
    DJANGO_SECRET_KEY=build-time-dummy \
    DJANGO_ALLOWED_HOSTS=localhost \
    DJANGO_SECURE_SSL_REDIRECT=false \
    python manage.py collectstatic --noinput

EXPOSE 8000

# Invoke via bash so a bind-mount that drops the execute bit doesn't break boot.
ENTRYPOINT ["bash", "./entrypoint.sh"]
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
