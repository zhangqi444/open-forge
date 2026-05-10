---
name: muximux
description: "Self-hosted homelab dashboard with optional built-in reverse proxy. Single Go binary, YAML config, no database. Strips X-Frame-Options headers so embedded apps work inside iframes. Supports auth (local/OIDC/forward-auth), auto-HTTPS via Let's Encrypt (embedded Caddy), split view, 1600+ icons. GPL-2.0."
---

# Muximux

**A self-hosted homelab dashboard with a built-in reverse proxy that makes stubborn apps work in iframes.** One Go binary, one YAML config file, one port. Strips `X-Frame-Options` headers and rewrites paths/fetch/XHR at runtime so even heavy SPAs embed correctly. Includes built-in auth (local users, OIDC, forward-auth), real-time WebSocket health checks, split-view panels, auto-HTTPS via an embedded Caddy instance, and 1,600+ icons. GPL-2.0.

Unique differentiator: most dashboards just link out to your apps. Muximux makes them actually embed, by proxying through its own backend and patching runtime fetch/XHR in the browser.

- Upstream repo: <https://github.com/mescon/Muximux>
- Docs (wiki): <https://github.com/mescon/Muximux/blob/main/docs/wiki/README.md>
- Image: `ghcr.io/mescon/muximux`
- Latest release: v3.0.32

## Architecture in one minute

- Single **Go** binary; frontend is embedded in the binary — no separate web server, no runtime dependencies, no database
- Listens on port **8080** by default; optional ports **80** / **443** for auto-HTTPS (embedded Caddy)
- All state lives in a single YAML config at `data/config.yaml`; back up or migrate by copying that one file
- Built-in reverse proxy (`proxy: true` per app) strips `X-Frame-Options`, rewrites HTML/CSS/JS paths, patches `fetch()` / `XMLHttpRequest` / WebSocket so SPAs load correctly inside iframes
- Optional TLS domain + Let's Encrypt (Caddy obtains certs automatically); optional gateway Caddyfile to serve other sites alongside Muximux
- Resource: minimal — single binary, no external services required

## Compatible install methods

| Infra | Runtime | Notes |
|---|---|---|
| **Docker** | `ghcr.io/mescon/muximux:latest` | **Primary** — one-liner |
| **Docker Compose** | `docker compose up -d` | Full example with health checks in upstream `docker-compose.yml` |
| **Binary** | `./muximux` | Pre-built release binary for Linux/macOS/Windows |

## Inputs to collect

| Input | Example | Phase | Notes |
|---|---|---|---|
| `WEB_PORT` | `8080` | Network | Host port for the Muximux UI |
| `HTTP_PORT` | `80` | Network | Only needed if using auto-HTTPS / ACME challenges |
| `HTTPS_PORT` | `443` | Network | Only needed if using auto-HTTPS |
| `TZ` | `America/New_York` | Config | Timezone for logs and scheduled checks |
| `PUID` / `PGID` | `1000` / `1000` | Storage | UID/GID that owns the data volume on the host |
| Data directory | `./data` | Storage | Contains `config.yaml`, themes, icons cache |
| `TLS_DOMAIN` | `muximux.example.com` | TLS (optional) | Set to enable auto-HTTPS via embedded Caddy |
| `TLS_EMAIL` | `admin@example.com` | TLS (optional) | Email for Let's Encrypt expiry notices |
| OIDC provider | (varies) | Auth (optional) | `OIDC_ISSUER_URL`, `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET` |

## Install via Docker Compose

```yaml
# docker-compose.yml — based on upstream v3.0.32
services:
  muximux:
    image: ghcr.io/mescon/muximux:latest
    container_name: muximux
    init: true
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    ports:
      - "8080:8080"
      # Uncomment for auto-HTTPS (set TLS_DOMAIN env var or tls.domain in config.yaml):
      # - "80:80"
      # - "443:443"
    volumes:
      - ./data:/app/data
      # Optional: mount a custom gateway Caddyfile for serving other domains
      # - ./sites.Caddyfile:/app/data/sites.Caddyfile:ro
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=UTC
      # Optional direct overrides:
      # - MUXIMUX_LISTEN=:8080
      # TLS (for auto-HTTPS):
      # - TLS_DOMAIN=muximux.example.com
      # - TLS_EMAIL=admin@example.com
      # OIDC auth (referenced via ${VAR} expansion in config.yaml):
      # - OIDC_CLIENT_ID=muximux
      # - OIDC_CLIENT_SECRET=your-secret
      # - OIDC_ISSUER_URL=https://auth.example.com
      # - OIDC_REDIRECT_URL=https://muximux.example.com/auth/callback
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:8080/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
```

```bash
mkdir -p data
docker compose up -d
```

## One-liner Docker run

```bash
docker run -d \
  --name muximux \
  -p 8080:8080 \
  -v $(pwd)/data:/app/data \
  ghcr.io/mescon/muximux:latest
```

## First boot

1. Visit `http://localhost:8080` — a guided **onboarding wizard** launches automatically if no config file exists.
2. The wizard walks through security setup (admin password), optional OIDC/forward-auth, and adding your first apps from a built-in catalog.
3. After onboarding, add more apps via **Settings → Apps**; enable `proxy: true` per-app to use the built-in reverse proxy for iframe-resistant apps.

## Data & config layout

```
data/
├── config.yaml          # all settings: server, apps, auth, TLS, themes
├── themes/              # custom CSS themes
└── icons/               # cached dashboard icons
```

The entire state is `config.yaml`. Back up this file before upgrades.

## Reverse-proxy mode (iframe fixes)

Enable per-app in `config.yaml` or via the UI:

```yaml
apps:
  - name: Sonarr
    url: http://sonarr:8989
    proxy: true     # strips X-Frame-Options, rewrites paths, patches fetch/XHR
    slug: sonarr    # app loads at /proxy/sonarr/
```

Muximux rewrites the app's responses at runtime. Most heavy SPAs (Plex, Jellyfin, *arr-apps) work with `proxy: true`.

## Auto-HTTPS (embedded Caddy)

Set `tls.domain` in `config.yaml` or `TLS_DOMAIN` env var, expose ports 80 and 443:

```yaml
tls:
  domain: muximux.example.com
  email: admin@example.com
```

DNS must resolve to the server before Caddy requests the cert.

## Upgrade

```bash
docker compose pull
docker compose up -d
```

Check the [releases page](https://github.com/mescon/Muximux/releases) for breaking changes across major versions.

## Gotchas

- **Upgrading from v2 (PHP/legacy) to v3**: v3 is a complete rewrite; the v2 config format is not compatible. Re-add apps via the v3 UI.
- **`proxy: true` proxies through `/proxy/{slug}/`**: app URLs in your browser will be under Muximux's domain, not the app's original domain. Some apps have hardcoded origin checks that still block.
- **TLS requires ports 80 + 443 exposed**: ACME HTTP-01 challenges come in on port 80. Open both in your firewall and docker-compose ports.
- **Config is YAML, not JSON**: a stray tab (tabs are invalid YAML) breaks startup. Use the built-in GUI to avoid hand-editing when possible.
- **`cap_drop: ALL` in Compose**: the upstream example drops all Linux capabilities. If you see permission errors on startup, verify `PUID`/`PGID` matches the owner of `./data`.
- **Binary deploys**: download from the [releases page](https://github.com/mescon/Muximux/releases); data directory defaults to `./data` beside the binary; override with `--data /path/to/data`.
