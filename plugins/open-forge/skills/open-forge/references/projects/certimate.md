---
name: certimate
description: Certimate is an open-source, self-hosted SSL certificate ACME automation tool — automates the full lifecycle of issuance, deployment, renewal, and monitoring via a visual workflow. Supports 60+ DNS providers and 120+ deployment targets. Go binary or Docker. Upstream: https://github.com/certimate-go/certimate
---

# Certimate

Certimate is a **self-hosted SSL certificate automation platform** that manages the entire certificate lifecycle: request, deploy, renew, and monitor — all through a visual workflow UI. It is the self-hosted alternative to certificate bots like Certbot and acme.sh, but with a web dashboard, multi-domain/wildcard support, and automated deployment to 120+ targets including Kubernetes, CDNs, load balancers, and WAFs.

Upstream: <https://github.com/certimate-go/certimate>  
Docs: <https://docs.certimate.me/en-US/>  
Docker Hub: `certimate/certimate`  
License: MIT

## What it does

- **ACME automation** — request, renew, and revoke certificates from Let's Encrypt, ZeroSSL, Google Trust Services, Actalis, SSL.com, and more
- **DNS-01 and HTTP-01 challenge support** — works with 60+ DNS registrars (Cloudflare, AWS Route53, GoDaddy, Alibaba Cloud, Tencent Cloud, and more)
- **Single / multi-domain / wildcard / IP certificates** — RSA or ECC key types
- **120+ deployment targets** — Kubernetes secrets, CDN platforms, WAFs, load balancers, SSH/SFTP file copy, local filesystem, and more
- **Visual workflow editor** — build automation pipelines without code; chain issuance → deployment → notification steps
- **Notifications** — email, Discord, Slack, Telegram, DingTalk, Feishu, WeCom, and more
- **Multiple certificate formats** — PEM, PFX/PKCS12, JKS
- **Zero dependencies** — uses PocketBase embedded database; no separate database container needed
- **Ultra-lightweight** — ~16 MB memory footprint

## Architecture

- **Single binary or single container** — Go binary with PocketBase embedded (SQLite-based, no external DB)
- **Port**: `8090`
- **Storage**: `/app/pb_data` volume (PocketBase database + certificate files)
- **Resource footprint**: extremely low (~16 MB RAM)

## Compatible install methods

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux/macOS/Windows host | Binary | Download precompiled release from GitHub. Run `./certimate serve`. |
| Any Linux host | Docker (single container) | Primary containerised method. |
| Any Linux host | Docker Compose | Recommended for environment variable management and auto-restart. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port to expose Certimate on?" | Default `8090`. |
| preflight | "Data path on host for certificate storage?" | e.g. `/opt/certimate/data`. Mounted at `/app/pb_data`. |
| bootstrap | "Admin email and password?" | Default on first boot: `admin@certimate.fun` / `1234567890`. Change immediately. |

## Docker run (quick start)

```bash
docker run -d \
  --name certimate \
  --restart unless-stopped \
  -p 8090:8090 \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  -v $(pwd)/data:/app/pb_data \
  certimate/certimate:latest
```

Access at `http://<host>:8090`.  
**Default credentials**: `admin@certimate.fun` / `1234567890` — **change immediately**.

## Docker Compose

```yaml
# compose.yaml
services:
  certimate:
    image: certimate/certimate:latest
    container_name: certimate
    restart: unless-stopped
    ports:
      - "${CERTIMATE_PORT:-8090}:8090"
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /etc/timezone:/etc/timezone:ro
      - ${CERTIMATE_DATA_PATH:-./data}:/app/pb_data
```

```bash
docker compose up -d
```

## Binary install

```bash
# Download latest release
curl -sL https://github.com/certimate-go/certimate/releases/latest/download/certimate_linux_amd64.tar.gz \
  | tar xz

# Run
./certimate serve
```

Access at `http://localhost:8090`.

## First-run setup

1. Open `http://<host>:8090` in a browser.
2. Log in with default credentials (`admin@certimate.fun` / `1234567890`).
3. **Change the admin password immediately** (top-right menu → Account settings).
4. Go to **Settings → Certificate Providers** and add your ACME CA credentials.
5. Go to **Settings → DNS Providers** and add your DNS registrar API keys.
6. Go to **Settings → Deployment Targets** and configure where certificates should be deployed.
7. Create a **Workflow**: select domain(s) → choose provider → set deployment target → set renewal schedule.

## Reverse proxy

Certimate serves plain HTTP. For HTTPS access (recommended if not on a private network), front with a reverse proxy.

**Caddy example:**

```caddyfile
certimate.example.com {
    reverse_proxy localhost:8090
}
```

## Upgrade

```bash
docker compose pull && docker compose up -d
```

The `/app/pb_data` volume persists all configuration and certificates across upgrades.

## Backup

All data (PocketBase database + stored certificates) lives in the mounted `pb_data` directory:

```bash
tar czf certimate-backup-$(date +%Y%m%d).tar.gz ./data
```

## Gotchas

- **Change default credentials on first login** — the default `admin@certimate.fun` / `1234567890` credentials are widely known; change them before exposing the dashboard to any network.
- **Timezone volumes required for correct renewal scheduling** — mount `/etc/localtime` and `/etc/timezone` from the host so cron-style renewal timers fire at the correct local time.
- **DNS propagation before HTTP-01 challenge** — when using HTTP-01, the domain must resolve to the Certimate host and port 80 must be reachable from the CA's validation servers.
- **DNS-01 is recommended for wildcard certs** — wildcard certificates (`*.example.com`) require DNS-01 challenge; HTTP-01 cannot issue wildcards.
- **`pb_data` is write-sensitive** — avoid bind-mounting over an existing non-empty directory on first run; start with an empty directory to let PocketBase initialise cleanly.
- **No Docker Compose in the official repo** — the upstream README only shows `docker run`; the Compose snippet above is the recommended equivalent.
