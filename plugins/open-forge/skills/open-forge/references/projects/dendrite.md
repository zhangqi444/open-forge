---
name: dendrite
description: Dendrite recipe for open-forge. Second-generation Matrix homeserver written in Go. Monolith mode with SQLite or PostgreSQL. NOTE: Dendrite is in maintenance mode as of 2024 — security fixes only. For new deployments consider Synapse or conduwuit/Tuwunel.
---

# Dendrite

Second-generation Matrix homeserver written in Go. Upstream: <https://github.com/element-hq/dendrite>. Docs: <https://element-hq.github.io/dendrite/>.

> ⚠️ **Dendrite is in maintenance mode as of 2024.** Only security fixes are being applied. For new production deployments, consider Synapse (fully-featured) or conduwuit/Tuwunel (lightweight Rust alternatives). This recipe is for existing Dendrite operators and anyone who specifically needs a lightweight Go homeserver.

Dendrite runs in monolith mode as a single binary (recommended for self-hosting), backed by SQLite or PostgreSQL. The Docker image is published at `ghcr.io/element-hq/dendrite`. Schema migrations run automatically on startup.

| | |
|---|---|
| **License** | Apache 2.0 |
| **Stars** | ~5 K |
| **GitHub** | <https://github.com/element-hq/dendrite> (moved from `matrix-org/dendrite` in 2023) |
| **Docs** | <https://element-hq.github.io/dendrite/> |

## Compatible install methods

| Method | Upstream docs | First-party? | When to use |
|---|---|---|---|
| Docker Compose (monolith + PostgreSQL) | <https://element-hq.github.io/dendrite/> | ✅ | Recommended production path. PostgreSQL for any real usage. |
| Docker Compose (monolith + SQLite) | <https://element-hq.github.io/dendrite/> | ✅ | Dev / small personal instance only. Not suitable for production. |

## Inputs to collect

Phase-keyed prompts. Ask at the phase where each is needed.

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Which database backend?" | Options: `PostgreSQL (production)` / `SQLite (dev only)` | Determines Compose template and config. |
| infra | "What is the public hostname of the server?" | Free-text | Both paths. |
| network | "What is the Matrix server name? (e.g. `example.com` — becomes part of every user's MXID)" | Free-text | Both paths. Immutable after first run. |
| network | "Will you run federation on port 8448, or use well-known delegation?" | Options: `Port 8448` / `Well-known delegation` | Both paths. Determines firewall rules. |
| network | "Do you have a valid TLS certificate trusted by standard CAs for the server hostname?" | Confirm | Both paths. Required for federation. |
| software | "PostgreSQL password for the Dendrite DB user?" | Free-text (sensitive) | PostgreSQL path only. |

After each prompt, write the value into the state file under `inputs.*`.

## Software-layer concerns

### Key ports

| Port | Protocol | Purpose |
|---|---|---|
| 8008 | TCP | Matrix client-server HTTP API |
| 8448 | TCP | Matrix federation (open this OR use well-known delegation) |

### Config file

**Path:** `./dendrite.yaml` (mounted into the container at `/etc/dendrite/dendrite.yaml`)

Generate a skeleton config:

```bash
docker run --rm \
  ghcr.io/element-hq/dendrite:latest \
  generate-config -server example.com > dendrite.yaml
```

Generate the signing key (required — each homeserver has a unique identity key):

```bash
docker run --rm \
  -v ./:/mnt \
  ghcr.io/element-hq/dendrite:latest \
  generate-keys --private-key /mnt/matrix_key.pem
```

Set the `private_key` path in `dendrite.yaml` to point to `matrix_key.pem`.

### Data directories

| Path | Contents |
|---|---|
| `dendrite-media` volume | User-uploaded media files. Grows unboundedly — plan disk space accordingly. |
| `pg-data` volume | PostgreSQL data files (PostgreSQL path). |

### Docker Compose (monolith + PostgreSQL)

```yaml
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: dendrite
      POSTGRES_PASSWORD: dendrite
      POSTGRES_MULTIPLE_DATABASES: dendrite
    volumes:
      - pg-data:/var/lib/postgresql/data
    restart: unless-stopped

  dendrite:
    image: ghcr.io/element-hq/dendrite:latest
    ports:
      - "8008:8008"
      - "8448:8448"
    volumes:
      - ./dendrite.yaml:/etc/dendrite/dendrite.yaml
      - dendrite-media:/var/dendrite/media
    depends_on:
      - postgres
    restart: unless-stopped

volumes:
  pg-data:
  dendrite-media:
```

### Well-known delegation (if not on port 8448)

Serve at `/.well-known/matrix/server` on your `server_name` domain:

```json
{"m.server": "matrix.example.com:443"}
```

## Upgrade procedure

```bash
docker pull ghcr.io/element-hq/dendrite:latest
docker compose up -d
```

Database schema migrations run **automatically on startup** — no manual migration step required. Review the changelog before upgrading to catch any breaking changes.

## Gotchas

- **Dendrite is in maintenance mode.** As of 2024, only security fixes are applied. Feature development has stopped. Not recommended for new production deployments unless a lightweight Go homeserver is a specific requirement.
- **Missing MSC4186 (Simplified Sliding Sync) and MSC3861 (OIDC auth).** Element X clients use Simplified Sliding Sync for their sync protocol and expect OIDC for authentication. Dendrite implements neither, so Element X users will have an incomplete or non-functional experience.
- **Media storage grows unboundedly.** Every file uploaded by users accumulates in the media volume. Configure `media_retention` settings in `dendrite.yaml` and plan disk space accordingly from day one.
- **SQLite is unsuitable for production.** SQLite works for development and small personal instances but degrades under concurrent load. Use PostgreSQL 13+ for any deployment with more than one or two active users.
- **Federation requires a CA-trusted TLS certificate.** Self-signed certificates are not accepted for Matrix federation. Use Let's Encrypt or another trusted CA. The certificate must be valid for the hostname used in SRV records or well-known delegation.
- **`server_name` is immutable after first run.** Like all Matrix homeservers, changing the server name after the database is initialised breaks federation and all existing user IDs.

## Links

- GitHub: <https://github.com/element-hq/dendrite>
- Docs: <https://element-hq.github.io/dendrite/>
- Docker image: <https://ghcr.io/element-hq/dendrite>
- Matrix Spec (federation): <https://spec.matrix.org/latest/server-server-api/>
- Synapse (full-featured alternative): <https://github.com/element-hq/synapse>
- Tuwunel (lightweight Rust alternative): <https://tuwunel.chat>
