# SPDX-FileCopyrightText: © 2024 Clifford Weinmann <https://www.cliffordweinmann.com/>
# SPDX-License-Identifier: MIT-0

### Config ###
# Set REGISTRY value to login during "make push-release"
# REGISTRY := registry.example.com
# Set REPOBASE value to image base name (excluding "/$(IMGBASENAME):tag" suffix) for "make push-release"
# REPOBASE := $(REGISTRY)/mynamespace
# Public image (REPOBASE := ghcr.io/clifford2) is built by GitHub Action
REPOBASE := ghcr.io/clifford2
IMGBASENAME := nginx-demo
DEVTAG := dev
DEVPORT := 8080

# Get current version (used in image tags and when bumping version numbers)
APP_VERSION := $(shell cat .version 2>/dev/null || echo '0.0.0-new')
BUILD_TIME := $(shell TZ=UTC date '+%Y-%m-%dT%H:%M:%SZ')
GIT_REVISION := $(shell git rev-parse @)

# Construct image names
IMGDEVTAG := localhost/$(IMGBASENAME):$(DEVTAG)
IMGRELNAME := $(REPOBASE)/$(IMGBASENAME)
IMGRELTAG := $(IMGRELNAME):$(APP_VERSION)

# Use podman or docker?
ifeq ($(shell command -v podman 2> /dev/null),)
	CONTAINER_ENGINE := docker
else
	CONTAINER_ENGINE := podman
endif

ifeq ($(CONTAINER_ENGINE),podman)
	BUILDARCH := $(shell podman version --format '{{.Client.OsArch}}' | cut -d/ -f2)
	BUILD_NOLOAD := podman build --build-arg=APP_VERSION="$(APP_VERSION)" --build-arg=BUILD_TIME="$(BUILD_TIME)" --build-arg=GIT_REVISION="$(GIT_REVISION)"
	BUILD_CMD := $(BUILD_NOLOAD)
	DIGEST_CMD := podman inspect --format "{{.Digest}}"
	RUN_CMD := podman run --replace
else
	BUILDARCH := $(shell docker version --format '{{.Client.Arch}}')
	BUILD_NOLOAD := docker buildx build -f Containerfile --build-arg=APP_VERSION="$(APP_VERSION)" --build-arg=BUILD_TIME="$(BUILD_TIME)" --build-arg=GIT_REVISION="$(GIT_REVISION)"
	BUILD_CMD := $(BUILD_NOLOAD) --load
	DIGEST_CMD := docker inspect --format "{{.Id}}"
	RUN_CMD := docker run
endif

# Default target: show typical targets
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
	@echo "Release steps:"
	@echo ""
	@echo "  make lint:           Check for YAML syntax errors"
	@echo "  make bump-version-{major,minor,patch}: Increment version"
	@echo "  git commit -a:       Commit changes to version control"
	@echo "  make git-tag-push:   Tag git repo with current version & push"
	@echo ""
	@echo "Optional release targets:"
	@echo ""
	@echo "  build-release:  Build release image ($(IMGRELTAG)) (also done by GitHub Actions)"
	@echo "  push-release:   Push release image ($(IMGRELTAG))"
	@echo "  run-release:    Run DEFAULT release container on port $(DEVPORT)"
	@echo "  stop-release:   Stop release container"
	@echo ""
	@echo "We're using $(CONTAINER_ENGINE) on $(BUILDARCH)"
	@echo "Would build version $(APP_VERSION)"
	@echo "DEV image: $(IMGDEVTAG)"
	@echo "RELEASE image: $(IMGRELTAG)"

# Show app version
.PHONY: get-version
get-version:
	@echo "$(APP_VERSION)"

# Show calculated DEV image name
.PHONY: get-dev-image-name
get-dev-image-name:
	@echo "$(IMGRELTAG)"

# Show calculated RELEASE image name
.PHONY: get-release-image-name
get-release-image-name:
	@echo "$(IMGDEVTAG)"

