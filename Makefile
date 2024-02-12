# Image values
REGISTRY := docker.io
PROJECT := cliffordw
IMAGE := nginx-demo
IMAGE_REF := $(REGISTRY)/$(PROJECT)/$(IMAGE)
TAG := 1.0.1

# Git commit hash
HASH := $(shell git rev-parse --short HEAD)

build:
	podman build -f Containerfile -t $(IMAGE_REF):$(TAG) .
	podman tag $(IMAGE_REF):$(TAG) $(IMAGE_REF):latest

push:
	podman push --remove-signatures $(IMAGE_REF):$(TAG)
	podman push --remove-signatures $(IMAGE_REF):latest
