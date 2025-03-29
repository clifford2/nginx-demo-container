# Build Instructions

## Development

```sh
make build-dev
make test-dev
make open-dev
make stop-dev
```

## Release

Build for release:

```sh
make bump-version-{major,minor,patch}
make build-release
```

Commit & push source:

```sh
git add . && git commit
make git-tag
make git-push
```

Push image:

```sh
make push-release
```
