---
name: replex
description: Recipe for Replex — Plex proxy that remixes home hubs: merges movie/show rows, removes watched items, forces quality, enables hero style. Requires reverse proxy + SSL for non-browser clients.
---

# Replex

Remix your Plex hubs — a proxy that transforms communication between Plex Media Server and Plex clients. Upstream: https://github.com/lostb1t/replex

Sits in front of Plex to enable features Plex doesn't expose: merge movie and show recommendation rows into single interleaved hubs, remove watched items, force maximum quality / direct play, auto-select version by client resolution, and apply collection restrictions per user. Works with every Plex client (not just Plex Web).

> **Seeking maintainer** — the author has moved away from Plex; the project needs a new maintainer.

## Prerequisites

- Plex Media Server
- A reverse proxy with SSL (required for most Plex clients — see gotchas)
- Plex server admin token

## Compatible combos

| Runtime | Notes |
|---|---|
| Docker Compose (with Plex) | Primary method — Replex and Plex in same compose stack |
| Docker Compose (standalone) | Replex only, pointing at existing Plex instance |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Plex URL | e.g. http://plex:32400 or http://192.168.1.x:32400 |
| preflight | Plex server admin token | Settings → Troubleshooting → Your account in Plex; or see https://support.plex.tv/articles/204059436 |
| network | Public domain + SSL | Required for non-browser Plex clients to use the proxy |

## Software-layer concerns

**How it works:** Replex is an HTTP proxy — all Plex client traffic goes through Replex, which modifies API responses before forwarding them to clients. Plex server still does all media serving.

**Port:** Replex on port 80 inside the container; map to host port (e.g. 3001:80).

**Plex custom server URL:** After deploying, add your Replex URL to Plex → Settings → Network → "Custom server access URLs". Disable Plex's built-in remote access (it bypasses the proxy).

**SSL is essential:** Most Plex clients (especially mobile apps) refuse insecure connections. Set up a reverse proxy (Caddy or NGINX Proxy Manager recommended) with a domain and SSL cert, then use that HTTPS URL as the custom server access URL.

**Do NOT run Plex in host network mode** — it causes Plex to connect using the local IP, bypassing Replex.

**Caching:** REPLEX_CACHE_TTL defaults to 1800s. Keep caching enabled except during troubleshooting.

## Docker Compose (Replex + Plex)

```yaml
services:
  plex:
    image: lscr.io/linuxserver/plex:latest
    container_name: plex
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - VERSION=docker
      - PLEX_CLAIM=        # from https://plex.tv/claim
    ports:
      - "32400:32400"
    volumes:
      - /path/to/library:/config
      - /path/to/tv:/tv
      - /path/to/movies:/movies
    restart: unless-stopped

  replex:
    image: ghcr.io/lostb1t/replex:latest
    container_name: replex
    environment:
      REPLEX_HOST: http://plex:32400
      REPLEX_TOKEN: your-plex-admin-token
    ports:
      - "3001:80"
    restart: unless-stopped
    depends_on:
      - plex
```

## Key settings reference

| Env var | Default | Description |
|---|---|---|
| REPLEX_HOST | (required) | Plex URL (e.g. http://plex:32400) |
| REPLEX_TOKEN | (required) | Plex server admin token |
| REPLEX_INTERLEAVE | true | Merge same-named collection hubs from different libraries |
| REPLEX_EXCLUDE_WATCHED | true | Hide watched items from hubs |
| REPLEX_HUB_RESTRICTIONS | true | Apply collection restrictions to hubs per user |
| REPLEX_DISABLE_CONTINUE_WATCHING | false | Remove the Continue Watching row |
| REPLEX_DISABLE_USER_STATE | true | Remove watched badges from hub items |
| REPLEX_FORCE_MAXIMUM_QUALITY | false | Force original quality bitrate on all clients |
| REPLEX_AUTO_SELECT_VERSION | false | Auto-pick media version closest to client resolution |
| REPLEX_HERO_ROWS | (empty) | Comma-separated hub identifiers to display in hero style |
| REPLEX_CACHE_TTL | 1800 | Cache TTL in seconds (0 = disabled, not recommended) |

Full settings list: https://github.com/lostb1t/replex#settings

## Upgrade procedure

```bash
docker compose pull replex
docker compose up -d replex
```

Replex is stateless — no data to migrate.

## Gotchas

- **SSL is required for production** — browser testing works over HTTP, but mobile/TV clients will refuse insecure connections. Set up Caddy or NGINX Proxy Manager before rolling out to all clients.
- **Disable Plex remote access** — built-in Plex remote access bypasses the proxy. Disable it under Settings → Remote Access, and clear client caches to force reconnection via the custom URL.
- **Do not use Plex host networking** — causes Plex to advertise the host IP directly to clients, bypassing Replex.
- **Hero style limitations** — hero hubs on Android load a maximum of 100 items; Continue Watching doesn't support hero style natively (workaround: smart collection + REPLEX_DISABLE_CONTINUE_WATCHING).
- **Seeking maintainer** — the project may have reduced activity; check issue tracker before adopting for a new setup.

## Links

- Upstream repository + full settings docs: https://github.com/lostb1t/replex
- GitHub Container Registry: https://ghcr.io/lostb1t/replex
- Finding your Plex token: https://support.plex.tv/articles/204059436
- Caddy reverse proxy: https://caddyserver.com
- NGINX Proxy Manager: https://nginxproxymanager.com
