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

Run with:

```sh
podman run -d -p 8080:8080 docker.io/cliffordw/nginx-demo:latest
curl http://127.0.0.1:8080/index.json
```
