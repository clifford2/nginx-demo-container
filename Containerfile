# FROM docker.io/library/nginx:1.26.0-alpine3.19 # runs as root
FROM docker.io/nginxinc/nginx-unprivileged:1.26.0-alpine-slim
ARG UID=101 # UID for nginx user in base image
COPY index.* /usr/share/nginx/html/
COPY 99-subst-on-index.sh /docker-entrypoint.d/99-subst-on-index.sh
USER root
RUN chmod 0644 /usr/share/nginx/html/index.*
RUN chmod 0755 /docker-entrypoint.d/99-subst-on-index.sh
RUN echo 'Insert timestamp' \
	&& timestamp=$(TZ=UTC date '+%Y-%m-%dT%H:%M:%SZ') \
	&& sed -i -e "s/{TIME}/${timestamp}/" /usr/share/nginx/html/index.html \
	&& sed -i -e "s/{TIME}/${timestamp}/" /usr/share/nginx/html/index.txt \
	&& sed -i -e "s/{TIME}/${timestamp}/" /usr/share/nginx/html/index.json
RUN chown 101 /usr/share/nginx/html /usr/share/nginx/html/index.*
USER 101
# EXPOSE 8080/tcp # Already done by base image
