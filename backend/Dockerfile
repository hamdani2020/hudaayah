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

EXPOSE 8000

# Invoke via bash so a bind-mount that drops the execute bit doesn't break boot.
ENTRYPOINT ["bash", "./entrypoint.sh"]
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
