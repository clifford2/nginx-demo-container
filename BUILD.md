# Build Instructions

## Development

Build for test:

```sh
make run-dev
```

Stop test container:

```sh
make stop-dev
```

## Release

Build for release:

```sh
make bump-version-{major,minor,patch}
./build.sh
```

Commit & push source:

```sh
git add . && git commit
make git-tag
git push --follow-tags
```

Push image:

```sh
podman login docker.io
make push-release
```
