<div align="center">

# dev-box
[![Docker](https://img.shields.io/badge/Docker-2CA5E0?logo=docker&logoColor=white)](docker.md)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-3069DE?logo=kubernetes&logoColor=white)](kubernetes.md)
[![Debian](https://img.shields.io/badge/Debian-A81D33?logo=debian)](https://www.debian.org/)

[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/manuel-fernandez-rodriguez/dev-box/publish-image.yml)](https://github.com/manuel-fernandez-rodriguez/dev-box/actions/workflows/publish-image.yml)
[![GitHub License](https://img.shields.io/github/license/manuel-fernandez-rodriguez/dev-box)](https://github.com/manuel-fernandez-rodriguez/dev-box/blob/main/LICENSE.txt)
[![Github Package](https://img.shields.io/badge/package-dev--box-latest)](https://github.com/manuel-fernandez-rodriguez/dev-box/pkgs/container/dev-box)

</div>

## Overview
**Debian Trixie** multiuser desktop environment based on **XFCE4**, accessible 
via Remote Desktop Protocol (RDP), based on [xfce-rdp](https://github.com/manuel-fernandez-rodriguez/xfce-rdp),
with preinstalled:

- .NET10 SDK
- Visual Studio Code
- C# DevKit
- Firefox
- Plus all the goodies in xfce-rdp image

## Quick Run on Docker

```bash
docker run -e RUNTIME_CONFIG='{"userCredentials":[{"username":"developer","password":"s3cr3t","sudo":true}]}' \
  -p 33890:3389 --shm-size=1g -d --name dev-box dev-box:latest
```

See more detailed instructions on [Docker setup](doc/docker.md).

## Quick Run on Kubernetes

```bash
kubectl run dev-box \
  --image=ghcr.io/manuel-fernandez-rodriguez/dev-box:latest \
  --restart=Never --port=3389 --image-pull-policy=IfNotPresent \
  --env="RUNTIME_CONFIG={\"userCredentials\":[{\"username\":\"developer\",\"password\":\"s3cr3t\",\"sudo\":true}]}" \
  --overrides='{"apiVersion":"v1","spec":{"containers":[{"name":"dev-box","volumeMounts":[{"name":"dshm","mountPath":"/dev/shm"}]}],"volumes":[{"name":"dshm","emptyDir":{"medium":"Memory","sizeLimit":"1Gi"}}]}}'
```

See more detailed instructions on [Kubernetes setup](doc/kubernetes.md).

## Extending this image
See [Extending the xfce-rdp base image](https://github.com/manuel-fernandez-rodriguez/xfce-rdp/blob/main/doc/extending.md) for best practices 
and examples on how to add your own initialization logic without modifying 
the base image.