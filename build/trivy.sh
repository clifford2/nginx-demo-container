#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2026 Clifford Weinmann <https://www.cliffordweinmann.com/>
# SPDX-License-Identifier: MIT-0

# Latest as of 2026-09-05
trivy_image='docker.io/aquasec/trivy:0.74.0@sha256:62b1e65e8869bc4b4c6aa4fa2b21595256c7c2f6018a9d9ad61caf87187c1969'

CONTAINER_ENGINE="${CONTAINER_ENGINE:-podman}"
echo "trivy in [${CONTAINER_ENGINE}]"
if [ "${CONTAINER_ENGINE}" = "podman" ]
then
	my_uid="$(id -u)"
	if [ $my_uid -eq 0 ]
	then
		podman run --rm -v /run/podman/podman.sock:/var/run/podman/podman.sock:z -v ~/.cache/trivy:/root/.cache/:Z -v ./sbom:/sbom:Z ${trivy_image} $@ --podman-host /var/run/podman/podman.sock
	else
		if [ ! -S /run/user/${my_uid}/podman/podman.sock ]
		then
			echo "podman.sock for user ${my_uid} not found"
			exit 1
		fi
		podman run --rm -v /run/user/${my_uid}/podman/podman.sock:/var/run/podman/podman.sock:Z -v ~/.cache/trivy:/root/.cache/:Z -v ./sbom:/sbom:Z ${trivy_image} $@ --podman-host /var/run/podman/podman.sock
	fi
elif [ "${CONTAINER_ENGINE}" = "docker" ]
then
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock:z -v $HOME/.cache/trivy:/root/.cache/:Z -v ./sbom:/sbom:Z ${trivy_image} $@
else
	echo "Unknown container engine ${CONTAINER_ENGINE}"
	exit 1
fi
