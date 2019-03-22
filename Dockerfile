FROM alpine:3.6

LABEL maintainer="Daniel Sullivan <https://github.com/mumblepins>"

ARG SYSLOG_VERSION="3.12.1"
ARG BUILD_CORES=2

RUN apk add --no-cache \
    glib \
    pcre \
    eventlog \
    openssl \
    tini \
    && apk add --no-cache --virtual .build-deps \
    curl \
    alpine-sdk \
    glib-dev \
    pcre-dev \
    eventlog-dev \
    openssl-dev \
    && set -ex \
    && cd /tmp \
    && curl -sSL "https://github.com/balabit/syslog-ng/releases/download/syslog-ng-${SYSLOG_VERSION}/syslog-ng-${SYSLOG_VERSION}.tar.gz" \
        | tar xz \
    && cd "syslog-ng-${SYSLOG_VERSION}" \
    && ./configure -q --prefix=/usr \
    && make -j $BUILD_CORES \
    && make install \
    && rm -rf /tmp/* \
    && apk del --no-cache .build-deps \
    && mkdir -p /etc/syslog-ng /var/run/syslog-ng /var/log/syslog-ng

#COPY ./etc /etc/
COPY syslog-ng.conf startup.sh /app/

RUN chmod +x /app/startup.sh

# Build-time metadata as defined at http://label-schema.org
ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL
ARG VERSION

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="syslog-ng-alpine" \
      org.label-schema.description="Minimal Syslog Build on Alpine" \
      org.label-schema.url="https://hub.docker.com/r/mumblepins/syslog-ng-alpine/" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url=$VCS_URL \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0" \
      org.label-schema.docker.cmd="docker run -d -p 514:514/udp -v /var/log/syslog-ng:/var/log/syslog-ng --name syslog-ng mumblepins/syslog-ng-alpine"

VOLUME ["/var/log/syslog-ng", "/var/run/syslog-ng", "/etc/syslog-ng"]

EXPOSE 514/udp 601/tcp 6514/tcp

ENTRYPOINT ["tini", "--"]

CMD ["/bin/sh", "-c", "/app/startup.sh && exec /usr/sbin/syslog-ng -F -f /etc/syslog-ng/syslog-ng.conf"]
