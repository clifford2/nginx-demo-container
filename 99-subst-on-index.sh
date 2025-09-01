#!/bin/sh

# SPDX-FileCopyrightText: © 2024 Clifford Weinmann <https://www.cliffordweinmann.com/>
#
# SPDX-License-Identifier: MIT-0

umask 022
COLOR=${COLOR:-'#333'}
test -d /usr/share/nginx/html || mkdir /usr/share/nginx/html
cp -p /usr/share/nginx/html-template/favicon.ico /usr/share/nginx/html/favicon.ico
cat /usr/share/nginx/html-template/50x.html > /usr/share/nginx/html/50x.html
timestamp=$(TZ=UTC date '+%Y-%m-%dT%H:%M:%SZ')
for ext in html json txt csv
do
	sed -e "s/{HOSTNAME}/$(hostname)/" -e "s/{CURRTIME}/${timestamp}/" -e "s/{COLOR}/${COLOR}/g" /usr/share/nginx/html-template/index.${ext} > /usr/share/nginx/html/index.${ext}
done
