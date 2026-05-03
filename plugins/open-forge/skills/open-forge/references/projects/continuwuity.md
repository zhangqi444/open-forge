# Continuwuity

> Community-driven Matrix homeserver written in Rust. A fork of the archived conduwuit project, aiming for stability, spec compliance, and long-term maintenance. Lightweight enough to run on modest hardware. MIT-licensed.

**Official URL:** https://continuwuity.org  
**Docs:** https://continuwuity.org  
**Primary repo:** https://forgejo.ellis.link/continuwuation/continuwuity  
**GitHub mirror:** https://github.com/continuwuity/continuwuity

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker / Docker Compose | Recommended; official images available |
| Any Linux VPS/VM | Native binary | Pre-built binaries + packages in upstream releases |
| Modest hardware (Pi, small VPS) | Docker or native | Designed to run on low-resource machines |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `server_name` | Your Matrix domain (appears in MXIDs: `@user:server_name`) | `matrix.example.com` |
| Admin username | First user to register will be admin | `@admin:matrix.example.com` |
| Database path | Where RocksDB data is stored | `/var/lib/continuwuity` |
| TURN server | Optional for VoIP/video calls — coturn recommended | `turn:turn.example.com:3478` |

---

## Software-Layer Concerns

### Architecture
- Continuwuity is a single binary + RocksDB (embedded) — no external database required
- Federation requires port 8448 (or a `.well-known` delegation) to be publicly reachable
- A reverse proxy (Caddy/Nginx) is strongly recommended to handle TLS

### Quick Start (Docker Compose)
```yaml
# compose.yaml
services:
  continuwuity:
    image: ghcr.io/continuwuity/continuwuity:latest
    restart: unless-stopped
    ports:
      - "6167:6167"
    volumes:
      - continuwuity_data:/var/lib/continuwuity
      - ./continuwuity.toml:/etc/continuwuity.toml:ro

volumes:
  continuwuity_data:
```

Minimal `continuwuity.toml`:
```toml
[global]
server_name = "example.com"
database_path = "/var/lib/continuwuity"
port = 6167
address = "0.0.0.0"
allow_registration = true          # set false after creating your admin account
```

```bash
docker compose up -d
```

Refer to the full config reference at https://continuwuity.org for all options.

### Reverse Proxy (Caddy example)
```
matrix.example.com {
    reverse_proxy localhost:6167
}
```

For federation, also expose port 8448, or use `.well-known` delegation:
```
# Serve at https://example.com/.well-known/matrix/server
{"m.server": "matrix.example.com:443"}
```

### Migration from conduwuit
Continuwuity's RocksDB database is **compatible** with conduwuit — stop conduwuit, point continuwuity at the same database path, start continuwuity.

### Data Directories
| Path (container) | Purpose |
|------------------|---------|
| `/var/lib/continuwuity` | RocksDB database — must be persisted |

### Ports
- Default app port: `6167` (configurable)
- Federation port: `8448` (or delegate via `.well-known`)

---

## Upgrade Procedure

1. Pull new image: `docker compose pull`
2. Restart: `docker compose up -d`
3. Continuwuity handles RocksDB migrations automatically on startup
4. Check release notes at https://forgejo.ellis.link/continuwuation/continuwuity/releases for breaking changes

---

## Gotchas

- **`allow_registration` should be disabled after setup** — leaving it open allows anyone to register on your homeserver; set `allow_registration = false` and use invitation tokens if you want controlled registration
- **`server_name` is permanent** — the `server_name` in the config is baked into all MXIDs and room aliases; changing it later requires a full data migration; choose carefully
- **Not compatible with Conduit, Dendrite, or Synapse databases** — only conduwuit databases can be carried over; all others require a fresh start
- **Federation requires public reachability on port 8448 or .well-known** — homeservers that can't be reached by other Matrix servers will be island-only (no federation)
- **Nightly builds are cutting-edge** — the `main` branch has nightly images; for stability use tagged releases
- **VoIP requires a TURN server** — without coturn (or similar), audio/video calls through the homeserver will fail for users behind NAT

---

## Links
- Docs: https://continuwuity.org
- Primary repo: https://forgejo.ellis.link/continuwuation/continuwuity
- GitHub mirror: https://github.com/continuwuity/continuwuity
- Matrix room: https://matrix.to/#/#continuwuity:continuwuity.org
- Releases: https://forgejo.ellis.link/continuwuation/continuwuity/releases
