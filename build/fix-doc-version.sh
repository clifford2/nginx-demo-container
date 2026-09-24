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

# Generate YAML for each version
bash ../build/gen-k8s-deployment.sh \
	1 '' \
	1 'blue' \
	1 'green' > deployment-v1.yaml
bash ../build/gen-k8s-deployment.sh \
	2 'Bashful' \
	2 'Sneezy' \
	2 'Dopey' > deployment-v2.yaml
bash ../build/gen-k8s-deployment.sh \
	3 "Ah, you're an outcast! That's great, so are we! - Timon" \
	3 "They call me Mr. Pig! - Puumba" \
	3 "This is my kingdom. If I don't fight for it, who will? - Simba" > deployment-v3.yaml

# Generate a mixed-version file
cat > deployment-mixed.yaml <<- HEADER
# SPDX-FileCopyrightText: © 2026 Clifford Weinmann <https://www.cliffordweinmann.com/>
# SPDX-License-Identifier: MIT-0
#
# Deployments for 3 different image versions

HEADER
bash ../build/gen-k8s-deployment.sh \
	1 'blue' \
	2 'Sneezy' \
	3 'Dopey' >> deployment-mixed.yaml

# git add deployment-v1.yaml
# git add deployment-v2.yaml
# git add deployment-v3.yaml
