#!/bin/bash

# SPDX-FileCopyrightText: © 2024 Clifford Weinmann <https://www.cliffordweinmann.com/>
#
# SPDX-License-Identifier: BSD-2-Clause

# Fix version number in doc

ver=$(cat .version)
sed -i -e "s|version: .*$|version: ${ver}|" -e "s|image: .*$|image: docker.io/cliffordw/nginx-demo:${ver}|" k8s.yaml
sed -i -e "s| docker.io/cliffordw/nginx-demo.*$| docker.io/cliffordw/nginx-demo:${ver}|" README.md
