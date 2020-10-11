FROM gcr.io/gcp-runtimes/container-structure-test:v1.9.1 as container-structure-test

FROM docker:19.03.13-dind

# Build-time metadata as defined at https://github.com/opencontainers/image-spec
ARG DATE
ARG CURRENT_VERSION_MICRO
ARG COMMIT
ARG AUTHOR
ARG BATS_VERSION=0.4.0

LABEL \
    org.opencontainers.image.created=$DATE \
    org.opencontainers.image.url="https://hub.docker.com/r/pfillion/drone-dind" \
    org.opencontainers.image.source="https://github.com/pfillion/drone-dind" \
    org.opencontainers.image.version=$CURRENT_VERSION_MICRO \
    org.opencontainers.image.revision=$COMMIT \
    org.opencontainers.image.vendor="pfillion" \
    org.opencontainers.image.title="drone-dind" \
    org.opencontainers.image.description="Docker in Docker with more tools for Drone.io" \
    org.opencontainers.image.authors=$AUTHOR \
    org.opencontainers.image.licenses="MIT"

COPY --from=container-structure-test /container-structure-test ./bin/

RUN apk add --update --no-cache \
        git \
        make \
        bash \
    ; \
    # Install dependencies needed for installing Bats
    apk add --update --virtual build-dependencies \
        curl \
    ; \
    # Install Bats
    curl -sSL https://github.com/sstephenson/bats/archive/v${BATS_VERSION}.tar.gz -o /tmp/bats.tgz; \
    tar -zxf /tmp/bats.tgz -C /tmp; \
    /bin/bash /tmp/bats-${BATS_VERSION}/install.sh /usr/local; \
    # Cleanup
    rm -rf /tmp/*; \
    apk del build-dependencies