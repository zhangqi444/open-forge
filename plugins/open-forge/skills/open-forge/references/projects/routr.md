---
name: routr
description: Routr recipe for open-forge. Lightweight SIP proxy, location server, and registrar for a reliable and scalable SIP infrastructure. Supports Docker and Kubernetes. Source: https://github.com/fonoster/routr
---

# Routr

Lightweight SIP proxy, location server, and registrar that provides a reliable and scalable SIP infrastructure for telephony carriers, communication service providers, and integrators. Upstream: <https://github.com/fonoster/routr>. Docs: <https://routr.io/docs>.

Routr is Docker- and Kubernetes-ready, designed as a cloud-first SIP server. It supports programmable routing via a plugin/processor architecture and ships a CLI tool (`rctl`) for management.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker (routr-one) | Any Linux with Docker | Single-container all-in-one. Recommended for quick start. |
| Kubernetes + Helm | K8s | Production-grade. Official Helm chart at `routr.io/charts`. |
| Build from source | Node.js | Development use. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| network | "External IP address of this server?" | Required: set as `EXTERNAL_ADDRS`. SIP clients use this to reach the proxy. |
| sip | "SIP UDP port to expose?" | Default: `5060/udp` |
| api | "Management API port?" | Default: `51908` TCP |
| tls | "Enable TLS/SRTP for SIP?" | Optional. Requires cert provisioning. |

## Software-layer concerns

- **Image:** `fonoster/routr-one:latest` (all-in-one) or individual component images
- **Ports:**
  - `5060/udp` — SIP signaling
  - `5060/tcp` — SIP over TCP (optional)
  - `5061/tcp` — SIP over TLS (optional)
  - `51908/tcp` — gRPC management API
- **Config:** Environment variables; see upstream docs for full reference
- **Data:** State managed via internal Redis; persistent volume recommended for production
- **CLI:** `rctl` — install from npm (`npm install -g @routr/ctl`)

### Quick start with Docker

```bash
docker run \
  -p 51908:51908 \
  -p 5060:5060/udp \
  -e EXTERNAL_ADDRS=<YOUR_PUBLIC_IP> \
  fonoster/routr-one:latest
```

Verify the container is running:

```bash
docker ps --format 'table {{.ID}}\t{{.Image}}\t{{.Status}}'
```

### Kubernetes with Helm

```bash
helm repo add routr https://routr.io/charts
helm repo update
kubectl create namespace routr
helm install routr routr/routr --namespace routr
```

## Upgrade procedure

1. Pull the new image: `docker pull fonoster/routr-one:latest`
2. Stop and remove the running container
3. Start with the same `docker run` command
4. For Helm: `helm upgrade routr routr/routr --namespace routr`
5. Check release notes at https://github.com/fonoster/routr/releases for breaking changes

## Gotchas

- **`EXTERNAL_ADDRS` is mandatory**: SIP clients must be able to reach this IP. Set it to the public/reachable IP, not `127.0.0.1`.
- **SIP uses UDP**: ensure your firewall/security group allows `5060/udp` inbound.
- **NAT traversal**: if behind NAT, configure `EXTERN_ADDR` correctly or SIP will fail for remote clients.
- **routr-one vs components**: `routr-one` bundles everything; the component images (edgeport, location, dispatcher, etc.) are for advanced/distributed deployments.
- **rctl CLI** is separate from the Docker image — install it independently via npm.

## References

- [Upstream README](https://github.com/fonoster/routr#readme)
- [Official docs](https://routr.io/docs)
- [Docker Hub](https://hub.docker.com/r/fonoster/routr-one)
- [Helm chart](https://routr.io/charts)
