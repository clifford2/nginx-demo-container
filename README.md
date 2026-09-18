# Nginx Demo Container Image

## About

This code builds three very simple HTTP server container images, which are handy for
[Continuous Deployment](https://en.wikipedia.org/wiki/Continuous_deployment) (CD)
and [Load balancing](https://en.wikipedia.org/wiki/Load_balancing_(computing))
tests & demos.

The containers return simple content, containing:

- The image version/tag (handy for CD tests & demos)
- The image build time (handy for CD tests & demos)
- Container hostname & start time (handy for load balancing & deployment rollout tests & demos)
- A customizable area:
	- For v1 images, a coloured box, controlled by the optional `$COLOR` environment variable (handy visual aid for load balancing tests & demos)
	- For v2 & v3 images, a message box, where a text message from the optional `$MESSAGE` environment variable will be displayed

This output is available in the following formats:

- HTML: `index.html` (handy for human consumption)
- JSON: `index.json` (ideal for automated processing)
- Plain text: `index.txt` (LF terminated)
- Comma-separated values: `index.csv` (CR/LF terminated)

This is built on top of the [nginx](https://nginx.org/) HTTP web server,
running as an unprivileged user, on port 8080.

## Building The Images

Images built from this code are available at
[`ghcr.io/clifford2/nginx-demo`](https://ghcr.io/clifford2/nginx-demo).

If you prefer to build your own container images, see [`doc/build.md`](doc/build.md).

## Using The Images

For examples of how to use these images in Kubernetes, see
[`doc/k8s.md`](doc/k8s.md).

You can also test the images using Podman or Docker.
For examples, see [`doc/podman.md`](doc/podman.md).

## Output Samples

Some output samples are available in [`doc/samples.md`](doc/samples.md);

## License & Disclaimer

This code is shared under the MIT No Attribution License.
It is provided *AS IS*, without warranty of any kind.
See [`LICENSES/MIT-0.txt`](LICENSES/MIT-0.txt) for the full license text and disclaimer.

## Security

This is a demo, provided for educational purposes only.

While it is updated as often as possible, support is provided on a best effort basis only.

Please report any problems or vulnerabilities by opening a [GitHub issue here](https://github.com/clifford2/nginx-demo-container/issues).
