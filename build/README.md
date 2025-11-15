# Build Instructions

## Development

```sh
make build-dev
make test-dev
make open-dev
make stop-dev
```

## Release Publicly

Update version, commit, and push to GitHub (triggers GitHub Action to
build public image):

```sh
make lint
make bump-version-{major,minor,patch}
git add . && git commit
make git-tag-push
```

## Release Privately

Build local copy & publish to private registry (example):

```sh
make push-release REPOBASE=registry.example.net/clifford
```

## Manually Push Image To Alternate Registry

```sh
srcimg='localhost/nginx-demo'
dstrepo='registry.example.com'
dstimg="${dstrepo}/mynamespace/nginx-demo"
ver=$(cat .version)
podman tag ${srcimg}:${ver} ${dstimg}:${ver}
podman login ${dstrepo}
podman push ${dstimg}:${ver}
```
