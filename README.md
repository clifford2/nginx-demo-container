# Nginx Demo

A very simple demo container image, running [Nginx](https://nginx.org/)
on port 8080.

It returns simple files which contain:

- The image build time (handy for CI/CD tests/demos)
- Container hostname (handy for load balancing tests/demos).

This output is available in 3 formats, namely:

- HTML: `index.html`
- Plain text: `index.txt`
- JSON: `index.json`

An image built from this code is available on Docker Hub as
[`cliffordw/nginx-demo`](https://hub.docker.com/r/cliffordw/nginx-demo),
which you can run with:

```sh
podman run -d -p 8080:8080 docker.io/cliffordw/nginx-demo:latest
curl http://127.0.0.1:8080/index.json
```
