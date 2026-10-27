FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential libpq-dev curl \
    && rm -rf /var/lib/apt/lists/*

ARG REQUIREMENTS=development
COPY requirements/ ./requirements/
RUN pip install --upgrade pip && pip install -r requirements/${REQUIREMENTS}.txt

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
