# Nginx Demo

A very simple demo container image, running [Nginx](https://nginx.org/)
as a non root, unprivileged user, on port 8080.

The is a demo, for educational purposes only.
It is provided *AS IS*, without warranty of any kind - See `LICENSE`.

It returns simple files which contain:

- The image version/tag (handy for CI/CD tests & demos)
- The image build time (handy for CI/CD tests & demos)
- Container hostname & start time (handy for load balancing tests & demos)

This output is available in the following files / formats:

- HTML: `index.html` (handy for human consumption)
- JSON: `index.json` (handy for automated processing)
- Plain text: `index.txt`
- Comma-separated values: `index.csv`

An image built from this code is available on Docker Hub as
[`cliffordw/nginx-demo`](https://hub.docker.com/r/cliffordw/nginx-demo).

You can run it locally with:

```sh
podman run -d --rm -p 8081:8080 --name nginx-demo-red docker.io/cliffordw/nginx-demo:1.2.3
podman run -d --rm -p 8082:8080 --name nginx-demo-blue -e COLOR=blue docker.io/cliffordw/nginx-demo:1.2.3
podman run -d --rm -p 8083:8080 --name nginx-demo-green -e COLOR=green docker.io/cliffordw/nginx-demo:1.2.3
curl http://127.0.0.1:8081/index.json
curl http://127.0.0.1:8082/index.txt
curl http://127.0.0.1:8083/index.csv
podman stop nginx-demo-red nginx-demo-blue nginx-demo-green
```

An example Kubernetes manifest is also available in `k8s.yaml`.
