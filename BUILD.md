# Build Instructions

## Development

```sh
make build-dev
make test-dev
make open-dev
make stop-dev
```

## Release Publicly

Update version, commit, and push to GitHub (triggers GitHub Action to build
public image):

```sh
make bump-version-{major,minor,patch}
git add . && git commit
make git-tag git-push
```

## Release Privately

Build local copy & publish to private registry:

```sh
make build-release
make push-release
```

## Push Image To Alternate Registry

```sh
srcimg='registry.h.c6d.xyz/clifford/nginx-demo'
dstrepo='localhost:5000'
dstimg="${dstrepo}/clifford/nginx-demo"
ver=$(cat .version)
podman tag ${srcimg}:${ver} ${dstimg}:${ver}
podman login ${dstrepo}
podman push ${dstimg}:${ver}
```
