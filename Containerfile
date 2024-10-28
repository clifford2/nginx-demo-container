# FROM docker.io/library/nginx:1.27.2-alpine3.20 # runs as root
FROM docker.io/nginxinc/nginx-unprivileged:1.27.2-alpine3.20
ARG UID=101 # UID for nginx user in base image
COPY index.* .version /usr/share/nginx/html/
COPY 99-subst-on-index.sh /docker-entrypoint.d/99-subst-on-index.sh
COPY .version /tmp/.version
USER root
RUN chmod 0644 /usr/share/nginx/html/index.*
RUN chmod 0755 /docker-entrypoint.d/99-subst-on-index.sh
RUN echo 'Insert timestamp & version' \
	&& timestamp=$(TZ=UTC date '+%Y-%m-%dT%H:%M:%SZ') \
	&& ver=$(cat /usr/share/nginx/html/.version) \
	&& sed -i -e "s/{TIME}/${timestamp}/" -e "s/{VERSION}/${ver}/" /usr/share/nginx/html/index.html \
	&& sed -i -e "s/{TIME}/${timestamp}/" -e "s/{VERSION}/${ver}/" /usr/share/nginx/html/index.txt \
	&& sed -i -e "s/{TIME}/${timestamp}/" -e "s/{VERSION}/${ver}/" /usr/share/nginx/html/index.json
RUN chown $UID /usr/share/nginx/html /usr/share/nginx/html/index.*
USER 101
# EXPOSE 8080/tcp # Already done by base image
