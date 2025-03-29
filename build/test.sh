#!/bin/bash

# SPDX-FileCopyrightText: © 2024 Clifford Weinmann <https://www.cliffordweinmann.com/>
#
# SPDX-License-Identifier: MIT-0

# Build the container image & perform basic test
# set -x

ver=$(cat .version)

# podman build -t docker.io/cliffordw/nginx-demo:${ver} .
# podman ps | grep -wq nginx-demo && podman stop nginx-demo
# podman run --rm -d -p 8080:8080 --name nginx-demo docker.io/cliffordw/nginx-demo:${ver}

make run-dev
jsonver=$(curl --silent http://127.0.0.1:8080/index.json | jq '.image_version' -r)
textver=$(curl --silent http://127.0.0.1:8080/index.txt | awk 'BEGIN {FS=":"} {if ($1 == "image_version") {print $2}}')
csvver=$(curl --silent http://127.0.0.1:8080/index.csv | awk 'BEGIN {FS=","} {if ($1 == "\"image_version\"") {print $2}}' | sed -e 's/"//g' -e 's/\r//')
xdg-open http://127.0.0.1:8080/index.html 2>/dev/null

if [ "$ver" != "$jsonver" ]
then
	echo "ERROR: expected version [$ver], got JSON version [$jsonver]"
	exit 1
else
	echo "OK: JSON version"
fi

if [ "$ver" != "$textver" ]
then
	echo "ERROR: expected version [$ver], got text version [$textver]"
	exit 1
else
	echo "OK: text version"
fi

if [ "$ver" != "$csvver" ]
then
	echo "ERROR: expected version [$ver], got CSV version [$csvver]"
	exit 1
else
	echo "OK: csv version"
fi

sh ./fix-doc-version.sh

# podman tag docker.io/cliffordw/nginx-demo:${ver} docker.io/cliffordw/nginx-demo:latest
make build-release

echo "Build done"
