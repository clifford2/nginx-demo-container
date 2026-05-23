# SPDX-FileCopyrightText: © 2024 Clifford Weinmann <https://www.cliffordweinmann.com/>
# SPDX-License-Identifier: MIT-0

# ARGs to be passed at build time:
#  ARG APP_VERSION="our code version"
#  ARG BUILD_TIME="RFC 3339 build time"
#  ARG GIT_REVISION="$(git rev-parse @)"

ARG NGINX_VERSION="1.31.1"
ARG ALPINE_VERSION="3.23"
ARG BASEIMAGE="docker.io/library/nginx:${NGINX_VERSION}-alpine${ALPINE_VERSION}-slim"
# UID & GID for nginx user in base image
ARG NGINX_UID="101"
ARG NGINX_GID="101"

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
# 2026-05-23: no longer needed, as we now copy a full config file
# RUN sed -i -e '/^}/i add_header Cache-Control "no-cache, no-store, must-revalidate";' /etc/nginx/conf.d/default.conf
# RUN sed -i -e '/^}/i add_header Expires 0;' /etc/nginx/conf.d/default.conf
# RUN sed -i -e '/^}/i add_header Pragma "no-cache";' /etc/nginx/conf.d/default.conf
# RUN sed -i -e '/^}/i etag off;' /etc/nginx/conf.d/default.conf

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
	jq --compact-output < /tmp/index.json > /usr/share/nginx/html-template/index.json && \
	rm /tmp/index.json


#----------------------------------------------------------------------#
#-# Final image
FROM ${BASEIMAGE}

USER root

# Install curl for testing the image - see build/test.sh.
# Also install any required security patches in this step
RUN /sbin/apk update && \
	/sbin/apk add curl && \
	rm -rf /var/cache/apk/*

ARG APP_VERSION
ARG BUILD_TIME
ARG GIT_REVISION
ARG NGINX_VERSION
ARG NGINX_UID
ARG NGINX_GID

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

# Add Nginx config files
COPY --chmod=0644 ./build/templates/nginx.conf /etc/nginx/nginx.conf
COPY --chmod=0644 ./build/templates/nginx-default.conf /etc/nginx/conf.d/default.conf

# Add our content
RUN echo 'Initializing templates' && \
	umask 022 && \
	mkdir -p /usr/share/nginx/html-template && \
	cp -p /usr/share/nginx/html/50x.html /usr/share/nginx/html-template/50x.html && \
	chown -R ${NGINX_UID}:${NGINX_UID} /usr/share/nginx/html
COPY --chmod=0755 build/templates/99-subst-on-index.sh /docker-entrypoint.d/99-subst-on-index.sh
COPY --from=templates --chmod=0644 --chown=${NGINX_UID}:${NGINX_UID} /usr/share/nginx/html/index.html /usr/share/nginx/html/index.html
COPY --from=templates --chmod=0644 /usr/share/nginx/html-template/ /usr/share/nginx/html-template/

EXPOSE 8080/tcp
STOPSIGNAL SIGQUIT

USER $NGINX_UID

# Necessary in case we're running the container with a read-only root filesystem
VOLUME ["/usr/share/nginx/html"]
