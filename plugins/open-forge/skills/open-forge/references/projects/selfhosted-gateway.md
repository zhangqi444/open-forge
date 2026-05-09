---
name: selfhosted-gateway
description: selfhosted-gateway recipe for open-forge. Covers the two-component (gateway + client link) setup to expose Docker Compose services to the public Internet via a WireGuard/Caddy/NGINX RPoVPN tunnel — without exposing the home IP or requiring port-forwarding. Source: https://github.com/hintjen/selfhosted-gateway. License: AGPL-3.0.
---

# Selfhosted Gateway

Docker-native, entirely self-hosted alternative to Cloudflare Tunnels, Tailscale Funnel, and ngrok. Automates Reverse Proxy-over-VPN (RPoVPN) WireGuard tunnels so Docker Compose services running at home can be reached on the public Internet — without exposing your home IP, without static IPs, and without port-forwarding. Upstream: <https://github.com/hintjen/selfhosted-gateway>.

Built on battle-tested open-source components:
- **WireGuard** — encrypted tunnel between client and gateway.
- **NGINX** — gateway-side reverse proxy distributing requests to per-service tunnel endpoints.
- **Caddy** — client-side TLS termination with automatic Let's Encrypt/ZeroSSL certs.

## Use cases

- Self-hosting behind CGNAT (Starlink, mobile ISPs) where port-forwarding isn't possible.
- Hiding your home's public IP address from the internet.
- Securely exposing specific Docker services (Nextcloud, Immich, Gitea, etc.) via a cloud VPS acting as the public entry point.

## Architecture

Two roles:

| Role | Where it runs | What it does |
|---|---|---|
| **Gateway** | Public VPS (Hetzner, DigitalOcean, Linode, etc.) | NGINX receives inbound HTTPS traffic for `*.yourdomain.com` and routes each subdomain to the appropriate WireGuard tunnel endpoint. |
| **Client link** | Your home machine | A sidecar container added to your existing Docker Compose stack. Establishes a WireGuard tunnel to the gateway and runs Caddy for TLS. |

## Prerequisites

- A domain with the ability to create an `A` record.
- A publicly addressable Linux VPS with:
  - Ports 80 and 443 open (HTTP/HTTPS).
  - The ephemeral UDP port range open to the internet (check: `cat /proc/sys/net/ipv4/ip_local_port_range`).
  - `docker`, `git`, and `make` installed.
- Your local machine with `docker`, `git`, and `make` installed.

---

## Setup

### Step 1 — DNS

Point a wildcard A record `*.yourdomain.com` to the public IPv4 (and optionally IPv6) address of your VPS. Allow time for propagation before proceeding.

### Step 2 — Gateway setup (on the VPS)

```bash
# SSH into the VPS
git clone https://github.com/hintjen/selfhosted-gateway.git
cd selfhosted-gateway
make docker     # install Docker if not present
make setup      # interactive: enter your domain (e.g. yourdomain.com)
make gateway    # start the NGINX gateway container
```

The `make setup` step writes a `.env` file with the domain and generates the gateway's WireGuard key pair. `make gateway` starts the NGINX container listening on ports 80 and 443.

### Step 3 — Generate a link config (on your local machine)

For each Docker service you want to expose, run:

```bash
git clone https://github.com/hintjen/selfhosted-gateway.git
cd selfhosted-gateway
make docker

# Replace values:
#   GATEWAY  = SSH address of your VPS (e.g. root@1.2.3.4)
#   FQDN     = the public subdomain (e.g. myapp.yourdomain.com)
#   EXPOSE   = container-name:port (e.g. myapp:3000)
make link GATEWAY=root@1.2.3.4 FQDN=myapp.yourdomain.com EXPOSE=myapp:3000
```

This command:
1. SSHs into the VPS to provision a new gateway-side link container.
2. Generates a WireGuard key pair for this link.
3. Prints a `link:` Docker Compose snippet and writes an `.env` file (e.g. `./myapp-yourdomain-com.env`).

### Step 4 — Add the link sidecar to your Compose stack

Copy the printed snippet into your existing `docker-compose.yml`:

