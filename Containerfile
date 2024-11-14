FROM docker.io/nginxinc/nginx-unprivileged:1.27.2-alpine3.20
ARG UID=101 # UID for nginx user in base image
COPY --chmod=0644 index.* .version /usr/share/nginx/html/
COPY --chmod=0755 99-subst-on-index.sh /docker-entrypoint.d/99-subst-on-index.sh
USER root
RUN echo 'Insert timestamp & version' \
	&& timestamp=$(TZ=UTC date '+%Y-%m-%dT%H:%M:%SZ') \
	&& ver=$(cat /usr/share/nginx/html/.version) \
	&& sed -i -e "s/{BUILDTIME}/${timestamp}/" -e "s/{VERSION}/${ver}/" /usr/share/nginx/html/index.html \
	&& sed -i -e "s/{BUILDTIME}/${timestamp}/" -e "s/{VERSION}/${ver}/" /usr/share/nginx/html/index.txt \
	&& sed -i -e "s/{BUILDTIME}/${timestamp}/" -e "s/{VERSION}/${ver}/" /usr/share/nginx/html/index.json
# Move files elsewhere, so /usr/share/nginx/html/ can be mounted as a volume,
# and container root FS can be mounted read-only
RUN echo 'Handling permissions' \
	&& umask 022 \
	&& mv /usr/share/nginx/html /usr/share/nginx/html-template \
	&& mkdir /usr/share/nginx/html \
	&& chown $UID:$UID /usr/share/nginx/html
USER $UID
# EXPOSE 8080/tcp # Already done by base image
