# Nginx Demo Container Image

## About

This code builds a very simple web server container image, which is handy for
[Continuous Deployment (CD)](https://en.wikipedia.org/wiki/Continuous_deployment)
and load balancing tests & demos.
It is running [nginx](https://nginx.org/) as a non root, unprivileged
user, on port 8080.

It returns simple content containing:

- The image version/tag (handy for CD tests & demos)
- The image build time (handy for CD tests & demos)
- Container hostname & start time (handy for load balancing & deployment rollout tests & demos)
- A coloured box, controlled by the optional `$COLOR` environment variable (handy visual aid for load balancing tests & demos)

This output is available in the following formats:

- HTML: `index.html` (handy for human consumption)
- JSON: `index.json` (ideal for automated processing)
- Plain text: `index.txt` (LF terminated)
- Comma-separated values: `index.csv` (CR/LF terminated)

An image built from this code is available at
[`ghcr.io/clifford2/nginx-demo`](https://ghcr.io/clifford2/nginx-demo).

## Using The Image

### Basic Usage

Example Kubernetes manifests are available in `deploy/k8s-${version}.yaml`.

Deploy the latest version (available in [`deploy/k8s-latest.yaml`](deploy/k8s-latest.yaml)) to your Kubernetes cluster with:

```sh
kubectl apply -f https://raw.githubusercontent.com/clifford2/nginx-demo-container/refs/heads/main/deploy/k8s-latest.yaml
```

*Note that the `startupProbe` timing is intentionally longer than necessary to allow you to observe the transitions.*

You can also test the image with Podman or Docker, using commands like this (replace `podman` with `docker` if desired):

```shell
$ podman run -d --rm \
   -p 8081:8080 \
   --name nginx-demo-nocolor \
   ghcr.io/clifford2/nginx-demo:1.10.0
$ podman run -d --rm \
   -p 8082:8080 \
   --name nginx-demo-blue \
   -e COLOR=blue \
   ghcr.io/clifford2/nginx-demo:1.10.0
$ podman run -d --rm \
   -p 8083:8080 \
   --name nginx-demo-green \
   -e COLOR=green \
   ghcr.io/clifford2/nginx-demo:1.10.0
$ podman run -d --rm \
   -p 8084:8080 \
   --name nginx-demo-red \
   -e COLOR=red \
   ghcr.io/clifford2/nginx-demo:1.10.0

$ xdg-open http://127.0.0.1:8081/index.html
$ curl http://127.0.0.1:8082/index.json
$ curl http://127.0.0.1:8083/index.txt
$ curl http://127.0.0.1:8084/index.csv

$ podman stop nginx-demo-nocolor nginx-demo-red nginx-demo-blue nginx-demo-green
```

###  Rolling Update Demo

To demonstrate [Kubernetes rolling update](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/), try these steps:

```sh
# Deploy an older-than-latest version:
kubectl apply -f https://raw.githubusercontent.com/clifford2/nginx-demo-container/refs/heads/main/deploy/k8s-1.6.1.yaml
# Port forward the service to your device so you can access it locally
# (replace port 8088 to suite your needs):
kubectl port-forward service/nginx-demo 8088:8080
# Connect to the service with a web browser (http://0.0.0.0:8088), and reload
# a few times to see the load balancing between the 3 deployments.
#
# Change the `$COLOR` of 2 of the deployments:
kubectl patch deployment nginx-demo-blue -p '{"spec":{"template":{"spec":{
"containers":[{"name":"nginx-demo","env":[{"name":"COLOR","value":"#1F63E0"}]}]
}}}}'

kubectl patch deployment nginx-demo-green -p '{"spec":{"template":{"spec":{
"containers":[{"name":"nginx-demo","env":[{"name":"COLOR","value":"#3BC639"}]}]
}}}}'
# Watch the rollout happen (Ctrl-C to stop),
# while also reloading the web page to see the effects:
watch kubectl get deployments,pods -l app.kubernetes.io/name=nginx-demo

# Upgrade to the latest image version:
kubectl apply -f https://raw.githubusercontent.com/clifford2/nginx-demo-container/refs/heads/main/deploy/k8s-latest.yaml
# Watch the rollout happen (Ctrl-C to stop),
# while also reloading the web page to see the effects:
watch kubectl get deployments,pods -l app.kubernetes.io/name=nginx-demo
```

To test the liveness probe & automatic restart of a pod, remove the `healthz.json` file so that the probe fails:

```sh
kubectl get pods -l app.kubernetes.io/name=nginx-demo
kubectl exec <podname> -- rm /usr/share/nginx/html/healthz.json
```

## Output Samples

Here are some output examples from November 2025 (different code releases).

HTML:

![HTML](images/sample-html.png "HTML")

JSON:

```json
{
  "image_version": "1.7.11",
  "build_time": "2025-11-15T05:58:19Z",
  "container_hostname": "eeb54793d9e6",
  "start_time": "2025-11-15T06:09:01Z",
  "color": "#333",
  "nginx_version": "1.29.2",
  "opencontainers_annotations": {
    "org.opencontainers.image.authors": "Clifford Weinmann <https://www.cliffordweinmann.com/>",
    "org.opencontainers.image.created": "2025-11-15T05:58:19Z",
    "org.opencontainers.image.description": "NGINX Demo",
    "org.opencontainers.image.licenses": "MIT-0",
    "org.opencontainers.image.revision": "9243706706f0b74a5aa6f33d94f1848fc205d3f2",
    "org.opencontainers.image.source": "https://github.com/clifford2/nginx-demo-container",
    "org.opencontainers.image.title": "nginx-demo-container",
    "org.opencontainers.image.url": "https://github.com/clifford2/nginx-demo-container",
    "org.opencontainers.image.version": "1.7.11"
  }
}
```

CSV:

```csv
"image_version","1.5.1"
"build_time","2025-11-13T13:22:22Z"
"container_hostname","330e9917d50f"
"start_time","2025-11-13T13:37:39Z"
"color","#1F63E0"
```

Plain text:

```text
image_version:1.7.11
build_time:2025-11-15T05:58:19Z
container_hostname:eeb54793d9e6
start_time:2025-11-15T06:09:01Z
color:#333
nginx_version:1.29.2
```

## Building The Image

There are a couple of ways to build your own container image from this code, namely:

- Build manually, using [GNU Make](https://www.gnu.org/software/make/), by running `make build-release && make test-release`
- With [GitHub Actions](https://github.com/features/actions) (our current Continuous Integration (CI) approach) - see [`.github/workflows/build-image.yaml`](.github/workflows/build-image.yaml)
- With [Jenkins](https://www.jenkins.io/) - sample configuration available in [`Jenkinsfile`](Jenkinsfile)
- With an [Azure DevOps Pipeline](https://azure.microsoft.com/en-us/products/devops/pipelines) - sample configuration available in [`azure-pipelines.yml`](azure-pipelines.yml) 
- With [GitLab CI/CD pipelines](https://docs.gitlab.com/ci/pipelines/) - sample configuration available in [`.gitlab-ci.yml`](.gitlab-ci.yml)

## License & Disclaimer

This code is shared under the MIT No Attribution License.
It is provided *AS IS*, without warranty of any kind.
See [`LICENSES/MIT-0.txt`](LICENSES/MIT-0.txt) for the full license text and disclaimer.

## Security

This is a demo, provided for educational purposes only.

While it is updated as often as possible, support is provided on a best effort basis only.

Please report any problems or vulnerabilities by opening a [GitHub issue here](https://github.com/clifford2/nginx-demo-container/issues).
