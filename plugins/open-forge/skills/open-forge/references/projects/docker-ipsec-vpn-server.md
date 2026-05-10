---
name: docker-ipsec-vpn-server
description: Recipe for deploying an IPsec VPN server (IKEv2 / L2TP / Cisco IPsec) in Docker. Based entirely on upstream documentation at https://github.com/hwdsl2/docker-ipsec-vpn-server.
---

# IPsec VPN Server on Docker

Docker image to run an IPsec VPN server, supporting **IKEv2**, **IPsec/L2TP**, and **Cisco IPsec (XAuth)** modes. Built on Alpine Linux with [Libreswan](https://libreswan.org) and xl2tpd. Upstream: <https://github.com/hwdsl2/docker-ipsec-vpn-server>. Docker Hub: <https://hub.docker.com/r/hwdsl2/ipsec-vpn-server>.

VPN credentials and IKEv2 certificates are auto-generated on first start. Supports Windows, macOS, iOS, Android, Chrome OS, and Linux clients.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host with a public IP | Docker (Alpine image, ~19 MB) | Default; recommended |
| Any Linux host with a public IP | Docker (Debian image, ~62 MB) | Use hwdsl2/ipsec-vpn-server:debian tag |
| ARM server / Raspberry Pi | Docker | Multi-arch: linux/amd64, linux/arm64, linux/arm/v7 |

Not supported: Docker for Windows; Synology NAS (Debian image only).

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Host public IP or DNS name | Required for client config and firewall rules |
| preflight | VPN username(s) | Defaults to auto-generated if omitted |
| preflight | VPN password(s) | Defaults to auto-generated if omitted |
| preflight | IPsec PSK | Defaults to auto-generated if omitted |
| optional | Custom DNS name for IKEv2 server | FQDN; used in IKEv2 client profiles |
| optional | Custom DNS servers | Default: Google Public DNS (8.8.8.8 / 8.8.4.4) |

## Software-layer concerns

### Environment variables (vpn.env)

Create vpn.env from the upstream example:

```bash
# Leave blank to auto-generate on first start
VPN_IPSEC_PSK=
VPN_USER=
VPN_PASSWORD=
```

Optional extras:

```bash
# IKEv2 DNS name (FQDN)
VPN_DNS_NAME=vpn.example.com
# IKEv2 client profile name (no spaces or special chars except - _)
VPN_CLIENT_NAME=vpnclient
# Custom DNS servers
VPN_DNS_SRV1=1.1.1.1
VPN_DNS_SRV2=1.0.0.1
```

### Data directory

IKEv2 certificates and server config are persisted in named volume ikev2-vpn-data -> /etc/ipsec.d inside the container.

### Ports

| Port | Protocol | Purpose |
|---|---|---|
| 500 | UDP | IKE (IKEv2 + L2TP key exchange) |
| 4500 | UDP | NAT-T (IKEv2 + L2TP over NAT) |

Both ports must be open in any upstream firewall (EC2 security group, GCE firewall rule, etc.).

### Privileged mode

The container requires --privileged and a read-only bind-mount of /lib/modules to manage kernel IPsec and network interfaces.

## Docker Compose deployment

```yaml
volumes:
  ikev2-vpn-data:
    name: ikev2-vpn-data

services:
  vpn:
    image: hwdsl2/ipsec-vpn-server
    restart: always
    env_file:
      - ./vpn.env
    ports:
      - "500:500/udp"
      - "4500:4500/udp"
    privileged: true
    hostname: ipsec-vpn-server
    container_name: ipsec-vpn-server
    volumes:
      - ikev2-vpn-data:/etc/ipsec.d
      - /lib/modules:/lib/modules:ro
```

Deploy:
```bash
cp vpn.env.example vpn.env   # edit as needed
docker compose up -d
docker logs ipsec-vpn-server  # verify startup; check for auto-generated credentials
```

### Retrieve auto-generated credentials

```bash
docker logs ipsec-vpn-server 2>&1 | grep -A 6 "credentials"
```

## Upgrade procedure

```bash
# 1. Pull latest image
docker pull hwdsl2/ipsec-vpn-server

# 2. Note existing VPN credentials (from docker logs or vpn.env)

# 3. Remove and re-create the container
docker rm -f ipsec-vpn-server
docker compose up -d
```

Removing the container does NOT delete the ikev2-vpn-data volume -- certificates and config are preserved.

## Managing IKEv2 users

```bash
# List users
docker exec -it ipsec-vpn-server ikev2.sh --list-clients

# Add a user
docker exec -it ipsec-vpn-server ikev2.sh --addclient newuser

# Remove a user
docker exec -it ipsec-vpn-server ikev2.sh --revokeclient olduser
```

## Gotchas

- User account changes: After editing vpn.env, you must remove and re-create the container. Editing the env file alone has no effect on a running container.
- Windows behind NAT: IPsec/L2TP requires a one-time registry change when either side is behind NAT. Use IKEv2 or XAuth to avoid this.
- Multiple clients behind same NAT: IPsec/L2TP supports only one simultaneous connection per NAT gateway. Use IKEv2 or XAuth for multiple devices at the same location.
- macOS Docker: IPsec/L2TP may require a one-time container restart before it works on Docker for Mac.
- Synology NAS: Only the Alpine-based image is compatible; the Debian image is not.

## Upstream docs

- README: https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/README.md
- Advanced usage: https://github.com/hwdsl2/docker-ipsec-vpn-server/blob/master/docs/advanced-usage.md
- IKEv2 howto: https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/ikev2-howto.md
- L2TP clients: https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients.md
- XAuth clients: https://github.com/hwdsl2/setup-ipsec-vpn/blob/master/docs/clients-xauth.md
