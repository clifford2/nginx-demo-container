# SPDX-FileCopyrightText: © 2024 Clifford Weinmann <https://www.cliffordweinmann.com/>
#
# SPDX-License-Identifier: BSD-2-Clause

FROM docker.io/nginxinc/nginx-unprivileged:1.27.3-alpine3.20

# Base image serves content of /usr/share/nginx/html on port 8080
# UID for nginx user in base image
ARG UID=101

# Add our content
COPY --chmod=0755 99-subst-on-index.sh /docker-entrypoint.d/99-subst-on-index.sh
COPY --chmod=0644 index.* .version /usr/share/nginx/html/

# Insert image details (version & build timestamp) into web pages.
# To allow us to mount the root file system read-only if desired, we will
# put our content in non-default location, and copy it to the correct location
# (mounted as read-write a volume) in an entrypoint script.
USER root
RUN echo 'Insert image details' \
	&& timestamp=$(TZ=UTC date '+%Y-%m-%dT%H:%M:%SZ') \
	&& ver=$(cat /usr/share/nginx/html/.version) \
	&& for ext in html json txt csv; do sed -i -e "s/{BUILDTIME}/${timestamp}/" -e "s/{VERSION}/${ver}/" /usr/share/nginx/html/index.$ext; done \
	&& umask 022 \
	&& mv /usr/share/nginx/html /usr/share/nginx/html-template \
	&& mkdir /usr/share/nginx/html \
	&& chown $UID:$UID /usr/share/nginx/html

# Address CVE-2024-11053 (curl netrc password leak)
RUN /sbin/apk add --no-cache curl=8.11.1-r0

USER $UID
