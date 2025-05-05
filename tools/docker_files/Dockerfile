# base = debian + full apt update + ca-certificates for any https connections to work at all
FROM debian:stable-slim AS base

# Global env variables
ENV BYOND_MAJOR=516
ENV BYOND_MINOR=1662
ENV DME_FILE=baystation12.dme
ENV DMB_FILE=baystation12.dmb
ENV SERVER_PORT=14076
# Keep true if you're running Windows, false if you're on Linux, see docker-entrypoint.sh
ENV VOLUMES_FILESYSTEM_WORKAROUND=true

RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates


# byond = base + byond installed globally
FROM base AS byond

WORKDIR /byond

RUN apt-get install -y --no-install-recommends \
        curl \
        unzip \
        make \
        libstdc++6:i386

# Note that manual tweaking of the Makefile is required because BYOND is trying to link man pages to a missing folder
RUN curl "http://www.byond.com/download/build/${BYOND_MAJOR}/${BYOND_MAJOR}.${BYOND_MINOR}_byond_linux.zip" -o byond.zip \
    && unzip byond.zip \
    && cd byond \
    && sed -i 's|install:|&\n\tmkdir -p $(MAN_DIR)/man6|' Makefile \
    && make install \
    && chmod 644 /usr/local/byond/man/man6/* \
    && apt-get purge -y --auto-remove curl unzip make \
    && cd .. \
    && rm -rf byond byond.zip


# build = byond + zeroonyx compiled
FROM byond AS build

RUN groupadd -r spessmans \
    && useradd -r -g spessmans -m -s /sbin/nologin spessman

COPY --chown=spessman:spessmans . /home/spessman/zeroonyx

WORKDIR /home/spessman/zeroonyx

USER spessman

RUN DreamMaker $DME_FILE


# final = build isolated and started as a non-root user
FROM build

USER spessman

# Create these by default for compatibility with the windows workaround
# For Linux hosts, /config and /data should be mounted directly to /home/spessman/zeroonyx
VOLUME ["/ss13config", "/ss13data"]

EXPOSE $SERVER_PORT

ENTRYPOINT ["./docker-entrypoint.sh"]
