FROM ubuntu:16.04

MAINTAINER Skepickle

RUN DEBIAN_FRONTEND=noninteractive set -x \
    && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget libterm-readkey-perl libterm-readline-gnu-perl \
    && rm -rf /var/lib/apt/lists/*

ENV GOSU_VERSION 1.9
RUN set -x \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

RUN useradd -d /pm -m -c "PocketMine-MP Base" pm -s /bin/bash
RUN su - pm -c "set -x \
                && wget -q -O - https://raw.githubusercontent.com/PocketMine/php-build-scripts/master/installer.sh | bash -s -"
RUN userdel pm

RUN mkdir /pm_data
VOLUME /pm_data

COPY src/entrypoint.sh /tmp
RUN chmod +x /tmp/entrypoint.sh

COPY src/wrapper.pl /tmp
RUN chmod +x /tmp/wrapper.pl

EXPOSE 19132/udp
EXPOSE 19132/tcp

ENTRYPOINT ["/tmp/entrypoint.sh"]

