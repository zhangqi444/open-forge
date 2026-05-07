---
name: cardea
description: Cardea recipe for open-forge. SSH bastion server with access control, session recording, and optional TPM-backed key protection. Go + Docker, no database. Source: https://github.com/hectorm/cardea
---

# Cardea

An SSH bastion (jump host) server with access control, session recording, and optional TPM-backed private key protection. Clients connect through Cardea to backend servers using standard SSH clients — no special client software needed. Access rules live in a flat file (authorized_keys format), versioned like code. Sessions recorded in asciinema v3 format. No database, no web UI. EUPL-1.2 licensed, written in Go. Upstream: <https://github.com/hectorm/cardea>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux VPS | Docker (single container) | Official image on GHCR and Docker Hub |
| Any Linux VPS | Prebuilt binary | Download from GitHub releases |
| Hardware with TPM | Docker | Mount `/dev/tpmrm0` for TPM key protection |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "SSH port for Cardea bastion?" | Number | Default 2222; expose publicly |
| "Session recordings directory?" | Path | Optional; set for asciinema recording |
| "TPM key protection?" | Yes / No | Requires `/dev/tpmrm0` — optional |
| "Backend servers to allow access to?" | host:port list | Encoded in authorized_keys per user |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "User public keys to authorize?" | SSH public keys | Added to authorized_keys with permitconnect rules |
| "Unknown hosts policy?" | strict / tofu | `tofu` = trust on first use; `strict` = require known_hosts pre-seeding |
| "Rate limit per IP?" | Number | Default 10 unauthenticated requests per 5 min |

## Software-Layer Concerns

- **No database**: All configuration in flat files — authorized_keys, known_hosts, private key. Mount as a `data/` bind volume.
- **authorized_keys format**: Extended format — each line is a public key with `permitconnect` options defining which backends that key can reach. Example: `permitconnect="alice@10.0.1.1:22" ssh-ed25519 AAAA...`
- **Bastion key on backends**: Cardea's own public key must be added to `authorized_keys` on every backend server it connects to.
- **Session recordings**: Stored in asciinema v3 format; configurable retention time and max disk usage.
- **Health/metrics endpoint**: Exposes HTTP health + Prometheus metrics at `localhost:9222` by default.
- **TPM mode**: Binds the bastion's private key to the TPM chip — prevents extraction even with root access. Requires `/dev/tpmrm0`.
- **TOFU vs strict**: In `tofu` mode, Cardea trusts backend host keys on first connect and records them in known_hosts. `strict` mode requires known_hosts to be pre-populated.
- **Reproducible builds**: Releases include provenance attestation — verify with `gh attestation verify`.

## Deployment

### Docker (simple)

```bash
mkdir -p ./data

docker run -d \
  -p 2222:2222 \
  -u "$(id -u):$(id -g)" \
  --mount type=bind,src=./data/,dst=/data/ \
  ghcr.io/hectorm/cardea:v1
```

### Docker Compose

```yaml
services:
  cardea:
    image: ghcr.io/hectorm/cardea:v1
    ports:
      - "2222:2222"
    user: "1000:1000"
    volumes:
      - type: bind
        source: ./data/
        target: /data/
      - type: tmpfs
        target: /run/
      - type: tmpfs
        target: /tmp/
    environment:
      CARDEA_UNKNOWN_HOSTS_POLICY: "tofu"
      CARDEA_RECORDINGS_DIR: "/data/recordings"
      CARDEA_LOG_LEVEL: "info"
    restart: always
```

### Authorized keys setup

```bash
# data/authorized_keys — one entry per user:
# permitconnect defines which backend:port this key can reach

permitconnect="alice@10.0.1.1:22" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5... alice

# Multiple backends:
permitconnect="bob@web-server:22,bob@db-server:22" ssh-ed25519 AAAAC3Nza... bob

# Glob patterns:
permitconnect="alice@*.internal" ssh-ed25519 AAAAC3Nza... alice-wildcard
```

### Client usage

```bash
# Connect to backend via Cardea
ssh -p 2222 alice@10.0.1.1@cardea.example.com

# Or using + delimiter
ssh -p 2222 alice+10.0.1.1@cardea.example.com

# SSH config for convenience
cat >> ~/.ssh/config << 'EOF'
Host my-backend
    HostName cardea.example.com
    Port 2222
    User alice@10.0.1.1
EOF
ssh my-backend
```

## Upgrade Procedure

1. Pull new image: `docker compose pull && docker compose up -d`
2. Cardea state lives entirely in `./data/` — persists across upgrades.
3. Check release notes at https://github.com/hectorm/cardea/releases for config changes.

## Gotchas

- **Bastion key must be on backends**: Generate or find Cardea's public key from `data/` and add it to `~/.ssh/authorized_keys` on every backend server.
- **`permitconnect` is required per key**: A public key with no `permitconnect` option cannot connect to any backend.
- **TOFU vs strict**: Use `strict` for production — pre-populate `data/known_hosts` from each backend's host key. `tofu` is convenient for initial setup but is vulnerable to MITM on first connect.
- **Port 2222 exposed, port 9222 is local-only**: The metrics/health port binds to `localhost:9222` by default — don't expose publicly.
- **TPM requires device pass-through**: Add `devices: ["/dev/tpmrm0:/dev/tpmrm0"]` to compose and set `CARDEA_KEY_STRATEGY=tpm`.
- **Non-root container**: Run as a non-root user (default in the provided command) — `data/` directory must be writable by that UID.

## Links

- Source: https://github.com/hectorm/cardea
- Releases: https://github.com/hectorm/cardea/releases
- Docker image (GHCR): https://github.com/hectorm/cardea/pkgs/container/cardea
- Docker Hub: https://hub.docker.com/r/hectorm/cardea
