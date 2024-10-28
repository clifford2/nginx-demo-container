# Build Instructions

Build:

```sh
./build.sh
curl http://127.0.0.1:8080/index.txt
curl http://127.0.0.1:8080/index.json
xdg-open http://127.0.0.1:8080/index.html
```

Stop test container:

```sh
podman ps | grep -wq nginx-demo && podman stop nginx-demo
```

Commit & push source:

```sh
ver=$(cat .version)
git add . && git commit -a && git tag -a -m "Version ${ver}" "${ver}"
git push && git push --tags
```

Push image:

```sh
ver=$(cat .version)
podman tag docker.io/cliffordw/nginx-demo:${ver} docker.io/cliffordw/nginx-demo:latest
podman login docker.io
podman push docker.io/cliffordw/nginx-demo:${ver}
podman push docker.io/cliffordw/nginx-demo:latest
```
