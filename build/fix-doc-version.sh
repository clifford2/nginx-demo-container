#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2024 Clifford Weinmann <https://www.cliffordweinmann.com/>
#
# SPDX-License-Identifier: MIT-0

# Fix version number in doc

ver=$(bash $(dirname $0)/getver patch 3)
test -z "${ver}" && exit 1
sed -i \
 -e "s| ghcr.io/clifford2/nginx-demo.*$| ghcr.io/clifford2/nginx-demo:${ver}|" \
 README.md

# Generate deployment YAML files

cd $(dirname $0)/../deploy || exit 1
# v1
ver=$(bash ../build/getver patch 1)
bash ../build/gen-k8s-deployment-v1.sh $ver > deployment-v1.yaml
git add deployment-v1.yaml
# v2 & v3
for major in 2 3
do
	ver=$(bash ../build/getver patch $major)
	bash ../build/gen-k8s-deployment-v2.sh $ver > deployment-v${major}.yaml
	git add deployment-v${major}.yaml
done
