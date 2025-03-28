# SPDX-FileCopyrightText: © 2024 Clifford Weinmann <https://www.cliffordweinmann.com/>
#
# SPDX-License-Identifier: MIT-0

# Config
# REPOBASE := ghcr.io/clifford2
REPOBASE := registry.h.c6d.xyz/clifford
IMGBASENAME := nginx-demo
DEVTAG := dev
DEVPORT := 8080

# Get current version (used in image tags and when bumping version numbers)
APP_VERSION := $(shell cat .version 2>/dev/null || echo '0.0.0-new')

# Construct image names
IMGBASETAG := $(REPOBASE)/$(IMGBASENAME)
IMGDEVTAG := $(IMGBASETAG):$(DEVTAG)
IMGRELTAG := $(IMGBASETAG):$(APP_VERSION)

# Use podman or docker?
ifeq ($(shell command -v podman 2> /dev/null),)
	CONTAINER_ENGINE := docker
else
	CONTAINER_ENGINE := podman
endif

ifeq ($(CONTAINER_ENGINE),podman)
	BUILDARCH := $(shell podman version --format '{{.Client.OsArch}}' | cut -d/ -f2)
	BUILD_NOLOAD := podman build
	BUILD_CMD := $(BUILD_NOLOAD)
else
	BUILDARCH := $(shell docker version --format '{{.Client.Arch}}')
	BUILD_NOLOAD := docker buildx build
	BUILD_CMD := $(BUILD_NOLOAD) --load
endif

.PHONY: all
all: help

.PHONY: help
help:
	@echo "No default target configured - please specify the desired target:"
	@echo "  build-dev:     Build development image ($(IMGDEVTAG))"
	@echo "  run-dev:       Run DEFAULT (red) development container on port $(DEVPORT)"
	@echo "  run-dev-blue:  Run BLUE development container on port $(DEVPORT)"
	@echo "  run-dev-green: Run GREEN development container on port $(DEVPORT)"
	@echo "  stop-dev:      Stop development container"
	@echo "  get-version:   Show current version number"
	@echo "  bump-version-{major,minor,patch}: Increment version"
	@echo "  git-tag:       Tag git repo with current version"
#	@echo "  build-release: Build release image ($(IMGRELTAG))"
	@echo "  run-release:   Run DEFAULT (red) release container on port $(DEVPORT)"
	@echo "  stop-release:  Stop release container"
#	@echo "  push-release:  Push release image ($(IMGRELTAG))"
	@echo ""
	@echo "We're using $(CONTAINER_ENGINE) on $(BUILDARCH)"
	@echo "Would build $(IMGRELTAG)"

.PHONY: get-imagename
get-imagename:
	@echo "$(IMGRELTAG)"

.PHONY: build-dev
build-dev:
	$(BUILD_CMD) -t $(IMGDEVTAG) .

.PHONY: run-dev
run-dev: build-dev
	$(CONTAINER_ENGINE) run --replace --rm -d -p $(DEVPORT):8080 --name $(IMGBASENAME) --memory-reservation 16m --memory-reservation 32m $(IMGDEVTAG)
	@echo "Access the container at http://0.0.0.0:$(DEVPORT)/"

.PHONY: run-dev-blue
run-dev-blue: build-dev
	$(CONTAINER_ENGINE) run --replace --rm -d -p $(DEVPORT):8080 --name $(IMGBASENAME) --memory-reservation 16m --memory-reservation 32m -e COLOR=blue $(IMGDEVTAG)
	@echo "Access the container at http://0.0.0.0:$(DEVPORT)/"

.PHONY: run-dev-green
run-dev-green: build-dev
	$(CONTAINER_ENGINE) run --replace --rm -d -p $(DEVPORT):8080 --name $(IMGBASENAME) --memory-reservation 16m --memory-reservation 32m -e COLOR=green $(IMGDEVTAG)
	@echo "Access the container at http://0.0.0.0:$(DEVPORT)/"

.PHONY: stop-dev
stop-dev:
	$(CONTAINER_ENGINE) stop $(IMGBASENAME)

# @echo 'No longer required - built by GitHub Action when pushing tagged commit'
# .PHONY: build-release
# build-release:
#	$(BUILD_CMD) -t $(IMGRELTAG) .
#	$(CONTAINER_ENGINE) tag $(IMGRELTAG) $(IMGBASETAG):latest

.PHONY: run-release
run-release: build-release
	$(CONTAINER_ENGINE) run --replace --rm -d -p $(DEVPORT):8080 --name $(IMGBASENAME) --memory-reservation 16m --memory-reservation 32m $(IMGRELTAG)
	@echo "Access the container at http://0.0.0.0:$(DEVPORT)/"

.PHONY: stop-release
stop-release:
	$(CONTAINER_ENGINE) stop $(IMGBASENAME)

# .PHONY: push-release
# push-release: build-release
#	$(CONTAINER_ENGINE) push $(IMGRELTAG)
#	$(CONTAINER_ENGINE) push $(IMGBASETAG):latest

.PHONY: get-version
get-version:
	@echo "$(APP_VERSION)"

.PHONY: bump-version-major
bump-version-major: install-semver
	@~/bin/semver bump major $(APP_VERSION) > .version
	@sh ./fix-doc-version.sh

.PHONY: bump-version-minor
bump-version-minor: install-semver
	@~/bin/semver bump minor $(APP_VERSION) > .version
	@sh ./fix-doc-version.sh

.PHONY: bump-version-patch
bump-version-patch: install-semver
	@~/bin/semver bump patch $(APP_VERSION) > .version
	@sh ./fix-doc-version.sh

.PHONY: git-tag
git-tag:
	@git tag -m "Version $(APP_VERSION)" $(APP_VERSION)

.PHONY: git-push
git-push:
	@git push --follow-tags


.PHONY: install-semver
install-semver:
	@test -d ~/bin || mkdir ~/bin
	@test -f ~/bin/semver || curl --location --output ~/bin/semver https://raw.githubusercontent.com/fsaintjacques/semver-tool/master/src/semver && chmod 0755 ~/bin/semver
