FROM nginx:1.30.8-alpine@sha256:8eb04fe3b385090e9aa02961f77398ad09b6bf33ab07f6669a5bb7acce22c0d3

RUN apk upgrade --no-cache && apk add --no-cache openssl gettext

COPY hudaayah.conf.template /etc/nginx/templates/hudaayah.conf.template
COPY docker-entrypoint.sh /docker-entrypoint-hudaayah.sh
RUN chmod +x /docker-entrypoint-hudaayah.sh

RUN rm -f /etc/nginx/conf.d/default.conf

ENTRYPOINT ["/docker-entrypoint-hudaayah.sh"]
