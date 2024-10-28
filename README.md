# Nginx Demo

A very simple demo container image, running [Nginx](https://nginx.org/)
as a non root, unprivileged user, on port 8080.

It returns simple files which contain:

- The image version/tag (handy for CI/CD tests/demos)
- The image build time (handy for CI/CD tests/demos)
- Container hostname (handy for load balancing tests/demos)

This output is available in 3 files / formats, namely:

- HTML: `index.html`
- Plain text: `index.txt`
- JSON: `index.json`

An image built from this code is available on Docker Hub as
[`cliffordw/nginx-demo`](https://hub.docker.com/r/cliffordw/nginx-demo).

You can run it locally with:

```sh
podman run -d -p 8080:8080 docker.io/cliffordw/nginx-demo:1.0.6
curl http://127.0.0.1:8080/index.json
```

An example Kubernetes manifest is also available in `k8s.yaml`.
