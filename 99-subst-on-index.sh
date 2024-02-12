#!/bin/sh
sed -i -e "s/{HOSTNAME}/$(hostname)/" /usr/share/nginx/html/index.html
