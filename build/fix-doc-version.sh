#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2024 Clifford Weinmann <https://www.cliffordweinmann.com/>
#
# SPDX-License-Identifier: MIT-0

# Fix version number in doc

ver=$(cat .version)
test -z "${ver}" && exit 1
sed -i -e "s| ghcr.io/clifford2/nginx-demo.*$| ghcr.io/clifford2/nginx-demo:${ver}|" README.md
cd deploy || exit 1
if [ ! -f deploy/k8s-${ver}.yaml ]
then
	sed -e "s|version: .*$|version: \"${ver}\"|" -e "s|image: .*$|image: \"ghcr.io/clifford2/nginx-demo:${ver}\"|" k8s-latest.yaml > k8s-${ver}.yaml
	ln -fs k8s-${ver}.yaml k8s-latest.yaml
	git add k8s-${ver}.yaml
fi
