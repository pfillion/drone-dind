FROM docker:18-dind

# Build-time metadata as defined at http://label-schema.org
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.name="Drone-dind" \
    org.label-schema.description="Docker in Docker with more tools for Drone.io" \
    org.label-schema.url="https://hub.docker.com/r/pfillion/drone-dind" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="https://github.com/pfillion/drone-dind" \
    org.label-schema.vendor="pfillion" \
    org.label-schema.version=$VERSION \
    org.label-schema.schema-version="1.0"

RUN apk add --update --no-cache \
    git \
    make

ENTRYPOINT ["dockerd-entrypoint.sh"]