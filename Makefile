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
DEVTAG_BASE := dev
DEVPORT := 8080

# Get info used in image labels
BUILD_TIME := $(shell TZ=UTC date '+%Y-%m-%dT%H:%M:%SZ')
GIT_REVISION := $(shell git rev-parse @)

# Construct image names
IMGDEVTAG_BASE := localhost/$(IMGBASENAME):$(DEVTAG_BASE)
IMGRELNAME := $(REPOBASE)/$(IMGBASENAME)

# Use podman or docker?
ifeq ($(shell command -v podman 2> /dev/null),)
	CONTAINER_ENGINE := docker
else
	CONTAINER_ENGINE := podman
endif

ifeq ($(CONTAINER_ENGINE),podman)
	BUILDARCH := $(shell podman version --format '{{.Client.OsArch}}' | cut -d/ -f2)
	BUILD_NOLOAD := podman build --build-arg=BUILD_TIME="$(BUILD_TIME)" --build-arg=GIT_REVISION="$(GIT_REVISION)"
	BUILD_CMD := $(BUILD_NOLOAD)
	DIGEST_CMD := podman inspect --format "{{.Digest}}"
	RUN_CMD := podman run --replace
else
	BUILDARCH := $(shell docker version --format '{{.Client.Arch}}')
	BUILD_NOLOAD := docker buildx build -f Containerfile --build-arg=BUILD_TIME="$(BUILD_TIME)" --build-arg=GIT_REVISION="$(GIT_REVISION)"
	BUILD_CMD := $(BUILD_NOLOAD) --load --read-only
	DIGEST_CMD := docker inspect --format "{{.Id}}"
	RUN_CMD := docker run --read-only
endif

# Default target: show typical targets
.PHONY: help
help:
	@echo "No default target configured - please specify the desired target:"
	@echo ""
	@echo "Development targets:"
	@echo ""
	@echo "normal cycle:"
	@echo "  check-depends:      Verify that all external dependencies are available"
	@echo "  build-dev-v[123]:   Build development image"
	@echo "  test-dev-v[123]:    Test the development image (Trivy, curl)"
	@echo "  open-dev-v[123]:    Run development container & open in browser"
	@echo "  stop-dev:           Stop development container"
	@echo "additional testing:"
	@echo "  run-dev-v[123]:     Run development container on port $(DEVPORT)"
	@echo ""
	@echo "Release steps:"
	@echo ""
	@echo "  reuse lint:         Check license compliance"
	@echo "  make bump-version-{minor,patch}: Increment container image version"
	@echo "  # Commit before build to get correct GIT commit tag into image"
	@echo "  git add . && git commit: Commit changes to version control (need tag for build)"
	@echo "  make build-release: Build release image"
	@echo "  make test-release:  Test the release image (Trivy, curl)"
	@echo "  make sbom-release:  Generate Trivy SBOM & commit to source"
	@echo "  make git-tag-push:  Tag git repo with current version & push"
	@echo "  make push-release:  Push release image"
	@echo ""
	@echo "Optional release targets:"
	@echo ""
	@echo "  lint:               Check for YAML syntax errors"
	@echo "  run-release-v[123]: Run DEFAULT release container on port $(DEVPORT)"
	@echo "  stop-release:       Stop release container"
	@echo ""
	@echo "We're using $(CONTAINER_ENGINE) on $(BUILDARCH)"
	@echo "Would build version $(shell ./build/getver patch '<majorversion>')"
	@echo "DEV image: $(IMGDEVTAG_BASE)-v<majorversion>"
	@echo "RELEASE images: $(IMGRELNAME):$(shell ./build/getver patch '<majorversion>')"

# Get sha256 digest for latest DEV image
.PHONY: get-dev-image-digests
get-dev-image-digests:
	for major in $$(bash ./build/getver majors); \
	do \
	IMGDEVTAG="$(IMGDEVTAG_BASE)-v$${major}"; \
	echo "Image $${IMGDEVTAG} digest:"; \
	$(DIGEST_CMD) $${IMGDEVTAG}; \
	done

# Get sha256 digest for latest RELEASE image
.PHONY: get-release-image-digests
get-release-image-digests:
	@for major in $$(bash ./build/getver majors); \
	do \
	IMGRELTAG="$(IMGRELNAME):$$(bash ./build/getver patch $${major})"; \
	echo "Image $${IMGRELTAG} digest:"; \
	$(DIGEST_CMD) $${IMGRELTAG}; \
	done

# Build DEV v1 image
.PHONY: build-dev-v1
build-dev-v1: MAJOR_VERSION := 1
build-dev-v1: APP_VERSION := $(shell build/getver patch $(MAJOR_VERSION))
build-dev-v1: IMGDEVTAG := $(IMGDEVTAG_BASE)-v$(MAJOR_VERSION)
build-dev-v1: .build-dev