# Get sha256 digest for latest DEV image
.PHONY: get-dev-image-digest
get-dev-image-digest:
	@$(DIGEST_CMD) $(IMGDEVTAG)

# Get sha256 digest for latest RELEASE image
.PHONY: get-release-image-digest
get-release-image-digest:
	@$(DIGEST_CMD) $(IMGRELTAG)

# Build DEV image
.PHONY: build-dev
build-dev:
	$(BUILD_CMD) -t $(IMGDEVTAG) .

# Get text-based output from running DEV container
.PHONY: .get-text-content
.get-text-content:
	@echo ""
	@echo "JSON content:"
	@echo ""
	@curl --silent http://127.0.0.1:8080/index.json | jq '' || true
	@echo ""
	@echo "TXT content:"
	@echo ""
	@curl --silent http://127.0.0.1:8080/index.txt || true
	@echo ""
	@echo "CSV content:"
	@echo ""
	@curl --silent http://127.0.0.1:8080/index.csv || true

# Run DEV instance with default colour
.PHONY: run-dev
run-dev:
	$(RUN_CMD) --rm -d -p $(DEVPORT):8080 --name $(IMGBASENAME) --memory-reservation 16m --memory-reservation 32m $(IMGDEVTAG)
	@echo "The container should be accessible at http://0.0.0.0:$(DEVPORT)/"

# Run DEV instance with blue-ish colour
.PHONY: run-dev-blue
run-dev-blue:
	$(RUN_CMD) --rm -d -p $(DEVPORT):8080 --name $(IMGBASENAME) --memory-reservation 16m --memory-reservation 32m -e COLOR='#1F63E0' $(IMGDEVTAG)
	@echo "The container should be accessible at http://0.0.0.0:$(DEVPORT)/"

# Run DEV instance with green-ish colour
.PHONY: run-dev-green
run-dev-green:
	$(RUN_CMD) --rm -d -p $(DEVPORT):8080 --name $(IMGBASENAME) --memory-reservation 16m --memory-reservation 32m -e COLOR='#3BC639' $(IMGDEVTAG)
	@echo "The container should be accessible at http://0.0.0.0:$(DEVPORT)/"

# Run DEV instance with green-ish colour
.PHONY: run-dev-red
run-dev-red:
	$(RUN_CMD) --rm -d -p $(DEVPORT):8080 --name $(IMGBASENAME) --memory-reservation 16m --memory-reservation 32m -e COLOR='#B44B4C' $(IMGDEVTAG)
	@echo "The container should be accessible at http://0.0.0.0:$(DEVPORT)/"

# Stop DEV container
.PHONY: stop-dev
stop-dev:
	$(CONTAINER_ENGINE) stop $(IMGBASENAME)

# Run tests against DEV image
.PHONY: test-dev
test-dev: .check-test-deps build-dev
	@make --quiet run-dev
	@bash ./build/test.sh "http://0.0.0.0:$(DEVPORT)"
	@make --quiet stop-dev
	@test "$(CONTAINER_ENGINE)" = "podman" && systemctl --user start podman.socket
	@command -v trivy && trivy image $(IMGDEVTAG) || echo "Trivy not found - not scanning image"

# Start DEV instance & show results
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

# Build RELEASE image
.PHONY: build-release
build-release:
	$(BUILD_CMD) -t $(IMGRELTAG) .

# Pull RELEASE image from GHCR
.PHONY: pull-release
pull-release:
	$(CONTAINER_ENGINE) pull $(IMGRELTAG)

# Start RELEASE container
.PHONY: run-release
run-release: pull-release
	$(RUN_CMD) --rm -d -p $(DEVPORT):8080 --name $(IMGBASENAME) --memory-reservation 16m --memory-reservation 32m $(IMGRELTAG)
	@echo "The container should be accessible at http://0.0.0.0:$(DEVPORT)/"

# Stop RELEASE container
.PHONY: stop-release
stop-release:
	$(CONTAINER_ENGINE) stop $(IMGBASENAME)

