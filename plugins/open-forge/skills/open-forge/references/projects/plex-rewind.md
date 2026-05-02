---
name: plex-rewind-project
description: Plex Rewind recipe for open-forge. Covers Docker Compose deployment of this Plex statistics dashboard (Spotify Wrapped-style). Based on upstream README and docker-compose.yml at https://github.com/RaunoT/plex-rewind.
---

# Plex Rewind

Plex statistics and habits dashboard inspired by Spotify Wrapped. Shows per-user playback statistics, a live activity view, and a shareable dashboard — all powered by Tautulli data, with optional Overseerr integration. Built with Next.js. Upstream: <https://github.com/RaunoT/plex-rewind>.

> **Prerequisite**: Requires a running [Tautulli](https://tautulli.com) instance for statistics data, and Plex Media Server for authentication.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host / VPS | Docker Compose | Official method; image `ghcr.io/raunot/plex-rewind:latest` |
| Any Linux host / VPS | Docker (single container) | Same image; compose shown in upstream README |
| Local / home network | Docker Desktop | Fine for home use behind reverse proxy |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| deploy | "Public URL where Plex Rewind will be accessible?" | URL | Sets `NEXTAUTH_URL` and `NEXT_PUBLIC_SITE_URL` (e.g. `https://rewind.example.com`) |
| secrets | "NextAuth secret?" | Free-text (32+ chars random) | Generate with `openssl rand -base64 32`; sets `NEXTAUTH_SECRET` |
| tautulli | "Tautulli URL?" | URL | Internal or external URL of your Tautulli instance |
| tautulli | "Tautulli API key?" | Free-text | Found in Tautulli Settings → Web Interface |
| plex | "Plex server URL?" | URL | Internal or external URL of your Plex Media Server |
| overseerr (optional) | "Overseerr URL and API key?" | URLs + key | Optional; enables request breakdowns and request buttons |

## Software-layer concerns

### Environment variables

| Variable | Required | Description |
|---|---|---|
| `NEXTAUTH_SECRET` | ✅ | Encrypts NextAuth JWT sessions; generate with `openssl rand -base64 32` |
| `NEXTAUTH_URL` | ✅ | Full public URL of the app (e.g. `https://rewind.example.com`) |
| `NEXT_PUBLIC_SITE_URL` | ✅ | Same as `NEXTAUTH_URL` — used by Next.js client-side code |

Additional configuration (Tautulli URL, Plex URL, Overseerr, etc.) is set through the web UI on first run and stored in the `./config` volume.

### Docker Compose (from upstream README)

```yaml
services:
  plex-rewind:
    image: ghcr.io/raunot/plex-rewind:latest  # use :develop for latest dev build
    container_name: plex-rewind
    environment:
      - NEXTAUTH_SECRET=   # required — openssl rand -base64 32
      - NEXTAUTH_URL=http://localhost:8383   # change to your domain
      - NEXT_PUBLIC_SITE_URL=http://localhost:8383   # change to your domain
    volumes:
      - ./config:/app/config
    ports:
      - 8383:8383
    restart: unless-stopped
```

### Volumes

| Path | Purpose |
|---|---|
| `./config` | Stores app configuration (Tautulli URL, Plex URL, Overseerr, etc.) |

## Upgrade procedure

Per upstream:

```bash
docker compose pull
docker compose up -d
```

## Gotchas

- If you encounter authentication errors, set `NEXTAUTH_URL` and `NEXT_PUBLIC_SITE_URL` to your **external Docker IP** (e.g. `http://192.168.1.x:8383`) rather than `localhost` — especially relevant for Plex OAuth callbacks.
- Both `NEXTAUTH_URL` and `NEXT_PUBLIC_SITE_URL` must match exactly (protocol + host + port). Mismatches break the Plex login flow.
- Tautulli is **required** — Plex Rewind gets all play history and statistics from it, not directly from Plex.
- The app listens on port `8383` internally; map to any host port you prefer.
- Status endpoint available at `/api/status` for health checks / uptime monitors.
- Put behind a reverse proxy with TLS for any internet-facing deployment.
- PWA install requires HTTPS.

## Links

- Upstream repo: <https://github.com/RaunoT/plex-rewind>
- Container image: `ghcr.io/raunot/plex-rewind`
- Tautulli: <https://tautulli.com>
- Overseerr: <https://overseerr.dev>
