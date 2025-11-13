# SPDX-FileCopyrightText: © 2024 Clifford Weinmann <https://www.cliffordweinmann.com/>
# SPDX-License-Identifier: MIT-0

### Config ###
# Public image (REPOBASE := ghcr.io/clifford2) is built by GitHub Action
# Set REGISTRY value to login during "make push-release"
# REGISTRY := registry.example.com
# Set REPOBASE value to image base name (excluding "/$(IMGBASENAME):tag" suffix) for "make push-release"
# REPOBASE := $(REGISTRY)/mynamespace
REPOBASE := localhost
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

.PHONY: help
help:
	@echo "No default target configured - please specify the desired target:"
	@echo ""
	@echo "Development targets:"
	@echo ""
	@echo "normal cycle:"
	@echo "  check-depends:  Verify that all external dependencies are available"
	@echo "  build-dev:      Build development image ($(IMGDEVTAG))"
	@echo "  test-dev:       Test the development image (Trivy, curl)"
	@echo "  open-dev:       Run development container & open in browser"
	@echo "  stop-dev:       Stop development container"
	@echo "additional testing:"
	@echo "  run-dev:        Run DEFAULT (no colour override) development container on port $(DEVPORT)"
	@echo "  run-dev-blue:   Run BLUE development container on port $(DEVPORT)"
	@echo "  run-dev-green:  Run GREEN development container on port $(DEVPORT)"
	@echo "  run-dev-red:    Run RED development container on port $(DEVPORT)"
	@echo ""
	@echo "Release targets:"
	@echo ""
	@echo "  bump-version-{major,minor,patch}: Increment version"
	@echo "  # git commit -a"
	@echo "  git-tag-push:   Tag git repo with current version & push"
	@echo ""
	@echo "Optional release targets:"
	@echo ""
	@echo "  build-release:  Build release image ($(IMGRELTAG)) (also done by GitHub Actions)"
	@echo "  push-release:   Push release image ($(IMGRELTAG))"
	@echo "  run-release:    Run DEFAULT release container on port $(DEVPORT)"
	@echo "  stop-release:   Stop release container"
	@echo ""
	@echo "Utility targets:"
	@echo ""
	@echo "  get-version:    Show current version number"
	@echo ""
	@echo "We're using $(CONTAINER_ENGINE) on $(BUILDARCH)"
	@echo "Would build $(IMGRELTAG)"

.PHONY: get-imagename
get-imagename:
	@echo "$(IMGRELTAG)"

.PHONY: build-dev
build-dev:
	$(BUILD_CMD) -t $(IMGDEVTAG) .

.PHONY: .get-text-content
.get-text-content:
	@echo ""
	@echo "JSON content:"
	@echo ""
	@curl --silent http://127.0.0.1:8080/index.json | jq ''
	@echo ""
	@echo "TXT content:"
	@echo ""
	@curl --silent http://127.0.0.1:8080/index.txt
	@echo ""
	@echo "CSV content:"
	@echo ""
	@curl --silent http://127.0.0.1:8080/index.csv

.PHONY: run-dev
run-dev:
	$(CONTAINER_ENGINE) run --replace --rm -d -p $(DEVPORT):8080 --name $(IMGBASENAME) --memory-reservation 16m --memory-reservation 32m $(IMGDEVTAG)
	@echo "The container should be accessible at http://0.0.0.0:$(DEVPORT)/"

.PHONY: run-dev-blue
run-dev-blue:
	$(CONTAINER_ENGINE) run --replace --rm -d -p $(DEVPORT):8080 --name $(IMGBASENAME) --memory-reservation 16m --memory-reservation 32m -e COLOR='#1F63E0' $(IMGDEVTAG)
	@echo "The container should be accessible at http://0.0.0.0:$(DEVPORT)/"

.PHONY: run-dev-green
run-dev-green:
	$(CONTAINER_ENGINE) run --replace --rm -d -p $(DEVPORT):8080 --name $(IMGBASENAME) --memory-reservation 16m --memory-reservation 32m -e COLOR='#3BC639' $(IMGDEVTAG)
	@echo "The container should be accessible at http://0.0.0.0:$(DEVPORT)/"

.PHONY: run-dev-red
run-dev-red:
	$(CONTAINER_ENGINE) run --replace --rm -d -p $(DEVPORT):8080 --name $(IMGBASENAME) --memory-reservation 16m --memory-reservation 32m -e COLOR='#B44B4C' $(IMGDEVTAG)
	@echo "The container should be accessible at http://0.0.0.0:$(DEVPORT)/"

.PHONY: stop-dev
stop-dev:
	$(CONTAINER_ENGINE) stop $(IMGBASENAME)

