# SPDX-FileCopyrightText: © 2024 Clifford Weinmann <https://www.cliffordweinmann.com/>
# SPDX-License-Identifier: MIT-0

# ARGs to be passed at build time:
#  ARG APP_VERSION="our code version"
#  ARG BUILD_TIME="RFC 3339 build time"
#  ARG GIT_REVISION="$(git rev-parse @)"

ARG NGINX_VERSION="1.31.2"
ARG BASEIMAGE=docker.io/library/alpine:3.23.4
ARG NGINX_UID="101"
ARG NGINX_GID="101"

#----------------------------------------------------------------------#
#-# Base Nginx image
# Based on https://nginx.org/en/linux_packages.html
FROM ${BASEIMAGE} AS nginx

RUN apk add --no-cache openssl curl ca-certificates curl gettext-envsubst tzdata

RUN echo '@nginx https://nginx.org/packages/mainline/alpine/v3.23/main' >> /etc/apk/repositories
RUN echo 'Import nginx signing key' \
	&& curl -o /tmp/nginx_signing.rsa.pub https://nginx.org/keys/nginx_signing.rsa.pub \
	&& echo "e09fa32f0a0eab2b879ccbbc4d0e4fb9751486eedda75e35fac65802cc9faa266425edf83e261137a2f4d16281ce2c1a5f4502930fe75154723da014214f0655 */tmp/nginx_signing.rsa.pub" | sha512sum -c - \
	&& mv /tmp/nginx_signing.rsa.pub /etc/apk/keys/

ARG NGINX_UID
ARG NGINX_GID
RUN addgroup -g ${NGINX_GID} -S nginx \
	&& adduser -S -D -H -u ${NGINX_UID} -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx

ARG NGINX_VERSION
RUN apk add "nginx@nginx=~${NGINX_VERSION}"

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log \
	&& mkdir /docker-entrypoint.d

# Files from https://github.com/nginx/docker-nginx
COPY --chmod=0755 build/templates/docker-entrypoint.sh /
COPY --chmod=0755 build/templates/10-listen-on-ipv6-by-default.sh /docker-entrypoint.d/
COPY --chmod=0755 build/templates/15-local-resolvers.envsh /docker-entrypoint.d/
COPY --chmod=0755 build/templates/20-envsubst-on-templates.sh /docker-entrypoint.d/
COPY --chmod=0755 build/templates/30-tune-worker-processes.sh /docker-entrypoint.d/

ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 8080/tcp
STOPSIGNAL SIGQUIT
CMD ["nginx", "-g", "daemon off;"]

#----------------------------------------------------------------------#
#-# Customize content templates
FROM nginx AS templates

ARG APP_VERSION
ARG BUILD_TIME
ARG GIT_REVISION
ARG NGINX_VERSION
ARG NGINX_UID

USER root

# Install jq to minify index.json
RUN apk add --no-cache jq

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
FROM nginx

USER root

# RUN /sbin/apk update && /sbin/apk upgrade && rm -rf /var/cache/apk/*

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
