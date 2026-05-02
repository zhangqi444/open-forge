---
name: lufin
description: Recipe for Lufin — modern self-hosted file-sharing service with client-side E2E encryption, S3 support, rich previews, 26 languages, and automatic HTTPS via Caddy. Bun/Elysia backend, React frontend. Multiple DB options (PostgreSQL/MongoDB/SQLite).
---

# Lufin

Modern self-hosted file-sharing service with client-side end-to-end encryption. Upstream: https://github.com/VityaSchel/lufin (primary: https://git.hloth.dev/hloth/lufin)

Bun + Elysia backend, React + Vite frontend. Client-side E2E encryption (AES-GCM), EXIF metadata stripping, rich previews (images, audio, video, ZIP, XLSX, text, PDF), password protection, delete-at-first-download, S3 storage support (local or Cloudflare R2), configurable retention policies, 26 languages. Docker Compose with optional Caddy automatic HTTPS. MIT licensed.

Demo: https://lufin.hloth.dev

## Prerequisites

- A domain name with DNS configured
- A publicly reachable server (or tunnel — Cloudflare, Tailscale, ngrok)

## Compatible combos

| Runtime | Notes |
|---|---|
| Docker Compose + Caddy | Recommended — automatic HTTPS out of the box |
| Docker Compose (no Caddy) | Use your own reverse proxy for TLS |
| Manual install | Bun + Node.js — see upstream docs |

## Database options

| DB | Notes |
|---|---|
| PostgreSQL | Recommended for most cases |
| SQLite | Good for low-end / single-user |
| MongoDB | Supported if preferred |

## Storage options

| Storage | Notes |
|---|---|
| Local uploads dir | Fastest, recommended default |
| Local Minio S3 | High-load caching benefit |
| Remote S3 / Cloudflare R2 | For small-disk machines |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Domain name | For TLS certificate (required) |
| preflight | Enable Caddy auto-HTTPS? | Yes = Caddy manages certs; No = bring your own reverse proxy |
| preflight | Database choice | PostgreSQL / SQLite / MongoDB |
| preflight | Storage choice | Local uploads / local Minio S3 / remote S3 |
| config (opt) | S3 credentials | If using remote S3/R2: endpoint, bucket, key, secret |
| config (opt) | data-retention.config.json | Per-size retention rules (e.g. files >100MB deleted after 7 days) |

## Software-layer concerns

**Setup via interactive script:** Run `./configure.sh` to generate the `.env` file — answers questions about domain, HTTPS, DB, and storage choices. Then start with `./run.sh start`.

**Automatic HTTPS:** Caddy handles TLS certificate issuance automatically when enabled. If behind Cloudflare or using your own proxy, answer "no" to Caddy and configure TLS externally.

**Client-side encryption:** File content is encrypted in the browser before upload. The server never sees plaintext. This also means hotlinks (direct embeds) only work when encryption is disabled by the uploader.

**Data retention:** Configurable via `data-retention.config.json` — set retention periods per file size range.

**Static frontend:** The React frontend is built into a static bundle — no SSR runtime needed. Served by Caddy or your own static file server.

**`APP_REQUIRES_JS`:** The app requires JavaScript for client-side encryption.

## Setup

```bash
git clone https://github.com/VityaSchel/lufin.git
cd lufin

./configure.sh      # interactive setup: domain, HTTPS, DB, storage
./run.sh start      # starts all containers
```

## Run.sh commands

| Command | Description |
|---|---|
| `./run.sh start` | Start all containers |
| `./run.sh stop` | Stop all containers |
| `./run.sh reload` | Reload (e.g. after config changes) |

## Upgrade procedure

```bash
git pull
./run.sh stop
./run.sh start
```

Check releases for breaking changes. Database volumes are preserved.

## Gotchas

- **Domain required** — Caddy automatic HTTPS requires a publicly reachable domain. Local-only testing needs a workaround (see upstream docs on local HTTPS).
- **JavaScript required** — client-side encryption is JS-only; the app is unusable without it.
- **E2E encryption vs. hotlinks** — encrypted files cannot be hotlinked/embedded directly (the key is in the URL fragment, which browsers don't send to servers). Users can opt out of encryption for embeddable links.
- **configure.sh generates .env** — do not manually create `.env`; use the interactive script to avoid misconfiguration.
- **`./run.sh` not `docker compose`** — the run script handles the correct compose file selection based on your DB/storage choices.

## Links

- GitHub (primary mirror): https://github.com/VityaSchel/lufin
- Primary source: https://git.hloth.dev/hloth/lufin
- Docker install docs: https://github.com/VityaSchel/lufin/blob/main/docs/INSTALL.md
- Demo: https://lufin.hloth.dev
