#metaBox Uploader - Based on PhysK Release

# Lightweight Linux Node base
FROM alpine:latest
LABEL maintainer="metaBox <contact@metabox.cloud>"
LABEL build="0.0.1-Alpha"

# Install certifacates, required dependencies
RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories && \
    apk update && apk upgrade && \
    apk add --no-cache \
        ca-certificates \
        logrotate \
        shadow \
        bash \
        bc \
        findutils \
        coreutils \
        openssl \
        php7 \
        php7-fpm \
        php7-mysqli \
        php7-json \
        php7-openssl \
        php7-curl \
        php7-zlib \
        php7-xml \
        php7-phar \
        php7-dom \
        php7-xmlreader \
        php7-ctype \
        php7-mbstring \
        php7-gd \
        curl \
        nginx \
		htop \
		iftop \
		nethogs \
        libxml2-utils

# InstalL s6 overlay
RUN wget https://github.com/just-containers/s6-overlay/releases/download/v1.21.4.0/s6-overlay-amd64.tar.gz -O s6-overlay.tar.gz && \
    tar xfv s6-overlay.tar.gz -C / && \
    rm -r s6-overlay.tar.gz

# Install Unionfs
RUN apk add --update --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing mergerfs && \
    sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf

# Add volumes
VOLUME [ "/unionfs" ]
VOLUME [ "/config" ]
VOLUME [ "/move" ]

# Install RCLONE
RUN wget https://downloads.rclone.org/rclone-current-linux-amd64.zip -O rclone.zip && \
    unzip rclone.zip && rm rclone.zip && \
    mv rclone*/rclone /usr/bin && rm -r rclone* && \
    chown 911:911 /unionfs && \
    chown 911:911 /config && \
    chown -hR 911:911 /move && \
    chown -hR 911:911 /mnt

# Add user
RUN addgroup -g 911 abc && \
    adduser -u 911 -D -G abc abc

# Copy Files to root
COPY root/ /

# Install Uploader
RUN cd /app && \
    chmod +x tdrive/uploader.sh && \
    chmod +x tdrive/upload.sh && \
    chmod +x mergerfs.sh && \
    chmod +x debug.sh && \
    chown 911:911 tdrive/uploader.sh && \
    chown 911:911 tdrive/upload.sh && \
    chown 911:911 mergerfs.sh && \
    chown 911:911 debug.sh

#Install Uploader UI
RUN mkdir -p /html
COPY --chown=abc html/ /var/www/html
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY config/php.ini /etc/php7/conf.d/zzz_custom.ini
EXPOSE 80

ENV ADDITIONAL_IGNORES=null

HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8110/fpm-ping
# Setup EntryPoint
ENTRYPOINT [ "/init" ]
