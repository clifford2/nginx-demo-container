#!/bin/sh
umask 022
COLOR=${COLOR:-'#a64893'}
test -d /usr/share/nginx/html || mkdir /usr/share/nginx/html
cat /usr/share/nginx/html-template/50x.html > /usr/share/nginx/html/50x.html
timestamp=$(TZ=UTC date '+%Y-%m-%dT%H:%M:%SZ')
for ext in html json txt csv
do
	sed -e "s/{HOSTNAME}/$(hostname)/" -e "s/{CURRTIME}/${timestamp}/" -e "s/{COLOR}/${COLOR}/g" /usr/share/nginx/html-template/index.${ext} > /usr/share/nginx/html/index.${ext}
done
