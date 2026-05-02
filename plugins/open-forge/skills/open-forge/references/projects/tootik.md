# tootik

> Lightweight, text-based federated social network (ActivityPub / Fediverse) with a Gemini-protocol UI — no browser required, no tracking, single static binary backed by SQLite.

**URL:** https://github.com/dimkr/tootik
**Source:** https://github.com/dimkr/tootik
**License:** Apache License 2.0

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux (x86_64, arm64, arm, 386) | Binary (static executable) | Preferred method; prebuilt releases available |
| Any   | Build from source | Requires Go; three SQLite driver options (mattn, modernc, ncruces) |

> tootik does **not** publish a Docker image. It is a single static binary with no external dependencies.

## Inputs to Collect

### Provision phase
- A domain name pointed at the server (IPv4 + IPv6 recommended)
- HTTPS certificate (Let's Encrypt via Certbot, or bring your own)
- Gemini self-signed TLS certificate (generated with `openssl`)

### Deploy phase
- `-domain` — your public domain name
- `-addr` — HTTPS listen address (e.g. `:443`)
- `-gemaddr` — Gemini listen address (e.g. `:1965`)
- `-cert` / `-key` — paths to HTTPS certificate and key
- `-gemcert` / `-gemkey` — paths to Gemini certificate and key
- `-db` — path to SQLite database file
- Optional: `-blocklist` — path to Garden Fence blocklist CSV

## Software-layer Concerns

### Installation (static binary)
```bash
# Download latest release for your architecture
curl -L https://github.com/dimkr/tootik/releases/latest/download/tootik-$(
  case $(uname -m) in
    x86_64)  echo amd64  ;;
    aarch64) echo arm64  ;;
    i686)    echo 386    ;;
    armv7l)  echo arm    ;;
  esac
) -o /usr/local/bin/tootik
chmod 755 /usr/local/bin/tootik

# Run
tootik \
  -domain example.com \
  -addr :443 \
  -gemaddr :1965 \
  -blocklist /tootik-cfg/gardenfence-mastodon.csv \
  -cert /tootik-cfg/https-cert.pem \
  -key /tootik-cfg/https-key.pem \
  -gemcert /tootik-cfg/gemini-cert.pem \
  -gemkey /tootik-cfg/gemini-key.pem \
  -db /tootik-data/db.sqlite3
```

### Build from source
```bash
go generate ./migrations
CGO_ENABLED=0 go build ./cmd/tootik   # pure-Go SQLite (no CGO)
# or with CGO:
CGO_ENABLED=1 go build -tags fts5 ./cmd/tootik
```

### Config / flags
- `-domain`: public domain name (required)
- `-addr`: HTTPS listen address for ActivityPub federation
- `-gemaddr`: Gemini listen address for the user-facing UI
- `-cert` / `-key`: HTTPS TLS cert/key (Let's Encrypt recommended; tootik watches these files and restarts the HTTPS listener on change)
- `-gemcert` / `-gemkey`: Gemini TLS cert/key (self-signed, 10-year validity is fine)
- `-db`: SQLite database path (single file = all instance data)
- `-blocklist`: Garden Fence Mastodon-format CSV for domain blocking

### Data dirs
- `/tootik-data/db.sqlite3` (or your chosen path) — entire instance state (users, posts, follows, federation queues)
- `/tootik-cfg/` — TLS certificates and optional blocklist

## Upgrade Procedure
```bash
# Stop tootik (systemd or process manager)
systemctl stop tootik

# Download new binary
curl -L https://github.com/dimkr/tootik/releases/latest/download/tootik-<arch> \
  -o /usr/local/bin/tootik
chmod 755 /usr/local/bin/tootik

# tootik runs DB migrations automatically on startup
systemctl start tootik
```
Back up the SQLite database file before upgrading.

## Gotchas
- **No Docker image** — tootik is distributed as a static binary only; Docker Compose does not apply.
- **Gemini client required for users** — the UI is served over the Gemini protocol; users need a Gemini browser (e.g. Lagrange, Kristall). There is no web browser interface.
- **Ports 443 and 1965** — tootik needs to bind to privileged ports or be run behind a proxy; the setup guide creates an unprivileged `tootik` user and uses `setcap` or a reverse proxy.
- **Certificate renewal hook** — Certbot must be configured with a post-renewal hook to copy updated certs to the tootik config directory; tootik watches the files and reloads automatically.
- **ActivityPub subset only** — tootik intentionally implements only the subset of ActivityPub needed for its feature set; some advanced Mastodon features may not be supported.
- **FTS5 build tag** — for full-text search support, build with `-tags fts5`; prebuilt releases include FTS5.
- A $5/mo VPS is sufficient for a small personal or community instance.

## Links
- [README](https://github.com/dimkr/tootik/blob/main/README.md)
- [Setup Guide (SETUP.md)](https://github.com/dimkr/tootik/blob/main/SETUP.md)
- [Federation compatibility (FEDERATION.md)](https://github.com/dimkr/tootik/blob/main/FEDERATION.md)
- [Releases](https://github.com/dimkr/tootik/releases)
