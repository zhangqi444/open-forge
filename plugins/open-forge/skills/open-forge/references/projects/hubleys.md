# Hubleys

**Multi-user personal dashboard organized via central YAML config** — provides separate dashboards per user based on group permissions, with link tiles in folders, search engine integration, calendar events, weather, dynamic backgrounds, clock/stopwatch/timer, and admin messaging.

**Official site:** https://github.com/knrdl/hubleys-dashboard
**Source:** https://github.com/knrdl/hubleys-dashboard
**License:** MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | Docker Compose | Recommended; requires reverse proxy with forward auth |
| Local LAN | Docker | Single-user mode available via `SINGLE_USER_MODE=1` |

---

## Inputs to Collect

### Phase 1 — Planning
- Single-user vs multi-user mode
- Auth provider for forward auth (Authelia, Traefik ForwardAuth, nginx auth_request, etc.)
- OpenWeatherMap API key (optional, for weather widget)
- Unsplash API key (optional, for dynamic photo backgrounds)

### Phase 2 — Deploy
- `ADMINS` list — comma-separated `user:<username>` or `group:<groupname>` entries
- `ORIGIN` — full public URL of the instance
- Reverse proxy configuration to pass `Remote-User` header

---

## Software-Layer Concerns

- **Config file:** `/data/config.yml` — auto-generated on first start; edit to define links, folders, search engines, messages
- **Data dirs:**
  - `/data/` — all persistent data (mount as volume)
  - `/data/logos/` — custom icon images referenced in config
  - `/data/wallpaper/` — local photos for "wallpaper collection" background
  - `/data/users/backgrounds/` — user-uploaded background images
  - `/data/users/config/` — per-user settings
  - `/data/users/default-config.json` — template for new user settings
- **Forward auth:** Hubleys uses `Remote-User` HTTP header for user identity; requires a reverse proxy that sets this header after authentication
- **Permissions:** Run `chown -R 1000:1000 ./data` on the host before first start
- **Config reload:** Settings → Admin → Reload application (no restart needed after config edits)

---

## Deployment

```bash
# Quick demo (single-user, no auth)
docker run -it --rm -e SINGLE_USER_MODE=1 -e ORIGIN=http://localhost:3000 \
  -p 127.0.0.1:3000:3000 ghcr.io/knrdl/hubleys-dashboard:edge
```

```yaml
# docker-compose.yml
version: '2.4'
services:
  hubleys:
    image: ghcr.io/knrdl/hubleys-dashboard
    hostname: hubleys
    restart: unless-stopped
    environment:
      ORIGIN: https://dashboard.example.com
      OPENWEATHERMAP_API_KEY: your-key-here   # optional
      UNSPLASH_API_KEY: your-access-key-here  # optional
      ADMINS: user:admin1, user:admin2
    volumes:
      - ./data:/data
    networks:
      - proxy
    mem_limit: 100m
```

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

---

## Gotchas

- **Forward auth is required for multi-user** — the reverse proxy must set the `Remote-User` header; without it, user isolation doesn't work
- **File permissions** — `/data` must be owned by UID 1000; run `chown -R 1000:1000 ./data` before first start
- **Weather won't work in demo mode** — `SINGLE_USER_MODE=1` + `ORIGIN` is enough for a quick local trial but external API keys won't load
- **Unsplash backgrounds** require a free Unsplash developer account (Access Key)
- **Custom config paths** — can be overridden via env vars defined in the Dockerfile; useful if tracking `config.yml` in a separate git repo
- **Config changes** take effect via admin reload; Docker restart is not required

---

## Links

- Upstream README: https://github.com/knrdl/hubleys-dashboard#readme
- Default config example: https://github.com/knrdl/hubleys-dashboard/blob/main/src/lib/server/sysconfig/default.yml