```yaml
# Your existing service
services:
  myapp:
    image: myapp:latest
    # ... your existing config ...

  # Add this sidecar alongside your service
  link:
    image: fractalnetworks/gateway-client:latest
    environment:
      LINK_DOMAIN: myapp.yourdomain.com
      EXPOSE: myapp:3000
      GATEWAY_CLIENT_WG_PRIVKEY: <generated-private-key>
      GATEWAY_LINK_WG_PUBKEY: <gateway-public-key>
      GATEWAY_ENDPOINT: 1.2.3.4:49185
    cap_add:
      - NET_ADMIN
```

Or use the generated `.env` file:

```bash
docker compose --env-file ./myapp-yourdomain-com.env up -d
```

### Step 5 — Start your stack

```bash
docker compose up -d
```

The link sidecar establishes the WireGuard tunnel, Caddy obtains a TLS certificate, and your service becomes reachable at `https://myapp.yourdomain.com`.

Repeat steps 3–5 for each additional service you want to expose.

---

## Optional — Basic authentication

To password-protect a link, set `BASIC_AUTH` on the link container:

```yaml
link:
  image: fractalnetworks/gateway-client:latest
  environment:
    LINK_DOMAIN: myapp.yourdomain.com
    EXPOSE: myapp:3000
    BASIC_AUTH: "username:password"
    GATEWAY_CLIENT_WG_PRIVKEY: <key>
    GATEWAY_LINK_WG_PUBKEY: <key>
    GATEWAY_ENDPOINT: 1.2.3.4:49185
  cap_add:
    - NET_ADMIN
```

## Optional — Forward-only mode (no SSL termination in Caddy)

If you already run a local reverse proxy (e.g. Traefik) that handles TLS, use `FORWARD_ONLY=true` so Caddy just passes traffic through without terminating SSL:

```yaml
link:
  image: fractalnetworks/gateway-client:latest
  environment:
    LINK_DOMAIN: myapp.yourdomain.com
    EXPOSE: myapp:443
    EXPOSE_HTTPS: myapp:443
    FORWARD_ONLY: "true"
    GATEWAY_CLIENT_WG_PRIVKEY: <key>
    GATEWAY_LINK_WG_PUBKEY: <key>
    GATEWAY_ENDPOINT: 1.2.3.4:49185
  cap_add:
    - NET_ADMIN
```

In this mode, resolve `*.yourdomain.com` to your local Traefik on your LAN DNS, and to the VPS on external DNS.

## Optional — TCP/UDP proxy (socat)

To tunnel generic TCP/UDP traffic (e.g. a game server, SSH alternative):

Set `EXPOSE_UDP` for UDP or use `EXPOSE_TCP` for raw TCP alongside the `EXPOSE` variable. See the upstream README for the socat integration details.

---

## Verify

```bash
# On the VPS — check gateway containers are running
docker ps | grep gateway

# From any machine
curl -sI https://myapp.yourdomain.com/    # should return HTTP 200 with valid TLS cert
```

---

## Lifecycle

```bash
# Gateway (on VPS)
cd selfhosted-gateway
docker compose logs gateway                      # gateway logs
docker compose restart gateway                   # restart

# Client link (on local machine)
docker compose logs link                          # link/Caddy logs
docker compose restart link                       # reconnect tunnel
```

To decommission a link:

```bash
# On VPS
cd selfhosted-gateway
make remove-link FQDN=myapp.yourdomain.com       # stops and removes the gateway link container
```

---

## Gotchas

- **Wildcard DNS must be set up before generating the first link.** `make link` SSHs to the VPS to provision the gateway-side link container — if DNS isn't resolving yet, TLS cert provisioning will fail on first request.
- **`cap_add: NET_ADMIN` is required on the link container.** WireGuard needs elevated network capabilities to create tunnel interfaces.
- **Each exposed service gets its own link sidecar.** There is no shared link container; one sidecar per subdomain/service.
- **The link container must be in the same Docker network as the service it exposes.** The `EXPOSE` variable references the service by its container name — this only works if they share a network (default Compose network is fine).
- **Caddy obtains TLS certs on first request.** The very first browser hit to a new subdomain may show a brief delay or self-signed warning while Caddy provisions the cert. Subsequent requests are instant.
- **Ephemeral UDP ports must be open on the VPS.** The WireGuard tunnel uses a random port from the ephemeral range. Open the full `ip_local_port_range` in your VPS firewall (`cat /proc/sys/net/ipv4/ip_local_port_range` to check the range).
- **Not a managed service.** Unlike Cloudflare Tunnels, you own and manage both the VPS and the gateway stack. Budget for VPS costs and uptime management.
