FROM gcr.io/gcp-runtimes/container-structure-test:latest as container-structure-test

FROM docker:19-dind

# Build-time metadata as defined at http://label-schema.org
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
ARG BATS_VERSION=0.4.0

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

 COPY --from=container-structure-test /docker-credential-gcr /container-structure-test ./bin/

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