# Nginx reverse proxy + TLS terminator for the Hudaayah backend.
# Adds openssl (temporary self-signed cert on first boot) and gettext (envsubst for the
# config template). The config template and entrypoint are baked in; SERVER_NAME is
# supplied at runtime via the environment.
# Pinned to an immutable digest (multi-arch index). Dependabot proposes updates.
FROM nginx:1.27-alpine@sha256:65645c7bb6a0661892a8b03b89d0743208a18dd2f3f17a54ef4b76fb8e2f2a10

RUN apk add --no-cache openssl gettext

COPY hudaayah.conf.template /etc/nginx/templates/hudaayah.conf.template
COPY docker-entrypoint.sh /docker-entrypoint-hudaayah.sh
RUN chmod +x /docker-entrypoint-hudaayah.sh

# Default server config shipped by the image conflicts with ours on :80 — remove it.
RUN rm -f /etc/nginx/conf.d/default.conf

ENTRYPOINT ["/docker-entrypoint-hudaayah.sh"]