# Build DEV v2 image
.PHONY: build-dev-v2
build-dev-v2: MAJOR_VERSION := 2
build-dev-v2: APP_VERSION := $(shell build/getver patch $(MAJOR_VERSION))
build-dev-v2: IMGDEVTAG := $(IMGDEVTAG_BASE)-v$(MAJOR_VERSION)
build-dev-v2: .build-dev

# Build DEV v3 image
.PHONY: build-dev-v3
build-dev-v3: MAJOR_VERSION := 3
build-dev-v3: APP_VERSION := $(shell build/getver patch $(MAJOR_VERSION))
build-dev-v3: IMGDEVTAG := $(IMGDEVTAG_BASE)-v$(MAJOR_VERSION)
build-dev-v3: .build-dev

# Build DEV image
.PHONY: .build-dev
.build-dev:
	$(BUILD_CMD) --build-arg=MAJOR_VERSION="$(MAJOR_VERSION)" --build-arg=APP_VERSION="$(APP_VERSION)" -t $(IMGDEVTAG) .

# Get text-based output from running DEV container
.PHONY: .get-text-content
.get-text-content:
	@bash ./build/wait.sh
	@echo ""
	@echo "JSON content:"
	@echo ""
	@curl --silent http://127.0.0.1:$(DEVPORT)/index.json | jq '' || true
	@echo ""
	@echo "TXT content:"
	@echo ""
	@curl --silent http://127.0.0.1:$(DEVPORT)/index.txt || true
	@echo ""
	@echo "CSV content:"
	@echo ""
	@curl --silent http://127.0.0.1:$(DEVPORT)/index.csv || true

# Run DEV v1 instance with default colour
.PHONY: run-dev-v1
run-dev-v1: MAJOR_VERSION := 1
run-dev-v1: IMGDEVTAG := $(IMGDEVTAG_BASE)-v$(MAJOR_VERSION)
run-dev-v1: .run-dev

# Run DEV v2 instance with default colour
.PHONY: run-dev-v2
run-dev-v2: MAJOR_VERSION := 2
run-dev-v2: IMGDEVTAG := $(IMGDEVTAG_BASE)-v$(MAJOR_VERSION)
run-dev-v2: .run-dev

# Run DEV v3 instance with default colour
.PHONY: run-dev-v3
run-dev-v3: MAJOR_VERSION := 3
run-dev-v3: IMGDEVTAG := $(IMGDEVTAG_BASE)-v$(MAJOR_VERSION)
run-dev-v3: .run-dev

# Run DEV instance with default colour
.PHONY: .run-dev
.run-dev:
	$(RUN_CMD) --rm -d -p 127.0.0.1:$(DEVPORT):8080 --name $(IMGBASENAME) --memory-reservation 16m --memory-reservation 32m -e MESSAGE="Dev" $(IMGDEVTAG)
	@echo "The container should be accessible at http://0.0.0.0:$(DEVPORT)/"

# Stop DEV container
.PHONY: stop-dev
stop-dev:
	$(CONTAINER_ENGINE) stop $(IMGBASENAME)

# Run tests against DEV v1 image
.PHONY: test-dev-v1
test-dev-v1: MAJOR_VERSION := 1
test-dev-v1: IMGDEVTAG := $(IMGDEVTAG_BASE)-v$(MAJOR_VERSION)
test-dev-v1: .test-dev

# Run tests against DEV v2 image
.PHONY: test-dev-v2
test-dev-v2: MAJOR_VERSION := 2
test-dev-v2: IMGDEVTAG := $(IMGDEVTAG_BASE)-v$(MAJOR_VERSION)
test-dev-v2: .test-dev

# Run tests against DEV v3 image
.PHONY: test-dev-v3
test-dev-v3: MAJOR_VERSION := 3
test-dev-v3: IMGDEVTAG := $(IMGDEVTAG_BASE)-v$(MAJOR_VERSION)
test-dev-v3: .test-dev

# Run tests against DEV image
.PHONY: .test-dev
.test-dev: .check-test-deps
	@make --quiet run-dev-v$(MAJOR_VERSION)
	@bash ./build/test.sh "$(MAJOR_VERSION)" "http://0.0.0.0:$(DEVPORT)"
	@make --quiet stop-dev
	@test "$(CONTAINER_ENGINE)" = "podman" && systemctl --user start podman.socket
	CONTAINER_ENGINE=${CONTAINER_ENGINE} bash ./build/trivy.sh image $(IMGDEVTAG) --exit-code 1 --no-progress --severity HIGH,CRITICAL

