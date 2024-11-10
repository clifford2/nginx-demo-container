#!/bin/sh
umask 022
test -d /usr/share/nginx/html || mkdir /usr/share/nginx/html
cat /usr/share/nginx/html-template/50x.html > /usr/share/nginx/html/50x.html
for ext in html txt json
do
	sed -e "s/{HOSTNAME}/$(hostname)/" /usr/share/nginx/html-template/index.${ext} > /usr/share/nginx/html/index.${ext}
done
