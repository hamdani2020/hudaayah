#!/bin/sh
# Certbot service loop (run by the `certbot` container in docker-compose.prod.yml).
#
# Every 12h:
#   1) Issue a certificate for any extra web host that does not have a real one yet
#      (e.g. its DNS record was added after the last deploy). Needs LETSENCRYPT_EMAIL.
#   2) Renew every certificate that is close to expiry.
# nginx reloads hourly (infra/nginx/docker-entrypoint.sh), so new certs go live within
# an hour without a redeploy.
set -u

issue_missing() {
  name="$1"
  [ -n "$name" ] || return 0
  [ -f "/etc/letsencrypt/renewal/$name.conf" ] && return 0
  if [ -z "${LETSENCRYPT_EMAIL:-}" ]; then
    echo "renew-loop: no LETSENCRYPT_EMAIL; cannot issue a certificate for $name."
    return 0
  fi
  echo "renew-loop: issuing certificate for $name..."
  # Keep nginx's self-signed placeholder aside so certbot writes live/$name (not -0001),
  # and put it back if issuance fails so nginx can still reload.
  rm -rf "/tmp/placeholder-$name"
  [ -d "/etc/letsencrypt/live/$name" ] && mv "/etc/letsencrypt/live/$name" "/tmp/placeholder-$name"
  rm -rf "/etc/letsencrypt/archive/$name"
  if certbot certonly --webroot -w /var/www/certbot -d "$name" \
      --email "$LETSENCRYPT_EMAIL" --agree-tos --no-eff-email --non-interactive \
      --keep-until-expiring; then
    rm -rf "/tmp/placeholder-$name"
    echo "renew-loop: certificate for $name issued."
  else
    echo "renew-loop: certificate for $name failed; will retry in 12h."
    rm -rf "/etc/letsencrypt/live/$name"
    [ -d "/tmp/placeholder-$name" ] && mv "/tmp/placeholder-$name" "/etc/letsencrypt/live/$name"
  fi
}

trap exit TERM
while :; do
  for name in ${EXTRA_SERVER_NAMES:-}; do
    issue_missing "$name"
  done
  certbot renew --webroot -w /var/www/certbot --quiet
  sleep 12h & wait $!
done
