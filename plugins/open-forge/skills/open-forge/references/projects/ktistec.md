---
name: ktistec-project
description: Ktistec recipe for open-forge. Single/multi-user ActivityPub (fediverse) server. No external database — uses SQLite. Crystal-based. Minimal dependencies. MCP support. Mastodon-compatible API subset. Must be fronted by TLS reverse proxy. Upstream: https://github.com/toddsundsted/ktistec
---

# Ktistec

A single- or small-group ActivityPub server for the fediverse. Designed for small numbers of trusted users where everyone is an administrator. Uses SQLite — no PostgreSQL, Redis, or other external services needed. Rich text and Markdown editors, polls, quote posts, content filtering, RSS feeds, Thread Analysis, X-Ray mode for seeing into federated threads, scripting via Tasks, and MCP (Model Context Protocol) support. Written in Crystal.

Upstream: <https://github.com/toddsundsted/ktistec> | Live instance: <https://epiktistes.com>

Single container. Must be fronted by a TLS-enabled reverse proxy.

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host (AMD64) | Single container; fronted by nginx or Caddy for TLS |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Your domain?" | e.g. `social.example.com` — baked into ActivityPub actor URLs; **cannot change after init** |
| preflight | "Host port?" | Default: `3000` — internal port; only reverse proxy should reach it |

## Software-layer concerns

### Image

```
ghcr.io/toddsundsted/ktistec:latest
```

GitHub Container Registry — check [releases](https://github.com/toddsundsted/ktistec/releases) for pinned versions.

### Compose

```yaml
services:
  ktistec:
    image: ghcr.io/toddsundsted/ktistec:latest
    container_name: ktistec
    restart: unless-stopped
    ports:
      - "127.0.0.1:3000:3000"   # bind to loopback — only nginx/Caddy should reach this
    volumes:
      - ktistec-data:/home/ktistec
    environment:
      HOST: social.example.com   # your domain — no https://, no trailing slash
      PORT: "3000"

volumes:
  ktistec-data:
```

> Source: upstream README — <https://github.com/toddsundsted/ktistec>

### Key environment variables

| Variable | Purpose |
|---|---|
| `HOST` | Your domain name (no scheme, no trailing slash). Set before first run — used in all ActivityPub actor URLs. |
| `PORT` | Port ktistec listens on internally. Default `3000`. |

### Data directory

All data (SQLite database, uploaded media, config) lives in `/home/ktistec` inside the container, mounted as the `ktistec-data` named volume.

### Nginx reverse proxy (TLS)

```nginx
server {
    listen 443 ssl;
    server_name social.example.com;

    ssl_certificate     /etc/letsencrypt/live/social.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/social.example.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Caddy reverse proxy (auto TLS)

```
social.example.com {
    reverse_proxy localhost:3000
}
```

### First-run setup

On first visit to your domain, Ktistec presents an onboarding wizard to create your admin account and configure the site. Complete this before sharing the URL.

### MCP support

Ktistec exposes an MCP (Model Context Protocol) endpoint for agentic integrations. OAuth is required for MCP access. See upstream docs for details.

### API

Ktistec supports a subset of the Mastodon API, enabling use with Mastodon-compatible mobile and desktop clients. See: <https://github.com/toddsundsted/ktistec#api>

### Building from source

```bash
git clone https://github.com/toddsundsted/ktistec.git
cd ktistec
docker build -t ktistec .
```

Requires Crystal compatibility — see upstream README for version notes.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Data persists in `ktistec-data`. Check [releases](https://github.com/toddsundsted/ktistec/releases) for migration notes.

## Gotchas

- **`HOST` cannot be changed after init** — all ActivityPub actor URLs include your domain. Changing it after the first run breaks federation. Set it to your permanent domain before starting.
- **TLS is mandatory** — ActivityPub federation requires HTTPS. Ktistec speaks plain HTTP only; you must use a TLS-terminating reverse proxy.
- **Bind port to loopback** — use `127.0.0.1:3000:3000` so the port isn't publicly accessible without going through nginx/Caddy.
- **Everyone is admin** — Ktistec is designed for small trusted groups; all users have admin privileges. Don't open registration publicly unless you intend this.
- **No external DB** — SQLite lives inside the `ktistec-data` volume. Back this up regularly.
- **Crystal-compiled binary** — no JVM, no Node. Fast startup, low memory. The prebuilt image is AMD64; ARM users need to build from source.

## Links

- Upstream README: <https://github.com/toddsundsted/ktistec>
- Releases: <https://github.com/toddsundsted/ktistec/releases>
- Live instance: <https://epiktistes.com>
