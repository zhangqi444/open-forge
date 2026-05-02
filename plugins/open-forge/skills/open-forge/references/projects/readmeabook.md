# ReadMeABook

Audiobook automation for Plex and Audiobookshelf.  
*Radarr/Sonarr + Overseerr — but for audiobooks, all in one.*

- **Repo:** https://github.com/kikootwo/ReadMeABook
- **License:** AGPL v3
- **Discord:** https://discord.gg/kaw6jKbKts

---

## What it does

Request a book → Prowlarr searches indexers → qBittorrent or SABnzbd downloads → Files organised → Library imports automatically.

Also includes **BookDate**: AI-powered recommendations (OpenAI/Claude/local LLM) with a Tinder-style swipe interface — swipe right to request.

Additional features:
- Chapter merging: multi-file downloads → single M4B with chapter markers
- E-book sidecar: optional EPUB/PDF downloads from Shadow Library
- Request approval workflows for multi-user setups
- OIDC/OAuth support
- Audible-backed search (user-friendly search UX)
- Guided setup wizard with connection testing

---

## Compatible combos

| Infra | Runtime | Stack |
|-------|---------|-------|
| Any Docker host | Docker / Compose | Plex or Audiobookshelf + qBittorrent or SABnzbd + Prowlarr |
| Any Docker host | Docker / Compose | Audiobookshelf standalone (no Plex) |

**Prerequisites:** Docker, Plex or Audiobookshelf, qBittorrent or SABnzbd, Prowlarr.

---

## Inputs to collect

| Phase | Variable / Setting | Notes |
|-------|-------------------|-------|
| Deploy | `PUBLIC_URL` | Required for OIDC/OAuth (e.g. `https://audiobooks.example.com`) |
| Deploy | `PUID` / `PGID` | Optional; match your host user ID |
| Setup wizard | Plex or Audiobookshelf URL + token/credentials | Source media server |
| Setup wizard | qBittorrent or SABnzbd URL + credentials | Download client |
| Setup wizard | Prowlarr URL + API key | Indexer aggregator |
| Setup wizard | Download path | Must match download client's output path |
| Setup wizard | Media library path | Where Plex/ABS expects audiobooks |
| Optional | OpenAI / Anthropic / local LLM API key | For BookDate AI recommendations |

---

## Software-layer concerns

### Volume mapping — critical
ReadMeABook and the download client **must see files at the same path**.  
Use identical mount points in both containers, or a shared named volume.  
See: https://github.com/kikootwo/readmeabook/blob/main/documentation/deployment/volume-mapping.md

### Compose example
```yaml
services:
  readmeabook:
    image: ghcr.io/kikootwo/readmeabook:latest
    container_name: readmeabook
    restart: unless-stopped
    ports:
      - "3030:3030"
    volumes:
      - ./config:/app/config
      - ./cache:/app/cache
      - /data/downloads:/downloads      # must match download client path
      - /data/audiobooks:/media         # your audiobook library root
      - ./pgdata:/var/lib/postgresql/data
      - ./redis:/var/lib/redis
    environment:
      PUID: 1000
      PGID: 1000
      PUBLIC_URL: "https://audiobooks.example.com"
```

### Bundled services
The container includes PostgreSQL and Redis — no separate DB containers needed.

### Setup wizard
Open http://localhost:3030 after first start. The wizard guides through all connection config.

---

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Config and database persist in the mounted volumes (`./config`, `./pgdata`, `./redis`).

---

## Gotchas

- `PUBLIC_URL` is **required** for OAuth/OIDC to work correctly; without it, external auth will fail.
- Volume path mismatch between ReadMeABook and the download client is the #1 cause of "downloads not detected" issues.
- The image bundles PostgreSQL and Redis — don't add separate DB containers unless you want to override.
- E-book sidecar downloads from Shadow Library may have legal implications depending on jurisdiction.
- BookDate AI features require an API key; they're optional and can be skipped.

---

## Further reading

- README: https://github.com/kikootwo/ReadMeABook
- Volume mapping guide: https://github.com/kikootwo/readmeabook/blob/main/documentation/deployment/volume-mapping.md
- Discord: https://discord.gg/kaw6jKbKts
