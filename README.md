# Nginx Demo Container Image

## About

This code builds a very simple demo container image, running
[nginx](https://nginx.org/) as a non root, unprivileged user,
on port 8080.

It returns simple content containing:

- The image version/tag (handy for CI/CD tests & demos)
- The image build time (handy for CI/CD tests & demos)
- Container hostname & start time (handy for load balancing & deployment rollout tests & demos)
- The value of an optional `$COLOR` environment variable (handy visual aid for load balancing tests & demos)

This output is available in the following formats:

- HTML: `index.html` (handy for human consumption)
- JSON: `index.json` (ideal for automated processing)
- Plain text: `index.txt` (LF terminated)
- Comma-separated values: `index.csv` (CR/LF terminated)

An image built from this code is available at
[`ghcr.io/clifford2/nginx-demo`](https://ghcr.io/clifford2/nginx-demo).

## Using The Image

Example Kubernetes manifests are available in `deploy/k8s-{version}.yaml`.
The latest version is also available in [`deploy/k8s-latest.yaml`](deploy/k8s-latest.yaml).
Deploy with:

```sh
kubectl apply -f https://raw.githubusercontent.com/clifford2/nginx-demo-container/refs/heads/main/deploy/k8s-latest.yaml
```

You can also run the image locally with commands like this:

```shell
$ podman run -d --rm \
   -p 8081:8080 \
   --name nginx-demo-nocolor \
   ghcr.io/clifford2/nginx-demo:1.7.4
$ podman run -d --rm \
   -p 8082:8080 \
   --name nginx-demo-blue \
   -e COLOR=blue \
   ghcr.io/clifford2/nginx-demo:1.7.4
$ podman run -d --rm \
   -p 8083:8080 \
   --name nginx-demo-green \
   -e COLOR=green \
   ghcr.io/clifford2/nginx-demo:1.7.4
$ podman run -d --rm \
   -p 8084:8080 \
   --name nginx-demo-red \
   -e COLOR=red \
   ghcr.io/clifford2/nginx-demo:1.7.4

$ xdg-open http://127.0.0.1:8081/index.html
$ curl http://127.0.0.1:8082/index.json
$ curl http://127.0.0.1:8083/index.txt
$ curl http://127.0.0.1:8084/index.csv

$ podman stop nginx-demo-nocolor nginx-demo-red nginx-demo-blue nginx-demo-green
```

## License & Disclaimer

This code is shared under the MIT No Attribution License.
It is provided *AS IS*, without warranty of any kind.
See [`LICENSES/MIT-0.txt`](LICENSES/MIT-0.txt) for the full license text and disclaimer.

## Security

This is a demo, provided for educational purposes only.

While it is updated as often as possible, support is provided on a best effort basis only.

Please report any problems or vulnerabilities by opening a [GitHub issue here](https://github.com/clifford2/nginx-demo-container/issues).

## Output Samples

Here are some output examples from v1.5.1.

HTML:

![HTML](images/sample-html.png "HTML")

JSON:

```json
{
  "image_version": "1.5.1",
  "build_time": "2025-11-13T13:22:22Z",
  "container_hostname": "330e9917d50f",
  "start_time": "2025-11-13T13:37:39Z",
  "color": "#1F63E0",
  "nginx_version": "1.29.2"
}
```

CSV:

```csv
"image_version","1.5.1"
"build_time","2025-11-13T13:22:22Z"
"container_hostname","330e9917d50f"
"start_time","2025-11-13T13:37:39Z"
"color","#1F63E0"
"nginx_version","1.29.2"
```

Plain text:

```text
image_version:1.5.1
build_time:2025-11-13T13:22:22Z
container_hostname:330e9917d50f
start_time:2025-11-13T13:37:39Z
color:#1F63E0
nginx_version:1.29.2
```