# Start DEV v1 instance & show results
.PHONY: open-dev-v1
open-dev-v1: MAJOR_VERSION := 1
open-dev-v1: .open-dev

# Start DEV v2 instance & show results
.PHONY: open-dev-v2
open-dev-v2: MAJOR_VERSION := 2
open-dev-v2: .open-dev

# Start DEV v3 instance & show results
.PHONY: open-dev-v3
open-dev-v3: MAJOR_VERSION := 3
open-dev-v3: .open-dev

# Start DEV instance & show results
.PHONY: .open-dev
.open-dev:
	@make --quiet run-dev-v$(MAJOR_VERSION)
	@make --quiet .get-text-content
	@command -v xdg-open > /dev/null && (xdg-open http://0.0.0.0:$(DEVPORT)/index.html 2>/dev/null) || echo "Please open http://0.0.0.0:$(DEVPORT)/index.html manually in your browser"

# Build RELEASE images for all major versions
.PHONY: build-release
build-release:
	@for major in $$(bash ./build/getver majors); \
	do \
	APP_VERSION=$$(bash ./build/getver patch $${major}); \
	IMGRELTAG="$(IMGRELNAME):$${APP_VERSION}"; \
	echo "Building $${IMGRELTAG}"; \
	$(BUILD_CMD) --build-arg=MAJOR_VERSION="$${major}" --build-arg=APP_VERSION="$${APP_VERSION}" -t $${IMGRELTAG} . ; \
	done

# Pull RELEASE images from GHCR
.PHONY: pull-release
pull-release:
	@for major in $$(bash ./build/getver majors); \
	do \
	APP_VERSION=$$(bash ./build/getver patch $${major}); \
	IMGRELTAG="$(IMGRELNAME):$${APP_VERSION}"; \
	$(CONTAINER_ENGINE) pull $${IMGRELTAG}; \
	done

# Run RELEASE v1 instance
.PHONY: run-release-v1
run-release-v1: MAJOR_VERSION := 1
run-release-v1: APP_VERSION := $(shell build/getver patch $(MAJOR_VERSION))
run-release-v1: IMGRELTAG := $(IMGRELNAME):$(APP_VERSION)
run-release-v1: .run-release

# Run RELEASE v2 instance
.PHONY: run-release-v2
run-release-v2: MAJOR_VERSION := 2
run-release-v2: APP_VERSION := $(shell build/getver patch $(MAJOR_VERSION))
run-release-v2: IMGRELTAG := $(IMGRELNAME):$(APP_VERSION)
run-release-v2: .run-release

# Run RELEASE v3 instance
.PHONY: run-release-v3
run-release-v3: MAJOR_VERSION := 3
run-release-v3: APP_VERSION := $(shell build/getver patch $(MAJOR_VERSION))
run-release-v3: IMGRELTAG := $(IMGRELNAME):$(APP_VERSION)
run-release-v3: .run-release

# Start RELEASE container
.PHONY: .run-release
.run-release:
	$(RUN_CMD) --rm -d -p 127.0.0.1:$(DEVPORT):8080 --name $(IMGBASENAME) --memory-reservation 16m --memory-reservation 32m -e MESSAGE="Release" $(IMGRELTAG)
	@echo "The container should be accessible at http://0.0.0.0:$(DEVPORT)/"

# Stop RELEASE container
.PHONY: stop-release
stop-release:
	$(CONTAINER_ENGINE) stop $(IMGBASENAME)

# Run tests against all RELEASE images
.PHONY: test-release
test-release:
	@make --quiet test-release-v1
	@make --quiet test-release-v2
	@make --quiet test-release-v3

# Run tests against RELEASE v1 image
.PHONY: test-release-v1
test-release-v1: MAJOR_VERSION := 1
test-release-v1: APP_VERSION := $(shell build/getver patch $(MAJOR_VERSION))
test-release-v1: IMGRELTAG := $(IMGRELNAME):$(APP_VERSION)
test-release-v1: .test-release

# Run tests against RELEASE v2 image
.PHONY: test-release-v2
test-release-v2: MAJOR_VERSION := 2
test-release-v2: APP_VERSION := $(shell build/getver patch $(MAJOR_VERSION))
test-release-v2: IMGRELTAG := $(IMGRELNAME):$(APP_VERSION)
test-release-v2: .test-release

# Run tests against RELEASE v3 image
.PHONY: test-release-v3
test-release-v3: MAJOR_VERSION := 3
test-release-v3: APP_VERSION := $(shell build/getver patch $(MAJOR_VERSION))
test-release-v3: IMGRELTAG := $(IMGRELNAME):$(APP_VERSION)
test-release-v3: .test-release

# Run tests against RELEASE image
.PHONY: .test-release
.test-release: .check-test-deps
	@make --quiet run-release-v$(MAJOR_VERSION)
	$(CONTAINER_ENGINE) ps -a
	bash ./build/test.sh "$(MAJOR_VERSION)" "http://0.0.0.0:$(DEVPORT)" "$(CONTAINER_ENGINE) exec -t $(IMGBASENAME) curl"
	make --quiet stop-release
	test "$(CONTAINER_ENGINE)" = "podman" && systemctl --user start podman.socket || echo "No need to start podman socket"
	CONTAINER_ENGINE=${CONTAINER_ENGINE} bash ./build/trivy.sh image $(IMGRELTAG) --exit-code 1 --no-progress --severity HIGH,CRITICAL

# Create SPDX SBOM for release images for all major versions
.PHONY: sbom-release
sbom-release:
	@test -d sbom || mkdir sbom
	@for major in $$(bash ./build/getver majors); \
	do \
	APP_VERSION=$$(bash ./build/getver patch $${major}); \
	IMGRELTAG="$(IMGRELNAME):$${APP_VERSION}"; \
	CONTAINER_ENGINE=${CONTAINER_ENGINE} bash ./build/trivy.sh image $${IMGRELTAG} --no-progress; \
	CONTAINER_ENGINE=${CONTAINER_ENGINE} bash ./build/trivy.sh image --scanners vuln --format spdx-json --output /sbom/sbom-v$${APP_VERSION}.json $${IMGRELTAG}; \
	git add sbom/sbom-v$${APP_VERSION}.json; \
	done
	git commit -m "Added SBOM for $$(bash ./build/getver patches)"
	@# git push

# Push RELEASE images for all major versions
.PHONY: push-release
push-release:
	test ! -z "$(REGISTRY)" && $(CONTAINER_ENGINE) login $(REGISTRY) || echo 'Not logging into registry'
	@for major in $$(bash ./build/getver majors); \
	do \
	APP_VERSION=$$(bash ./build/getver patch $${major}); \
	IMGRELTAG="$(IMGRELNAME):$${APP_VERSION}"; \
	echo "Pushing $${IMGRELTAG}"; \
	$(CONTAINER_ENGINE) push $${IMGRELTAG}; \
	minor=$$(bash ./build/getver minor $${major}); \
	$(CONTAINER_ENGINE) tag $${IMGRELTAG} $(IMGRELNAME):$${minor}; \
	$(CONTAINER_ENGINE) push $(IMGRELNAME):$${minor}; \
	$(CONTAINER_ENGINE) tag $${IMGRELTAG} $(IMGRELNAME):$${major}; \
	$(CONTAINER_ENGINE) push $(IMGRELNAME):$${major}; \
	done

# Syntax check source code
.PHONY: lint
lint: .check-lint-depends
	@yamllint .github/workflows/build-image.yaml
	@yamllint deploy/service-clusterip.yaml deploy/service-nodeport.yaml deploy/ingress.yaml deploy/openshift-route.yaml
	@yamllint deploy/deployment-v*.yaml

# Increment APP_VERSION minor version number
.PHONY: bump-version-minor
bump-version-minor: .check-ver-deps lint
	@bash ./build/bumpver minor
	@bash ./build/fix-doc-version.sh

# Increment APP_VERSION patch version number
.PHONY: bump-version-patch
bump-version-patch: .check-ver-deps lint
	@bash ./build/bumpver patch
	@bash ./build/fix-doc-version.sh

# git tag with current APP_VERSION
# Stick to 1.x.y version numbering for git releases
.PHONY: .git-tag
.git-tag: APP_VERSION := $(shell build/getver patch 1)
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
	@test -f ./build/semver || (curl --location --output ./build/semver https://raw.githubusercontent.com/fsaintjacques/semver-tool/master/src/semver && chmod 0755 ./build/semver)
	@bash ./build/semver --version

# Install trivy scanner locally if not present
# Deprecated - we now run it in a container instead
.PHONY: .install-trivy
.install-trivy:
	@test -d ~/bin || mkdir ~/bin
	command -v trivy || (cd ~/bin && TRIVY_VERSION=`curl --location --silent https://api.github.com/repos/aquasecurity/trivy/releases/latest | jq '.name[1:]' -r` && echo "Version [$${TRIVY_VERSION}]" && curl --location --output trivy_Linux-64bit.tar.gz https://github.com/aquasecurity/trivy/releases/download/v$${TRIVY_VERSION}/trivy_$${TRIVY_VERSION}_Linux-64bit.tar.gz && tar -xzvf trivy_Linux-64bit.tar.gz trivy && rm trivy_Linux-64bit.tar.gz)
	export PATH=~/bin:$$PATH; trivy --version

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
	command -v git
