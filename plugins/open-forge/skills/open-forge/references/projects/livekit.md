---
name: livekit-project
description: LiveKit recipe for open-forge. Real-time video, audio, and data via scalable WebRTC SFU. Apache 2.0.
---

# LiveKit

Scalable, open-source WebRTC SFU (Selective Forwarding Unit) for real-time video, audio, and data. Single binary or Docker deployment. Ecosystem services cover recording/streaming (Egress), ingest (Ingress), and AI agent participants (Agents). Upstream: <https://github.com/livekit/livekit>. Docs: <https://docs.livekit.io>.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (single container) | <https://docs.livekit.io/home/self-hosting/local/> | ✅ | Quickest path; suitable for single-node production with a YAML config file. |
| Docker Compose | <https://docs.livekit.io/home/self-hosting/local/> | ✅ | Single-node with optional Redis, Egress, Ingress, and Agents services. |
| Single binary | <https://github.com/livekit/livekit/releases> | ✅ | Bare-metal or VM; download the binary and run with `--config`. |
| Multi-node (distributed) | <https://docs.livekit.io/home/self-hosting/distributed/> | ✅ | Horizontal scale; requires Redis for shared room state. |
| LiveKit Cloud (managed) | <https://livekit.io/cloud> | ✅ | Out of scope for open-forge — hosted service, no install. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Single-node or multi-node cluster?" | `single` / `multi` | Multi-node requires Redis |
| network | "What is the server's public IP address?" | IPv4 | Required for `rtc.nat_ip` when behind NAT or on a cloud VM |
| network | "Are UDP ports 7882+ reachable from the internet?" | Confirm / describe firewall | WebRTC media will not work without UDP reachability |
| keys | "API key and secret for production use?" | Free-text (sensitive) | Replace the default `devkey`/`devsecret` pair |
| redis | "Redis connection URL?" | `redis://host:6379` | Required for multi-node; optional for single-node |
| tls | "Reverse proxy for HTTPS (nginx, Caddy, etc.)?" | Free-text | LiveKit itself is plain HTTP; TLS must be terminated upstream |

## Software-layer concerns

### Ports

| Port | Protocol | Purpose |
|---|---|---|
| 7880 | TCP | HTTP API / WebSocket signalling |
| 7881 | TCP | WebRTC TCP fallback |
| 7882 | UDP | WebRTC media (primary) |

All three ports must be reachable from clients. For WebRTC, UDP is preferred; TCP is the fallback.

### Config file (`livekit.yaml`)

```yaml
port: 7880
keys:
  your_api_key: your_api_secret   # change for production
rtc:
  tcp_port: 7881
  udp_port: 7882
  use_external_ip: true            # auto-detect public IP via STUN
  # nat_ip: 1.2.3.4               # set explicitly when auto-detect fails
# redis:                           # required for multi-node
#   address: redis:6379
```

Config path (Docker): `/etc/livekit.yaml` (mount via volume).

### Docker Compose example

```yaml
services:
  livekit:
    image: livekit/livekit-server:latest
    ports:
      - "7880:7880"
      - "7881:7881"
      - "7882:7882/udp"
    volumes:
      - ./livekit.yaml:/etc/livekit.yaml
    command: --config /etc/livekit.yaml
    restart: unless-stopped
```

Start with:

```bash
docker compose up -d
```

### Dev quickstart (no config file)

```bash
# Ephemeral dev server — do NOT use in production
docker run --rm \
  -p 7880:7880 -p 7881:7881 -p 7882:7882/udp \
  livekit/livekit-server --dev
```

The `--dev` flag auto-generates an insecure key pair. It is printed to stdout on startup and is not suitable for any production workload.

### TLS (reverse proxy)

LiveKit runs plain HTTP on port 7880. For HTTPS/WSS (required for browser-based WebRTC), terminate TLS in nginx or Caddy and proxy to `localhost:7880`.

Minimal Caddy snippet:

```
meet.example.com {
    reverse_proxy localhost:7880
}
```

### Ecosystem services (separate containers)

| Service | Image | Purpose |
|---|---|---|
| Egress | `livekit/egress` | Record or stream rooms to file / RTMP |
| Ingress | `livekit/ingress` | Ingest RTMP / WHIP sources into rooms |
| Agents | `livekit/agents` framework | AI participants (Python/TypeScript SDK) |

Each service requires its own YAML config and a Redis connection. See <https://docs.livekit.io/home/self-hosting/local/> for compose examples with all services.

### Data directories

LiveKit itself is stateless — no persistent data directories. Room state is held in-memory (single-node) or Redis (multi-node). Recordings produced by Egress are written to the path configured in the Egress config (local dir or S3-compatible storage).

## Upgrade procedure

```bash
# Docker Compose
docker compose pull
docker compose up -d

# Single binary
# Download new binary from https://github.com/livekit/livekit/releases
# Replace the binary and restart the service
```

No database migrations. Config file format is stable across minor versions; check release notes for breaking changes on major bumps.

## Gotchas

- **UDP must be reachable from the internet.** WebRTC media travels over UDP. If your firewall blocks inbound UDP on port 7882 (or your configured media UDP port range), clients will fall back to TCP (7881) or fail entirely. Verify with a tool like `netcat` from outside the network.
- **NAT IP must be set explicitly when auto-detect fails.** `use_external_ip: true` works on most cloud VMs but can fail on complex NAT setups. If clients can't connect media, set `rtc.nat_ip` to your server's public IP.
- **`--dev` flag is insecure.** The dev key pair is printed to stdout and is the same on every run. Never expose a `--dev` server to the public internet.
- **Multi-node requires Redis.** Without Redis, multiple LiveKit instances each maintain independent room state — clients connecting to different nodes for the same room will not see each other.
- **LiveKit does not terminate TLS.** Put nginx, Caddy, or a similar reverse proxy in front for HTTPS. Browsers require WSS (secure WebSocket) for WebRTC in most contexts.
- **Egress and Ingress are separate services.** They are not included in the base `livekit/livekit-server` image. Each requires its own config file and Redis connection.
- **Port mapping for UDP.** If running Docker behind a host-level NAT or in a cloud environment, ensure the UDP port mapping is correct. Docker's default NAT can interfere with UDP — test end-to-end before declaring the deployment production-ready.

## Links

- GitHub: <https://github.com/livekit/livekit>
- Docs: <https://docs.livekit.io>
- Self-hosting guide: <https://docs.livekit.io/home/self-hosting/local/>
- Distributed deployment: <https://docs.livekit.io/home/self-hosting/distributed/>
- Egress: <https://github.com/livekit/egress>
- Ingress: <https://github.com/livekit/ingress>
- Agents framework: <https://github.com/livekit/agents>
- License: Apache 2.0
- Stars: ~12K
