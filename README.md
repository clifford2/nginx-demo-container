# Nginx demo

Simple Nginx demo container image.

Shows image build time (handy for CI tests/demos) and
container hostname (handy for load balancing tests/demos).

Build:

```sh
podman build -t docker.io/cliffordw/nginx-demo:1.0.0 .
```
