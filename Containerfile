# SPDX-FileCopyrightText: © 2024 Clifford Weinmann <https://www.cliffordweinmann.com/>
#
# SPDX-License-Identifier: MIT-0

# ARGs to be passed at build time:
#  ARG APP_VERSION="our code version"
#  ARG BUILD_TIME="RFC 3339 build time"
#  ARG GIT_REVISION="$(git rev-parse @)"

ARG NGINX_VERSION="1.29.3"
ARG BASEIMAGE="docker.io/nginxinc/nginx-unprivileged:${NGINX_VERSION}-alpine3.22-slim"
ARG ALPINE_VERSION="3.22"
# NGINX_UID for nginx user in base image
ARG NGINX_UID="101"

#----------------------------------------------------------------------#
#-# Customize content templates
FROM ${BASEIMAGE} AS templates

ARG APP_VERSION
ARG BUILD_TIME
ARG GIT_REVISION
ARG NGINX_VERSION
ARG NGINX_UID

USER root

# Install jq to minify index.json
RUN apk add --no-cache jq

# Add HTTP cache control headers
RUN sed -i -e '/^}/i add_header Cache-Control "no-cache, no-store, must-revalidate";' /etc/nginx/conf.d/default.conf
RUN sed -i -e '/^}/i add_header Expires 0;' /etc/nginx/conf.d/default.conf
RUN sed -i -e '/^}/i add_header Pragma "no-cache";' /etc/nginx/conf.d/default.conf
RUN sed -i -e '/^}/i etag off;' /etc/nginx/conf.d/default.conf

# Add our content
RUN echo 'Initializing templates' && \
	umask 022 && \
	mkdir -p /usr/share/nginx/html-template
COPY --chmod=0644 build/templates/index.* images/favicon.ico /usr/share/nginx/html-template/
COPY --chmod=0644 build/templates/default-index.html /usr/share/nginx/html/index.html
RUN sed -i -e "s/{NGINX_UID}/${NGINX_UID}/" /usr/share/nginx/html/index.html

# Insert image build details (version & timestamp) into web pages.
# Base image serves content of /usr/share/nginx/html.
# To allow us to mount the root file system read-only (security best practice),
# we will put our content in a non-default location, and copy it to the correct
# location (mounted as a read-write volume) in an entrypoint script.
RUN echo 'Insert image details' && \
	for ext in html json txt csv; do sed -i -e "s/{BUILD_TIME}/${BUILD_TIME}/" -e "s/{APP_VERSION}/${APP_VERSION}/" -e "s/{NGINX_VERSION}/${NGINX_VERSION}/" /usr/share/nginx/html-template/index.$ext; done && \
	sed -i -e "s/{GIT_REVISION}/${GIT_REVISION}/" /usr/share/nginx/html-template/index.json && \
	cp /usr/share/nginx/html-template/index.json /tmp/index.json && \
	jq -c < /tmp/index.json > /usr/share/nginx/html-template/index.json && \
	rm /tmp/index.json


#----------------------------------------------------------------------#
#-# Final image
FROM ${BASEIMAGE}

USER root

# 2025-12-18 - Patch vulnerabilities in docker.io/nginxinc/nginx-unprivileged:1.29.3-alpine3.22-slim
# - CVE-2024-58251 (Medium)
# - CVE-2025-46394 (Low)
RUN /sbin/apk add --no-cache busybox=1.37.0-r20

# Install curl for testing the image - see build/test.sh.
RUN /sbin/apk add --no-cache curl

ARG APP_VERSION
ARG BUILD_TIME
ARG GIT_REVISION
ARG NGINX_VERSION
ARG NGINX_UID

LABEL maintainer="Clifford Weinmann <https://www.cliffordweinmann.com/>"
LABEL org.opencontainers.image.authors="Clifford Weinmann <https://www.cliffordweinmann.com/>"
LABEL org.opencontainers.image.created="${BUILD_TIME}"
LABEL org.opencontainers.image.description="NGINX Demo"
LABEL org.opencontainers.image.licenses="MIT-0"
LABEL org.opencontainers.image.revision="${GIT_REVISION}"
LABEL org.opencontainers.image.source="https://github.com/clifford2/nginx-demo-container"
LABEL org.opencontainers.image.title="nginx-demo-container"
LABEL org.opencontainers.image.url="https://github.com/clifford2/nginx-demo-container"
LABEL org.opencontainers.image.version="${APP_VERSION}"

# Add HTTP cache control headers
COPY --from=templates /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf

# Add our content
RUN echo 'Initializing templates' && \
	umask 022 && \
	mkdir -p /usr/share/nginx/html-template && \
	cp -p /usr/share/nginx/html/50x.html /usr/share/nginx/html-template/50x.html && \
	chown -R ${NGINX_UID}:${NGINX_UID} /usr/share/nginx/html
COPY --chmod=0755 build/templates/99-subst-on-index.sh /docker-entrypoint.d/99-subst-on-index.sh
COPY --from=templates --chmod=0644 --chown=${NGINX_UID}:${NGINX_UID} /usr/share/nginx/html/index.html /usr/share/nginx/html/index.html
COPY --from=templates --chmod=0644 /usr/share/nginx/html-template/ /usr/share/nginx/html-template/

USER $NGINX_UID
VOLUME ["/usr/share/nginx/html"]
