#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2024 Clifford Weinmann <https://www.cliffordweinmann.com/>
#
# SPDX-License-Identifier: MIT-0

# Fix version number in doc

ver=$(cat .version)
sed -i -e "s| ghcr.io/clifford2/nginx-demo.*$| ghcr.io/clifford2/nginx-demo:${ver}|" README.md
sed -i -e "s|version: .*$|version: ${ver}|" -e "s|image: .*$|image: ghcr.io/clifford2/nginx-demo:${ver}|" k8s-latest.yaml
test -f k8s-${ver}.yaml || cp k8s-latest.yaml k8s-${ver}.yaml