.PHONY: test-dev
test-dev: .check-test-deps build-dev
	@test "$(CONTAINER_ENGINE)" = "podman" && systemctl --user start podman.socket
	@command -v trivy && trivy image $(IMGDEVTAG) || echo "Trivy not found - not scanning image"
	@make --quiet run-dev
	@bash ./build/test.sh
	@make --quiet stop-dev

.PHONY: open-dev
open-dev: run-dev .get-text-content
	@command -v xdg-open > /dev/null && (xdg-open http://0.0.0.0:$(DEVPORT)/index.html 2>/dev/null) || echo "Please open http://0.0.0.0:$(DEVPORT)/index.html manually in your browser"

.PHONY: open-dev-blue
open-dev-blue: run-dev-blue .get-text-content
	@command -v xdg-open > /dev/null && (xdg-open http://0.0.0.0:$(DEVPORT)/index.html 2>/dev/null) || echo "Please open http://0.0.0.0:$(DEVPORT)/index.html manually in your browser"

.PHONY: open-dev-green
open-dev-green: run-dev-green .get-text-content
	@command -v xdg-open > /dev/null && (xdg-open http://0.0.0.0:$(DEVPORT)/index.html 2>/dev/null) || echo "Please open http://0.0.0.0:$(DEVPORT)/index.html manually in your browser"

.PHONY: open-dev-red
open-dev-red: run-dev-red .get-text-content
	@command -v xdg-open > /dev/null && (xdg-open http://0.0.0.0:$(DEVPORT)/index.html 2>/dev/null) || echo "Please open http://0.0.0.0:$(DEVPORT)/index.html manually in your browser"

.PHONY: build-release
build-release:
	$(BUILD_CMD) -t $(IMGRELTAG) .

.PHONY: run-release
run-release: build-release
	$(CONTAINER_ENGINE) run --replace --rm -d -p $(DEVPORT):8080 --name $(IMGBASENAME) --memory-reservation 16m --memory-reservation 32m $(IMGRELTAG)
	@echo "The container should be accessible at http://0.0.0.0:$(DEVPORT)/"

.PHONY: stop-release
stop-release:
	$(CONTAINER_ENGINE) stop $(IMGBASENAME)

.PHONY: push-release
push-release: build-release
	test ! -z "$(REGISTRY)" && $(CONTAINER_ENGINE) login $(REGISTRY)
	$(CONTAINER_ENGINE) push $(IMGRELTAG)
	$(CONTAINER_ENGINE) tag $(IMGRELTAG) $(IMGBASETAG):latest
	$(CONTAINER_ENGINE) push $(IMGBASETAG):latest

.PHONY: get-version
get-version:
	@echo "$(APP_VERSION)"

.PHONY: bump-version-major
bump-version-major: .check-ver-deps
	@~/bin/semver bump major $(APP_VERSION) > .version
	@bash ./build/fix-doc-version.sh

.PHONY: bump-version-minor
bump-version-minor: .check-ver-deps
	@~/bin/semver bump minor $(APP_VERSION) > .version
	@bash ./build/fix-doc-version.sh

.PHONY: bump-version-patch
bump-version-patch: .check-ver-deps
	@~/bin/semver bump patch $(APP_VERSION) > .version
	@bash ./build/fix-doc-version.sh

.PHONY: .git-tag
.git-tag: .check-git-deps
	@git tag -m "Version $(APP_VERSION)" $(APP_VERSION)

.PHONY: .git-push
.git-push: .check-git-deps
	@git push --follow-tags

.PHONY: git-tag-push
git-tag-push: .git-tag .git-push

# Install semver script if not present
.PHONY: .install-semver
.install-semver:
	@test -d ~/bin || mkdir ~/bin
	@test -f ~/bin/semver || curl --location --output ~/bin/semver https://raw.githubusercontent.com/fsaintjacques/semver-tool/master/src/semver && chmod 0755 ~/bin/semver

# Verify that we have git installed
.PHONY: .check-git-deps
.check-git-deps:
	@command -v git

# Verify that we have dependencies for versioning targets installed
.PHONY: .check-ver-deps
.check-ver-deps: .install-semver
	test -f /usr/bin/env
	@command -v bash
	@command -v cat
	@command -v sed

# Verify that we have dependencies for testing targets installed
.PHONY: .check-test-deps
.check-test-deps: .check-ver-deps
	@command -v awk
	@command -v curl
	@command -v jq

# Verify that we have all required dependencies installed
.PHONY: check-depends
check-depends: .check-test-deps .check-git-deps
	@command -v podman || command -v docker
	@command -v curl
	@command -v git
	@command -v trivy
	@command -v jq
