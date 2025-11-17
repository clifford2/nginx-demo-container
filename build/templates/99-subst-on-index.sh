#!/bin/sh

# SPDX-FileCopyrightText: © 2024 Clifford Weinmann <https://www.cliffordweinmann.com/>
#
# SPDX-License-Identifier: MIT-0

umask 022
COLOR=${COLOR:-'#333'}
test -d /usr/share/nginx/html || mkdir -p /usr/share/nginx/html
cp /usr/share/nginx/html-template/favicon.ico /usr/share/nginx/html/favicon.ico
cat /usr/share/nginx/html-template/50x.html > /usr/share/nginx/html/50x.html
timestamp=$(TZ=UTC date '+%Y-%m-%dT%H:%M:%SZ')
for ext in html json txt csv
do
	sed -e "s/{HOSTNAME}/$(hostname)/" -e "s/{CURRTIME}/${timestamp}/" -e "s/{COLOR}/${COLOR}/g" /usr/share/nginx/html-template/index.${ext} > /usr/share/nginx/html/index.${ext}
done
# Creating this here, rather than in Containerfile, means a healthcheck
# will fail if /usr/share/nginx/html/ is not writable.
echo '{"status": "UP"}' > /usr/share/nginx/html/healthz.json
