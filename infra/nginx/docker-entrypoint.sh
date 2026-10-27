#!/usr/bin/env sh
# Nginx container entrypoint for the Hudaayah backend.
#
# 1) Render the config template with the real SERVER_NAME.
# 2) If no TLS cert exists yet (first boot, before Let's Encrypt has issued one), drop in
#    a temporary self-signed cert so nginx can start and answer the ACME HTTP-01 challenge
#    on port 80. The certbot container then issues the real cert into the shared volume
#    and this container is reloaded, picking up the real cert.
# 3) Reload nginx every 6h so renewed certs are picked up without a restart.
set -eu

SERVER_NAME="${SERVER_NAME:?SERVER_NAME must be set}"
LIVE_DIR="/etc/letsencrypt/live/${SERVER_NAME}"

# 1) Render config.
export SERVER_NAME
envsubst '${SERVER_NAME}' \
  < /etc/nginx/templates/hudaayah.conf.template \
  > /etc/nginx/conf.d/hudaayah.conf

# 2) Self-signed placeholder so nginx can bind 443 before the real cert exists.
if [ ! -f "${LIVE_DIR}/fullchain.pem" ]; then
    echo "No certificate for ${SERVER_NAME} yet — generating a temporary self-signed cert."
    mkdir -p "${LIVE_DIR}"
    openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
        -keyout "${LIVE_DIR}/privkey.pem" \
        -out "${LIVE_DIR}/fullchain.pem" \
        -subj "/CN=${SERVER_NAME}" >/dev/null 2>&1
fi

# 3) Periodic reload loop (background) to pick up renewed certs.
(
    while true; do
        sleep 21600
        nginx -s reload 2>/dev/null || true
    done
) &

exec nginx -g 'daemon off;'
