# Push Image To Local Registry

*Probably redundant now, as our Makefile pushes to our local registry, while a GitHub Action builds & pushes the public version*

```sh
srcimg='registry.h.c6d.xyz/clifford/nginx-demo'
dstrepo='gitea.h.c6d.xyz:3000'
dstimg="${dstrepo}/clifford/nginx-demo"
ver=$(cat .version)
podman tag ${srcimg}:${ver} ${dstimg}:${ver}
podman login ${dstrepo}
podman push ${dstimg}:${ver}
```
