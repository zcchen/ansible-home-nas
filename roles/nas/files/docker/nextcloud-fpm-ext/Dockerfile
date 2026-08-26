ARG IMAGE="nextcloud:fpm"
FROM ${IMAGE}

ARG MIRROR_URL=""
RUN if [ -n "${MIRROR_URL}" ]; then \
        sed -i /etc/apt/sources.list.d/debian.sources -e "s#http://\([a-zA-Z0-9]\+\.*\)\{1,\}/#$MIRROR_URL#"; \
    fi


RUN apt update \
    && apt upgrade -y \
    && apt install -f -y \
        procps jq \
        ffmpeg \
        libsmbclient-dev \
    && rm -rf /var/lib/apt/lists/*

RUN pecl install smbclient \
    && docker-php-ext-enable smbclient \
    && apt purge -y libsmbclient-dev
