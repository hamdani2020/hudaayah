#!/usr/bin/env bash
# Hudaayah production deploy — version-controlled, run on the EC2 instance via SSM.
#
# Flow: sync source -> build app.env from SSM Parameter Store -> docker compose up
#       -> issue/renew TLS cert -> migrate -> seed pilot content.
#
# Config comes from /opt/hudaayah/deploy.env (written once by Terraform user-data):
#   AWS_REGION, GIT_REPO_URL, GIT_BRANCH, SSM_PREFIX, SERVER_NAME, LETSENCRYPT_EMAIL
#
# Usage:  deploy.sh [git-ref]      (ref defaults to GIT_BRANCH)
#
# This script lives in the repo (infra/deploy/deploy.sh). user-data symlinks it to
# /opt/hudaayah/deploy.sh and re-runs it on every SSM-triggered deploy, so edits here
# take effect on the next deploy WITHOUT recreating the instance.
set -euo pipefail

# --- Load per-instance config --------------------------------------------------
DEPLOY_ENV="${DEPLOY_ENV:-/opt/hudaayah/deploy.env}"
if [ -f "$DEPLOY_ENV" ]; then
  # shellcheck disable=SC1090
  . "$DEPLOY_ENV"
fi

: "${AWS_REGION:?AWS_REGION not set (expected in $DEPLOY_ENV)}"
: "${GIT_REPO_URL:?GIT_REPO_URL not set}"
: "${GIT_BRANCH:?GIT_BRANCH not set}"
: "${SSM_PREFIX:?SSM_PREFIX not set}"
: "${SERVER_NAME:?SERVER_NAME not set}"
: "${LETSENCRYPT_EMAIL:?LETSENCRYPT_EMAIL not set}"

APP_DIR="${APP_DIR:-/opt/hudaayah/app}"
APP_ENV_FILE="${APP_ENV_FILE:-/opt/hudaayah/app.env}"
COMPOSE_FILE="infra/deploy/docker-compose.prod.yml"
REF="${1:-$GIT_BRANCH}"

export SERVER_NAME APP_ENV_FILE   # consumed by the compose file

# --- 1) Sync source -------------------------------------------------------------
if [ ! -d "$APP_DIR/.git" ]; then
  git clone --branch "$GIT_BRANCH" "$GIT_REPO_URL" "$APP_DIR"
fi
git -C "$APP_DIR" fetch --all --prune
git -C "$APP_DIR" checkout "$GIT_BRANCH"
git -C "$APP_DIR" reset --hard "origin/$REF" 2>/dev/null || git -C "$APP_DIR" reset --hard "$REF"

cd "$APP_DIR"

compose() { docker compose -f "$COMPOSE_FILE" "$@"; }

# --- 2) Build runtime env file from SSM Parameter Store -------------------------
: > "$APP_ENV_FILE"
chmod 600 "$APP_ENV_FILE"
for param in $(aws ssm get-parameters-by-path \
      --region "$AWS_REGION" \
      --path "$SSM_PREFIX" \
      --with-decryption \
      --recursive \
      --query 'Parameters[].Name' --output text); do
  key="${param##*/}"
  value="$(aws ssm get-parameter --region "$AWS_REGION" --name "$param" --with-decryption --query 'Parameter.Value' --output text)"
  printf '%s=%s\n' "$key" "$value" >> "$APP_ENV_FILE"
done

# --- 3) Build + start the stack -------------------------------------------------
# nginx boots with a self-signed cert if no real one exists (see infra/nginx), so it
# can serve the ACME HTTP-01 challenge on :80. `</dev/null` detaches stdin so detached
# containers don't hold the SSM command's stdio open (which would keep it InProgress).
compose up -d --build </dev/null

# --- 4) Issue/renew Let's Encrypt cert (idempotent) -----------------------------
if ! compose run --rm --entrypoint sh certbot -c \
      "test -f /etc/letsencrypt/renewal/$SERVER_NAME.conf && openssl x509 -checkend 86400 -noout -in /etc/letsencrypt/live/$SERVER_NAME/cert.pem" 2>/dev/null; then
  echo "Requesting/renewing Let's Encrypt certificate for $SERVER_NAME..."
  compose run --rm --entrypoint sh certbot -c \
    "rm -rf /etc/letsencrypt/live/$SERVER_NAME /etc/letsencrypt/archive/$SERVER_NAME /etc/letsencrypt/renewal/$SERVER_NAME.conf" || true
  compose run --rm --entrypoint certbot certbot certonly \
    --webroot -w /var/www/certbot \
    -d "$SERVER_NAME" \
    --email "$LETSENCRYPT_EMAIL" \
    --agree-tos --no-eff-email --non-interactive \
    --keep-until-expiring \
    && compose exec -T nginx nginx -s reload
fi

# --- 5) Migrations --------------------------------------------------------------
# Static files are collected into the shared staticfiles volume by web's entrypoint.
compose exec -T web python manage.py migrate --noinput

# --- 5b) Seed + publish pilot lessons (idempotent) ------------------------------
# Pre-live QF provides surah 1 (Al-Fatihah) and surah 2 (Al-Baqarah) only.
# Non-fatal: a seed failure must not abort an otherwise-good rollout.
compose exec -T web python manage.py seed_al_fatihah --publish \
  || echo "WARNING: seed Al-Fatihah failed; continuing."
compose exec -T web python manage.py seed_al_fatihah --file al_baqarah.json --publish \
  || echo "WARNING: seed Al-Baqarah failed; continuing."

# --- 6) Prune dangling images ---------------------------------------------------
docker image prune -f
