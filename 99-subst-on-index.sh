#!/bin/sh
sed -i -e "s/{HOSTNAME}/$(hostname)/" /usr/share/nginx/html/index.html
sed -i -e "s/{HOSTNAME}/$(hostname)/" /usr/share/nginx/html/index.txt
sed -i -e "s/{HOSTNAME}/$(hostname)/" /usr/share/nginx/html/index.json
