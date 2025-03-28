# Nginx Demo Container Image

## About

A very simple demo container image, running [Nginx](https://nginx.org/)
as a non root, unprivileged user, on port 8080.

It returns simple files which contain:

- The image version/tag (handy for CI/CD tests & demos)
- The image build time (handy for CI/CD tests & demos)
- Container hostname & start time (handy for load balancing tests & demos)

This output is available in the following files / formats:

- HTML: `index.html` (handy for human consumption)
- JSON: `index.json` (handy for automated processing)
- Plain text: `index.txt`
- Comma-separated values: `index.csv`

An image built from this code is available at
[`ghcr.io/clifford2/nginx-demo`](https://ghcr.io/clifford2/nginx-demo).

## Using The Image

You can run the image locally with:

```sh
podman run -d --rm -p 8081:8080 --name nginx-demo-red ghcr.io/clifford2/nginx-demo:1.2.3
podman run -d --rm -p 8082:8080 --name nginx-demo-blue -e COLOR=blue ghcr.io/clifford2/nginx-demo:1.2.3
podman run -d --rm -p 8083:8080 --name nginx-demo-green -e COLOR=green ghcr.io/clifford2/nginx-demo:1.2.3
curl http://127.0.0.1:8081/index.json
curl http://127.0.0.1:8082/index.txt
curl http://127.0.0.1:8083/index.csv
podman stop nginx-demo-red nginx-demo-blue nginx-demo-green
```

An example Kubernetes manifest is also available in `k8s.yaml`.

## License & Disclaimer

This code is shared under the BSD 2-Clause "Simplified" License.
It is provided *AS IS*, without warranty of any kind.
See [`LICENSES/BSD-2-Clause.txt`](LICENSES/BSD-2-Clause.txt) for the full license text and disclaimer.

## Security

This is a demo, provided for educational purposes only.

While it is updated as often as possible, support is provided on a best effort basis only.

Please report any problems or vulnerabilities by opening a [GitHub issue here](https://github.com/clifford2/nginx-demo-container/issues).
