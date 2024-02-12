# FROM docker.io/library/nginx:1.25.3-alpine3.18 # runs as root
FROM docker.io/nginxinc/nginx-unprivileged:1.25.3-alpine3.18
ARG UID=101 # UID for nginx user in base image
COPY index.html /usr/share/nginx/html/index.html
COPY 99-subst-on-index.sh /docker-entrypoint.d/99-subst-on-index.sh
USER root
RUN chmod 0644 /usr/share/nginx/html/index.html
RUN chmod 0755 /docker-entrypoint.d/99-subst-on-index.sh
RUN sed -i -e "s/{TIME}/$(TZ=UTC date '+%Y-%m-%dT%H:%M:%SZ')/" /usr/share/nginx/html/index.html
RUN chown 101 /usr/share/nginx/html /usr/share/nginx/html/index.html
USER 101
# EXPOSE 8080/tcp # Already done by base image
