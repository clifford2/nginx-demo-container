#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2024 Clifford Weinmann <https://www.cliffordweinmann.com/>
#
# SPDX-License-Identifier: MIT-0

# Fix version number in doc

ver=$(cat .version)
sed -i -e "s| ghcr.io/clifford2/nginx-demo.*$| ghcr.io/clifford2/nginx-demo:${ver}|" README.md
sed -i -e "s|version: .*$|version: ${ver}|" -e "s|image: .*$|image: ghcr.io/clifford2/nginx-demo:${ver}|" deploy/k8s-latest.yaml
test -f deploy/k8s-${ver}.yaml || cp deploy/k8s-latest.yaml deploy/k8s-${ver}.yaml
if [ -f deploy/k8s-homelab-latest.yaml ]
then
	sed -i -e "s|version: .*$|version: ${ver}|" -e "s|image: .*$|image: ghcr.io/clifford2/nginx-demo:${ver}|" deploy/k8s-homelab-latest.yaml
	test -f deploy/k8s-homelab-${ver}.yaml || cp deploy/k8s-homelab-latest.yaml deploy/k8s-homelab-${ver}.yaml
fi
