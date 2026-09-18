# Nginx Demo Container Image

You can also test the image without Kubernetes, using
[Podman](https://podman.io/docs) or [Docker](https://docs.docker.com/).

The easiest way to do this is with
[`podman-compose`](https://github.com/containers/podman-compose) or
[`docker compose`](https://docs.docker.com/compose/).

Alternately you can also manually start individual containers, without
using Compose.

## Deploy With Podman Compose / Docker Compose

This example configuration starts 4 containers behind a load balancer.

```sh
# Change to directory containing config files
cd deploy
# Start containers with podman-compose
podman-compose up
# Alternate: start containers with docker compose
docker compose up

# Test
watch -d -n 1 curl --no-progress-meter http://127.0.0.1:9090/index.txt
# or
gio open http://127.0.0.1:9090/
```

## Deploy With Podman / Docker (no Compose)

Example commands for starting individual containers manually
(replace `podman` with `docker` if desired):

```shell
# Start containers
$ podman run -d --rm \
   -p 127.0.0.1:9091:8080 \
   --name nginx-demo-1 \
   ghcr.io/clifford2/nginx-demo:3.13.4
$ podman run -d --rm \
   -p 127.0.0.1:9092:8080 \
   --name nginx-demo-2 \
   -e MESSAGE=Blue \
   ghcr.io/clifford2/nginx-demo:3.13.4
$ podman run -d --rm \
   -p 127.0.0.1:9093:8080 \
   --name nginx-demo-3 \
   -e MESSAGE=Green \
   ghcr.io/clifford2/nginx-demo:3.13.4
$ podman run -d --rm \
   -p 127.0.0.1:9094:8080 \
   --name nginx-demo-4 \
   -e MESSAGE=Red \
   ghcr.io/clifford2/nginx-demo:3.13.4

# Test
$ gio open http://127.0.0.1:9091/index.html
$ curl http://127.0.0.1:9092/index.json | jq '.'
$ curl http://127.0.0.1:9093/index.txt
$ curl http://127.0.0.1:9094/index.csv

# Stop containers
$ podman stop nginx-demo-{1,2,3,4}
```
