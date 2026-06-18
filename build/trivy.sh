#!/usr/bin/env bash

# SPDX-FileCopyrightText: © 2026 Clifford Weinmann <https://www.cliffordweinmann.com/>
# SPDX-License-Identifier: MIT-0

# Latest as of 2026-04-22
trivy_image='docker.io/aquasec/trivy:0.70.1@sha256:53570e6911c2361ebe7995228088cf83a6b9b73e7f3cdca44bd8f8f425e80fa7'

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