# Run tests against RELEASE image
.PHONY: test-release
test-release: .check-test-deps
	make --quiet run-release
	bash ./build/test.sh "http://0.0.0.0:$(DEVPORT)"
	make --quiet stop-release
	test "$(CONTAINER_ENGINE)" = "podman" && systemctl --user start podman.socket || echo "No need to start podman socket"
	command -v trivy && trivy image $(IMGDEVTAG) || echo "Trivy not found - not scanning image"

# Build & push RELEASE image
.PHONY: push-release
push-release:
	test ! -z "$(REGISTRY)" && $(CONTAINER_ENGINE) login $(REGISTRY)
	$(CONTAINER_ENGINE) push $(IMGRELTAG)
	$(CONTAINER_ENGINE) tag $(IMGRELTAG) $(IMGRELNAME):$(shell cat .version | cut -d- -f1 | cut -d. -f1-2)
	# tag with major.minor version
	$(CONTAINER_ENGINE) push $(IMGRELNAME):$(shell cat .version | cut -d- -f1 | cut -d. -f1-2)
	$(CONTAINER_ENGINE) tag $(IMGRELTAG) $(IMGRELNAME):$(shell cat .version | cut -d- -f1 | cut -d. -f1)
	# tag with major version
	$(CONTAINER_ENGINE) push $(IMGRELNAME):$(shell cat .version | cut -d- -f1 | cut -d. -f1)
	$(CONTAINER_ENGINE) tag $(IMGRELTAG) $(IMGRELNAME):latest
	$(CONTAINER_ENGINE) push $(IMGRELNAME):latest

# Syntax check source code
.PHONY: lint
lint: .check-lint-depends
	@yamllint .github/workflows/build-image.yaml
	@yamllint deploy/k8s-latest.yaml
	@yamllint deploy/openshift-route.yaml

# Increment APP_VERSION major version number
.PHONY: bump-version-major
bump-version-major: .check-ver-deps lint
	@~/bin/semver bump major $(APP_VERSION) > .version
	@bash ./build/fix-doc-version.sh

# Increment APP_VERSION minor version number
.PHONY: bump-version-minor
bump-version-minor: .check-ver-deps
	@~/bin/semver bump minor $(APP_VERSION) > .version
	@bash ./build/fix-doc-version.sh

# Increment APP_VERSION patch version number
.PHONY: bump-version-patch
bump-version-patch: .check-ver-deps
	@~/bin/semver bump patch $(APP_VERSION) > .version
	@bash ./build/fix-doc-version.sh

# git tag with current APP_VERSION
.PHONY: .git-tag
.git-tag: .check-git-deps lint
	@git tag -m "Version $(APP_VERSION)" $(APP_VERSION)

# git push
.PHONY: .git-push
.git-push: .check-git-deps
	@git push --follow-tags

# git tag & push
.PHONY: git-tag-push
git-tag-push: .git-tag .git-push

# Verify that we have git installed
.PHONY: .check-git-deps
.check-git-deps:
	command -v git

# Install semver script if not present
.PHONY: .install-semver
.install-semver:
	@test -d ~/bin || mkdir ~/bin
	@test -f ~/bin/semver || curl --location --output ~/bin/semver https://raw.githubusercontent.com/fsaintjacques/semver-tool/master/src/semver && chmod 0755 ~/bin/semver

# Verify that we have dependencies for versioning targets installed
.PHONY: .check-ver-deps
.check-ver-deps: .install-semver
	test -f /usr/bin/env
	command -v bash
	command -v cat
	command -v sed

# Verify that we have dependencies for testing targets installed
.PHONY: .check-test-deps
.check-test-deps: .check-ver-deps
	command -v awk
	command -v curl
	command -v jq

# Verify that we have dependencies for syntax checks
.PHONY: .check-lint-depends
.check-lint-depends:
	command -v yamllint

# Verify that we have all required dependencies installed
.PHONY: check-depends
check-depends: .check-git-deps .check-test-deps .check-lint-depends
	command -v podman || command -v docker
	command -v curl
	command -v git
	command -v trivy
	command -v jq
