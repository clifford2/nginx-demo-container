#!/bin/sh
umask 022
test -d /usr/share/nginx/html || mkdir /usr/share/nginx/html
for ext in html txt json
do
	sed -e "s/{HOSTNAME}/$(hostname)/" /usr/share/nginx/html-template/index.${ext} > /usr/share/nginx/html/index.${ext}
done
