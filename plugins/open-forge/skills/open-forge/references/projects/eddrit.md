# eddrit

> Lightweight alternative frontend for Reddit — compact old.reddit-inspired design, no ads, mobile-friendly, no OAuth2 registration required for self-hosting (mimics the official Android app to bypass rate-limiting), basic RSS support for subreddits and posts. URLs mirror Reddit's structure so you can replace `reddit.com` with your instance domain.

**Official URL:** https://github.com/corenting/eddrit  
**Demo instance:** https://eddrit.com

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended; requires Valkey sidecar |
| Any Linux VPS/VM | Python ASGI (uvicorn) | Requires Python ≥ 3.14 + Poetry |
| ARM64 / ARMv7 | Docker | Multi-arch image available |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `VALKEY_URL` | URL of your Valkey (Redis-compatible) instance | `redis://eddrit-valkey:6379` |
| `FORWARDED_ALLOW_IPS` | Proxy IP(s) trusted for `X-Forwarded-*` headers | `*` (unsafe for public) or proxy IP |

### Phase: Optional
| Input | Description | Default |
|-------|-------------|---------|
| `DEBUG` | Enable Starlette debug mode | `false` |
| `LOG_LEVEL` | Minimum log level | `WARNING` |
| `PROXY` | HTTP proxy for outbound Reddit requests | none |

---

## Software-Layer Concerns

### Architecture
- **App:** Python ASGI application (Starlette/uvicorn)
- **Cache:** [Valkey](https://github.com/valkey-io/valkey) (Redis-compatible; stores OAuth tokens used to bypass Reddit rate-limiting)
- Valkey is a **required sidecar** — the app will not start without it

### Ports
| Container | Purpose |
|-----------|---------|
| `8080` | Web UI |

### Reverse Proxy Notes
- When behind Nginx/Caddy/Traefik, set `FORWARDED_ALLOW_IPS` to your proxy's IP (or `*` only if the container is not directly internet-exposed)
- Proxy must pass `X-Forwarded-For`, `X-Forwarded-Proto` headers correctly
- Setting `*` without network isolation makes the instance vulnerable to IP spoofing

### Reddit Rate-Limiting
- By default, eddrit mimics the Reddit Android app to avoid OAuth registration
- For public instances or hosted environments where Reddit blocks the IP range, set `PROXY` to a Cloudflare WARP or similar proxy

---

## Docker Compose Example

```yaml
services:
  eddrit:
    image: ghcr.io/corenting/eddrit:latest
    container_name: eddrit
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      VALKEY_URL: "redis://eddrit-valkey:6379"
      FORWARDED_ALLOW_IPS: "*"   # safe only if not exposed directly
      # PROXY: "socks5://127.0.0.1:1080"
    depends_on:
      - valkey

  valkey:
    image: valkey/valkey:alpine
    container_name: eddrit-valkey
    restart: unless-stopped
```

---

## Upgrade Procedure

1. Pull latest images: `docker compose pull`
2. Restart with new images: `docker compose up -d`
3. Check logs: `docker compose logs -f eddrit`

---

## Gotchas

- **Valkey is required** — eddrit stores Reddit OAuth tokens in Valkey; the app will not function without it
- **Reddit may block your server's IP** — hosting providers' IP ranges are often blocked by Reddit; use the `PROXY` option with Cloudflare WARP or a residential proxy to resolve this
- **`FORWARDED_ALLOW_IPS: "*"` is unsafe for public instances** — only use if the container is behind a private network or you've verified only your proxy can reach it
- **Python ≥ 3.14 required** for non-Docker deployments — this is a very recent Python version; Docker is strongly recommended
- **Not logged-in Reddit features** — eddrit is a read-only frontend; no posting, voting, or account features
- **Reddit API changes** may break functionality — check the repo for updates if the site stops loading

---

## Links
- GitHub: https://github.com/corenting/eddrit
- Deployment docs: https://github.com/corenting/eddrit/blob/master/doc/deployment/README.md
- Docker Hub: https://hub.docker.com/r/corentingarcia/eddrit
- GHCR: https://github.com/corenting/eddrit/pkgs/container/eddrit
