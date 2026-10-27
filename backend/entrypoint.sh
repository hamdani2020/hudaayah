#!/usr/bin/env bash
set -euo pipefail

# Wait for Postgres to accept connections before starting Django.
echo "Waiting for database at ${POSTGRES_HOST:-db}:${POSTGRES_PORT:-5432}..."
python - <<'PY'
import os, socket, time
host = os.environ.get("POSTGRES_HOST", "db")
port = int(os.environ.get("POSTGRES_PORT", "5432"))
for _ in range(60):
    try:
        with socket.create_connection((host, port), timeout=2):
            break
    except OSError:
        time.sleep(1)
else:
    raise SystemExit(f"Database {host}:{port} not reachable")
print("Database is up.")
PY

# Apply migrations on boot (idempotent) in dev.
python manage.py migrate --noinput

python manage.py collectstatic --noinput || true

exec "$@"
