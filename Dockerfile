
FROM alpine
LABEL org.opencontainers.image.title="Docker Workshop" \
    org.opencontainers.image.description="Docker workshop" \
    org.opencontainers.image.vendor="Docker Inc" \
    com.docker.desktop.extension.api.version="0.3.4" \
    com.docker.extension.screenshots="" \
    com.docker.desktop.extension.icon="" \
    com.docker.extension.detailed-description="" \
    com.docker.extension.publisher-url="" \
    com.docker.extension.additional-urls="" \
    com.docker.extension.categories="" \
    com.docker.extension.changelog=""

COPY ui ui
COPY docker-compose.yaml .
COPY metadata.json .
COPY docker.svg .
