---
name: bore
description: Recipe for self-hosting bore, a simple TCP tunnel server in Rust that exposes local ports to a remote server — similar to ngrok but fully self-hostable. Based on upstream documentation at https://github.com/ekzhang/bore.
---

# bore

A modern, simple TCP tunnel in Rust. Exposes local ports to a remote server, bypassing NAT/firewall restrictions. Similar to ngrok or localtunnel but designed to be trivially self-hosted. Upstream: <https://github.com/ekzhang/bore>. Stars: 11k+.

bore has two components:
- **Server** (`bore server`) — runs on the public host; listens for client registrations and proxies incoming connections
- **Client** (`bore local`) — runs on the local machine; connects to the server and forwards a local port

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux VPS | Docker (single binary container) | Recommended for server |
| Any Linux VPS | Binary / systemd | Minimal setup; 400 LOC Rust binary |
| Any machine | Cargo install | Dev/local use |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Server public IP or hostname | Clients connect to this address |
| preflight | Optional shared secret | Prevents server from being used by others |
| optional | Min/max port range | Default: 1024-65535 for tunnels |
| optional | Bind address | Default: 0.0.0.0 |

## Software-layer concerns

### Control port

bore uses TCP port **7835** as the implicit control port for client-server handshakes. This port must be open in your firewall.

### Tunnel ports

Each `bore local` session is assigned a random TCP port in the configured range (default 1024-65535). Open a range of ports in your firewall/security group if you want to allow multiple simultaneous tunnels.

### Authentication

bore uses HMAC challenge-response. Set a shared secret to prevent unauthorized use:

```bash
# Server
bore server --secret my_secret_string

# Client
bore local 8080 --to yourserver.example.com --secret my_secret_string
```

Secret can also be set via `BORE_SECRET` environment variable on both sides.

### No TLS encryption by default

bore tunnels are not encrypted beyond the initial HMAC handshake. For sensitive traffic, run bore inside a WireGuard/Tailscale tunnel or behind a TLS-terminating reverse proxy.

## Docker deployment (server)

```bash
docker run -it --init --rm --network host \
  ekzhang/bore server --secret my_secret_string
```

For persistent / restarting server, use Compose:

```yaml
services:
  bore:
    image: ekzhang/bore
    restart: unless-stopped
    network_mode: host
    command: server --secret "${BORE_SECRET}"
    environment:
      - BORE_SECRET=${BORE_SECRET}
```

Note: `network_mode: host` is the simplest way to expose all tunnel ports without enumerating them individually.

## Binary deployment (server, systemd)

```bash
# Install
cargo install bore-cli
# Or download prebuilt binary from https://github.com/ekzhang/bore/releases

# Run server
bore server --secret my_secret_string
```

Sample systemd unit (`/etc/systemd/system/bore.service`):

```ini
[Unit]
Description=bore TCP tunnel server
After=network.target

[Service]
ExecStart=/usr/local/bin/bore server --secret YOUR_SECRET
Restart=always
User=nobody

[Install]
WantedBy=multi-user.target
```

## Client usage

```bash
# Forward local port 8080 to remote server (assigned port printed on startup)
bore local 8080 --to yourserver.example.com --secret my_secret_string

# Forward to a specific remote port
bore local 8080 --to yourserver.example.com --port 9000 --secret my_secret_string
```

## Server options reference

```
bore server [OPTIONS]
  --min-port <MIN_PORT>          Minimum accepted TCP port [default: 1024]
  --max-port <MAX_PORT>          Maximum accepted TCP port [default: 65535]
  --secret <SECRET>              Optional authentication secret [env: BORE_SECRET]
  --bind-addr <BIND_ADDR>        IP to bind to [default: 0.0.0.0]
  --bind-tunnels <BIND_TUNNELS>  IP for tunnel listeners (defaults to --bind-addr)
```

## Upgrade procedure

```bash
# Docker: pull new image and restart
docker compose pull && docker compose up -d

# Cargo: reinstall
cargo install bore-cli --force
```

No persistent data — bore is stateless. Upgrading is always safe.

## Gotchas

- Port 7835 must be open on the server for client connections; tunnel ports (1024-65535 by default) must also be accessible.
- bore does not encrypt tunnel traffic — only the initial handshake is authenticated. Use a VPN or TLS proxy for sensitive data.
- `network_mode: host` in Docker exposes all host ports; scope the tunnel port range with `--min-port`/`--max-port` if desired.
- Connections are held for max 10 seconds server-side if the client doesn't accept them — brief disconnects may drop in-flight requests.
- There is no web UI or admin dashboard — bore is a pure CLI/daemon tool.

## Upstream docs

- README: https://github.com/ekzhang/bore/blob/main/README.md
- Releases (prebuilt binaries): https://github.com/ekzhang/bore/releases
