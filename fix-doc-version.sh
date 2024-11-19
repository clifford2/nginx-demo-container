#!/bin/bash
# Fix version number in doc

ver=$(cat .version)
sed -i -e "s|image: .*$|image: docker.io/cliffordw/nginx-demo:${ver}|" k8s.yaml
sed -i -e "s| docker.io/cliffordw/nginx-demo.*$| docker.io/cliffordw/nginx-demo:${ver}|" README.md
