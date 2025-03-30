# Build Instructions

## Development

```sh
make build-dev
make test-dev
make open-dev
make stop-dev
```

## Release

Update version:

```sh
make bump-version-{major,minor,patch}
git add . && git commit
make git-tag git-push
```

Release new image:

```sh
make build-release
make push-release
```
