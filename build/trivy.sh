#!/usr/bin/env bash

# Latest as of 2026-04-22
trivy_image='docker.io/aquasec/trivy:0.70.0@sha256:be1190afcb28352bfddc4ddeb71470835d16462af68d310f9f4bca710961a41e'

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
