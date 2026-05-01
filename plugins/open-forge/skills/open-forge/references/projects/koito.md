# Koito

**Modern, themeable ListenBrainz-compatible music scrobbler for self-hosters — tracks listening habits, supports relay to existing scrobblers, and imports from Maloja, ListenBrainz, LastFM, and Spotify.**
Official site: https://koito.io
Demo: https://koito.mnrva.dev
GitHub: https://github.com/gabehf/Koito

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | SQLite by default |

---

## Inputs to Collect

### Required
- Volume path — host path for Koito config/data at `/etc/koito`

---

## Software-Layer Concerns

### Docker Compose (minimal)
```yaml
services:
  koito:
    image: gabehf/koito:latest
    container_name: koito
    environment:
      - KOITO_SQLITE_ENABLED=true   # not needed after v0.2.0
    ports:
      - "4110:4110"
    volumes:
      - ./koito:/etc/koito
    restart: unless-stopped
```

### Ports
- `4110` — Koito web UI and scrobble API

### ListenBrainz compatibility
Koito implements the ListenBrainz API — configure any scrobbling client (Pano Scrobbler, Strawberry, etc.) to point at your Koito instance instead of ListenBrainz.

### Relay mode
Can relay scrobbles to another ListenBrainz-compatible service (e.g. the real ListenBrainz, Maloja) — safe to run alongside your existing setup without losing data.

### Data import
Supports importing listening history from:
- Maloja
- ListenBrainz
- LastFM
- Spotify

### Key features
- Sleek, themeable UI
- Listening stats and visualizations
- Image sources (album art) configurable
- Full configuration reference: https://koito.io/reference/configuration/

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- Project is under active development and considered "unstable" — expect some bugs
- `KOITO_SQLITE_ENABLED=true` is required in current versions; will be removed in v0.2.0
- Set up image sources before importing data for best results
- Use relay mode if you want to trial Koito without fully replacing your current scrobbler

---

## References
- Installation guide: https://koito.io/guides/installation/
- Data importing guide: https://koito.io/guides/importing/
- Configuration reference: https://koito.io/reference/configuration/
- GitHub: https://github.com/gabehf/Koito#readme
