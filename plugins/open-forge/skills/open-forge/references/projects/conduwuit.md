---
name: conduwuit
description: conduwuit recipe for open-forge. High-performance Matrix chat homeserver written in Rust (fork of Conduit). Single binary or Docker. NOTE: conduwuit development has ended; the successor project is Tuwunel (https://tuwunel.chat).
---

# conduwuit

High-performance Matrix chat homeserver written in Rust. Fork of Conduit. Upstream: <https://github.com/girlbossceo/conduwuit>. Docs: <https://conduwuit.puppyirl.gay/>.

> ⚠️ **conduwuit development has ended.** The successor project is **Tuwunel** at <https://tuwunel.chat>. For new deployments, use Tuwunel or Synapse. This recipe documents conduwuit as it existed for anyone maintaining an existing installation.

conduwuit runs as a single binary or Docker container with very low resource requirements. It uses an embedded RocksDB database — no external database required. Matrix federation is supported natively.

| | |
|---|---|
| **License** | Apache 2.0 |
| **Stars** | ~3 K |
| **GitHub** | <https://github.com/girlbossceo/conduwuit> |
| **Docs** | <https://conduwuit.puppyirl.gay/> |
| **Successor** | Tuwunel — <https://tuwunel.chat> |

## Compatible install methods

| Method | Upstream docs | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://conduwuit.puppyirl.gay/> | ✅ | Easiest path; recommended for containerised deployments. |
| Single binary | <https://conduwuit.puppyirl.gay/> | ✅ | Bare-metal or VM installs without Docker. |

## Inputs to collect

Phase-keyed prompts. Ask at the phase where each is needed.

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Which install method?" | Options: `Docker Compose` / `Single binary` | Drives which method section loads. |
| infra | "What is the public IP / hostname of the server?" | Free-text | Both methods. |
| network | "What is the Matrix server name? (e.g. `example.com` — this becomes part of every user's MXID)" | Free-text | Both methods. Cannot be changed after first run. |
| network | "Will you run on port 8448 (default Matrix federation port) or use well-known delegation?" | Options: `Port 8448` / `Well-known delegation` | Both methods. Determines firewall and reverse proxy setup. |
| network | "If using well-known delegation: what is the public hostname where Matrix client/federation traffic arrives? (e.g. `matrix.example.com`)" | Free-text | Well-known delegation path only. |
| software | "Where should the RocksDB data directory live?" | Free-text (default: `/var/lib/conduwuit`) | Both methods. Must be on an SSD. |

After each prompt, write the value into the state file under `inputs.*`.

## Software-layer concerns

### Key ports

| Port | Protocol | Purpose |
|---|---|---|
| 6167 | TCP | Matrix client and federation HTTP API (default) |
| 8448 | TCP | Matrix federation (standard port — open this OR set up well-known delegation) |

### Config file

**Path:** `/etc/conduwuit/conduwuit.toml` (TOML format, mounted into the container)

Minimal `conduwuit.toml`:

```toml
[global]
server_name = "example.com"
database_backend = "rocksdb"
database_path = "/var/lib/conduwuit"
port = 6167
```

Key settings:

| Setting | Description |
|---|---|
| `server_name` | Your Matrix domain (part of every MXID — immutable after first run) |
| `database_backend` | Always `"rocksdb"` — the only supported backend |
| `database_path` | Where RocksDB stores data |
| `port` | HTTP port conduwuit listens on (default `6167`) |

### Data directory

RocksDB database at the path set in `database_path`. Must reside on a fast disk (SSD strongly preferred).

### Docker Compose

```yaml
services:
  conduwuit:
    image: girlbossceo/conduwuit:latest
    ports:
      - "6167:6167"
    volumes:
      - ./conduwuit.toml:/etc/conduwuit/conduwuit.toml
      - conduwuit-data:/var/lib/conduwuit
    restart: unless-stopped

volumes:
  conduwuit-data:
```

### Well-known delegation (if not on port 8448)

Serve the following JSON at `/.well-known/matrix/server` on your `server_name` domain (via a reverse proxy or static file):

```json
{"m.server": "matrix.example.com:443"}
```

This tells other Matrix servers where to find your homeserver without requiring port 8448 to be open.

## Upgrade procedure

**Docker Compose:**

```bash
docker pull girlbossceo/conduwuit:latest
docker compose up -d
```

RocksDB data is in the named volume and persists across image updates.

## Gotchas

- **conduwuit is no longer maintained.** Development ended; the project's successor is Tuwunel (<https://tuwunel.chat>). For new deployments, use Tuwunel or Synapse. This recipe exists for existing conduwuit operators.
- **`server_name` is immutable after first run.** The Matrix server name becomes part of every user ID and room alias. It cannot be changed after the database is initialised without breaking federation and all existing user accounts.
- **Matrix federation requires correct DNS or well-known delegation.** Either port 8448 must be open and reachable, OR you must serve a valid `/.well-known/matrix/server` file. Without one of these, your server cannot federate with the broader Matrix network.
- **RocksDB degrades on spinning disks.** The embedded RocksDB database performs poorly on HDDs under load. Use an SSD for the data directory. Performance issues on spinning disks can manifest as slow room loading and federation timeouts.
- **No support for MSC4186 (Simplified Sliding Sync).** Element X clients rely on this extension for their sync protocol. conduwuit does not implement it, so Element X users will not have a fully working experience.

## Links

- GitHub: <https://github.com/girlbossceo/conduwuit>
- Docs: <https://conduwuit.puppyirl.gay/>
- Successor project (Tuwunel): <https://tuwunel.chat>
- Docker Hub image: <https://hub.docker.com/r/girlbossceo/conduwuit>
- Matrix Spec (federation): <https://spec.matrix.org/latest/server-server-api/>
