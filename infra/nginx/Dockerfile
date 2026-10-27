# Nginx reverse proxy + TLS terminator for the Hudaayah backend.
# Adds openssl (temporary self-signed cert on first boot) and gettext (envsubst for the
# config template). The config template and entrypoint are baked in; SERVER_NAME is
# supplied at runtime via the environment.
FROM nginx:1.27-alpine

RUN apk add --no-cache openssl gettext

COPY hudaayah.conf.template /etc/nginx/templates/hudaayah.conf.template
COPY docker-entrypoint.sh /docker-entrypoint-hudaayah.sh
RUN chmod +x /docker-entrypoint-hudaayah.sh

# Default server config shipped by the image conflicts with ours on :80 — remove it.
RUN rm -f /etc/nginx/conf.d/default.conf

ENTRYPOINT ["/docker-entrypoint-hudaayah.sh"]
