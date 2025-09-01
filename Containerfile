# SPDX-FileCopyrightText: © 2024 Clifford Weinmann <https://www.cliffordweinmann.com/>
#
# SPDX-License-Identifier: MIT-0

ARG NGINX_VERSION=1.29.1
ARG ALPINE_VERSION=3.22

FROM docker.io/nginxinc/nginx-unprivileged:${NGINX_VERSION}-alpine${ALPINE_VERSION}

LABEL maintainer="Clifford Weinmann <https://www.cliffordweinmann.com/>"
LABEL org.opencontainers.image.source https://github.com/clifford2/nginx-demo-container

ARG NGINX_VERSION
# Base image serves content of /usr/share/nginx/html on port 8080
# UID for nginx user in base image
ARG UID=101

# 2025-03-29: Patch the following vulnerabilities in docker.io/nginxinc/nginx-unprivileged:1.27.4-alpine3.21
# - CVE-2024-56171 libxml2: Use-After-Free in libxml2
# - CVE-2025-24928 libxml2: Stack-based buffer overflow in xmlSnprintfElements of libxml2
# - CVE-2025-27113 libxml2: NULL Pointer Dereference in libxml2 xmlPatMatch
# - CVE-2024-55549 libxslt: Use-After-Free in libxslt (xsltGetInheritedNsList)
# - CVE-2025-24855 libxslt: Use-After-Free in libxslt numbers.c
# - CVE-2024-8176 libexpat: expat: Improper Restriction of XML Entity Expansion Depth in libexpat
# RUN /sbin/apk add --no-cache libxml2=2.13.4-r5 libxslt=1.1.42-r2 libexpat=2.7.0-r0
# These versions are installed in the docker.io/nginxinc/nginx-unprivileged:1.28.0-alpine3.21 image

USER root
RUN /sbin/apk add --no-cache curl

# Add HTTP cache control headers
RUN sed -i -e '/^}/i add_header Cache-Control "no-cache, no-store, must-revalidate";' /etc/nginx/conf.d/default.conf
RUN sed -i -e '/^}/i add_header Expires 0;' /etc/nginx/conf.d/default.conf
RUN sed -i -e '/^}/i add_header Pragma "no-cache";' /etc/nginx/conf.d/default.conf
RUN sed -i -e '/^}/i etag off;' /etc/nginx/conf.d/default.conf

# Add our content
COPY --chmod=0755 99-subst-on-index.sh /docker-entrypoint.d/99-subst-on-index.sh
COPY --chmod=0644 templates/index.* .version images/favicon.ico /usr/share/nginx/html/

# Insert image details (version & build timestamp) into web pages.
# To allow us to mount the root file system read-only if desired, we will
# put our content in non-default location, and copy it to the correct location
# (mounted as read-write a volume) in an entrypoint script.
RUN echo 'Insert image details' \
	&& timestamp=$(TZ=UTC date '+%Y-%m-%dT%H:%M:%SZ') \
	&& ver=$(cat /usr/share/nginx/html/.version) \
	&& for ext in html json txt csv; do sed -i -e "s/{BUILDTIME}/${timestamp}/" -e "s/{APP_VERSION}/${ver}/" -e "s/{NGINX_VERSION}/${NGINX_VERSION}/" /usr/share/nginx/html/index.$ext; done \
	&& umask 022 \
	&& mv /usr/share/nginx/html /usr/share/nginx/html-template \
	&& mkdir /usr/share/nginx/html \
	&& chown $UID:$UID /usr/share/nginx/html

USER $UID
