---
name: algernon-project
description: Algernon recipe for open-forge. Covers Docker (single container) and binary install as documented at https://github.com/xyproto/algernon.
---

# Algernon

Small, self-contained Go web server with built-in support for Lua, Teal, Markdown, HTTP/2, QUIC, Redis/Valkey, PostgreSQL, SQLite, and more. Single binary — no dependencies required. Upstream: <https://github.com/xyproto/algernon>. Official site: <https://algernon.roboticoverlords.org/>.

## Compatible install methods

| Method | Upstream reference | When to use |
|---|---|---|
| Docker (single container) | <https://github.com/xyproto/algernon#docker> | Quickest path; mounts content dir as volume |
| Pre-built binary | <https://github.com/xyproto/algernon/releases/latest> | Production on bare metal or VM |
| `go install` | <https://github.com/xyproto/algernon#quick-installation> | Dev machines with Go ≥ 1.25 installed |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Where will Algernon serve content from?" | Directory path | Mounted into container at `/srv/algernon` or passed as positional arg |
| preflight | "Which port should Algernon listen on?" | Number (default `4000`) | Exposed via `-p <port>:4000` |
| tls (optional) | "Path to TLS certificate?" | File path | Algernon auto-enables HTTP/2 over TLS when cert+key are provided |
| tls (optional) | "Path to TLS private key?" | File path | Pair with cert |
| db (optional) | "Redis/Valkey URL for session/permission backend?" | `redis://<host>:<port>` | Omit for built-in BoltDB |

## Docker quick-start (from upstream README)

```bash
mkdir ./site
echo '# Hello' > ./site/index.md
docker run -it -p 4000:4000 -v $(pwd)/site:/srv/algernon xyproto/algernon
```

Visit `http://localhost:4000`.

## Software-layer concerns

| Concern | Detail |
|---|---|
| Content root | `/srv/algernon` inside container; bind-mount your site directory there |
| Database (built-in) | BoltDB file stored in the content directory (`*.db`). For multi-instance deployments, switch to Redis/Valkey. |
| Users & permissions | `/data` and `/repos` paths require login; `/admin` requires admin role. Configurable via Lua scripts. |
| TLS | Pass `--cert <path>` and `--key <path>` flags to enable HTTPS + automatic HTTP/2. Without cert, plain HTTP is used. |
| QUIC/HTTP3 | Enable with `--quic` flag (requires TLS). |
| Port | Default `4000`. Change with `-p <port>` CLI flag. |
| Special index files | `index.lua`, `index.md`, `index.html`, `index.pongo2`, `index.amber` — served in priority order per directory. |

## Upgrade procedure

Per <https://github.com/xyproto/algernon/releases>:

1. Pull the new Docker image: `docker pull xyproto/algernon`
2. Stop and restart the container with the same volume mount.
3. For binary installs: download the new release binary from the releases page, replace the old one, restart the process.

No database migrations required for BoltDB. If using Redis/Valkey, no schema changes between versions.

## Gotchas

- **x86_64 only for Docker**: the Docker Hub image targets `linux/amd64`. ARM (e.g. Raspberry Pi) users should build from source.
- **BoltDB is single-process**: only one Algernon instance can hold the BoltDB lock at a time. Use Redis/Valkey if running multiple replicas.
- **QUIC requires TLS**: `--quic` has no effect without a cert+key pair.
- **Lua handler scoping**: `index.lua` in a directory is the handler for that directory only — not recursive.

## Links

- Upstream README & docs: <https://github.com/xyproto/algernon>
- Tutorial: <https://github.com/xyproto/algernon/blob/main/TUTORIAL.md>
- Docker Hub: <https://hub.docker.com/r/xyproto/algernon/tags>
- Releases: <https://github.com/xyproto/algernon/releases/latest>
