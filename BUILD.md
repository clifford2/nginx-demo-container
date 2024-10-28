# Build Instructions

Build:

```sh
ver=$(cat .version)
podman build -t docker.io/cliffordw/nginx-demo:${ver} .
```

Test:

```sh
podman run --rm -d -p 8080:8080 --name nginx-demo docker.io/cliffordw/nginx-demo:${ver}
curl http://127.0.0.1:8080/index.txt
curl http://127.0.0.1:8080/index.json
curl http://127.0.0.1:8080/index.html
podman stop nginx-demo
```

Commit & push source:

```sh
sed -ie "s|image: .*$|image: docker.io/cliffordw/nginx-demo:${ver}|" k8s.yaml
git add .
git commit -a
git tag -a -m "Version ${ver}" "${ver}"
git push
git push --tags
```

Push image:

```sh
podman login
podman push docker.io/cliffordw/nginx-demo:${ver}
podman tag docker.io/cliffordw/nginx-demo:${ver} docker.io/cliffordw/nginx-demo:latest
podman push docker.io/cliffordw/nginx-demo:latest
```
