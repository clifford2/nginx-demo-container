#!/bin/bash
# Build the container image & perform basic test

set -x

ver=$(cat .version)
podman build -t docker.io/cliffordw/nginx-demo:${ver} .

podman ps | grep -wq nginx-demo && podman stop nginx-demo
podman run --rm -d -p 8080:8080 --name nginx-demo docker.io/cliffordw/nginx-demo:${ver}
textver=$(curl --silent http://127.0.0.1:8080/index.txt | awk 'BEGIN {FS=":"} {if ($1 == "image_version") {print $2}}')
jsonver=$(curl --silent http://127.0.0.1:8080/index.json | jq '.image_version' -r)
xdg-open http://127.0.0.1:8080/index.html

if [ "$ver" != "$textver" ]
	echo "Something's wrong - expected version [$ver], got text version [$textver]"
	exit 1
fi

if [ "$ver" != "$jsonver" ]
then
	echo "Something's wrong - expected version [$ver], got text version [$jsonver]"
	exit 1
fi

sed -i -e "s|image: .*$|image: docker.io/cliffordw/nginx-demo:${ver}|" k8s.yaml
sed -i -e "s| docker.io/cliffordw/nginx-demo.*$| docker.io/cliffordw/nginx-demo:${ver}|" README.md
podman tag docker.io/cliffordw/nginx-demo:${ver} docker.io/cliffordw/nginx-demo:latest
echo "Build done"
