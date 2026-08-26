ARG IMAGE="certbot/dns-cloudflare:latest"
FROM ${IMAGE}

RUN apk update && \
    apk add --no-cache shadow su-exec docker-cli && \
    mkdir -p /var/log/letsencrypt && \
    chown 700 /var/log/letsencrypt && \
    rm -rf /var/cache/apk/*

ENV CERTBOT_DOMAINS="" \
    CERTBOT_EMAIL="" \
    CERTBOT_CERT_NAME="" \
    CERTBOT_KEY_TYPE="ecdsa" \
    CERTBOT_SERVER="https://acme-v02.api.letsencrypt.org/directory" \
    CLOUDFLARE_API_TOKEN="" \
    CLOUDFLARE_CREDENTIALS_FILE="/cloudflare.ini" \
    CLOUDFLARE_PROPAGATION_SECONDS="10" \
    DEBUG=false \
    PUID=0 \
    PGID=0 \
    RENEWAL_INTERVAL=43200 \
    RENEWAL_DEPLOY_HOOK=""
    # `CERTBOT_CERT_NAME` usually is the basename of the CERTBOT_DOMAINS.

COPY --chmod=700 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/sh", "-c", "/entrypoint.sh"]

HEALTHCHECK --interval=20s --timeout=15s --start-period=5s --retries=20 \
    CMD [ -f "/etc/letsencrypt/live/$(echo "$CERTBOT_DOMAINS" | cut -d',' -f1)/fullchain.pem" ]
