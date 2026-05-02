# DeepSubX

**What it is:** A Dockerized tool that uses the DeepL API to translate subtitles for movies and TV shows in your local media library. Can translate existing `.srt` subtitle files or extract and translate embedded subtitles from `.mkv` video files. Optional Plex integration to trigger a library refresh after translation completes.

**Official URL:** https://github.com/garanda21/deepsubx
**Container:** `ghcr.io/garanda21/deepsubx:latest`
**License:** MIT
**Stack:** Docker; DeepL API backend

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended; mount media library |
| Homelab (NAS) | Docker | Mount NAS share paths as volumes |

---

## Inputs to Collect

### Pre-deployment (required)
- `DEEPL_API_KEY` — from https://www.deepl.com/pro-api (free tier available with monthly character limit)
- `./movies` volume — host path to your movies directory
- `./data` volume — persistent app data

### Optional (Plex integration)
- `PLEX_HOST` — Plex server hostname or IP
- `PLEX_PORT` — Plex server port (default: `32400`)
- `PLEX_TOKEN` — Plex authentication token (see gotchas for how to retrieve)

---

## Software-Layer Concerns

**Docker Compose:**
```yaml
services:
  app:
    image: ghcr.io/garanda21/deepsubx:latest
    ports:
      - "3000:3000"   # Backend API
      - "5173:5173"   # Frontend UI
    environment:
      - DEEPL_API_KEY=${DEEPL_API_KEY}
      - PLEX_HOST=${PLEX_HOST}
      - PLEX_PORT=${PLEX_PORT}
      - PLEX_TOKEN=${PLEX_TOKEN}
    volumes:
      - ./data:/data
      - ./movies:/movies
```

**Ports:**
- `3000` — Backend API
- `5173` — Frontend web UI

**Media folder structure expected:**

*Movies:*
```
/movies
  /Movie Title (Year)
    movie.mkv
    movie.srt     ← translated subtitle lands here
```

*TV Shows:*
```
/TV Show
  /Season 1
    episode1.mkv
    episode1.srt
```

**Embedded subtitle extraction:** Point DeepSubX at a `.mkv` file with embedded subtitle tracks; it will extract, translate, and save as a `.srt` sidecar.

**Plex token retrieval:**
1. Open your Plex server in a browser and log in
2. Open DevTools → Network tab → reload the page
3. Find any request to `plex.tv` and look for `X-Plex-Token` in the request headers or URL parameters

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`

---

## Gotchas

- **DeepL API key required** — free tier has a monthly 500,000 character limit; paid tiers available for larger libraries
- **DeepL free vs. pro keys** — free API keys use `api-free.deepl.com`; pro keys use `api.deepl.com`; the client handles this automatically based on key format
- **No TV show volume in default compose** — if you have TV shows, add a separate volume mount (e.g. `./tvshows:/tvshows`) and configure the path in the UI
- **Plex refresh is optional** — without Plex integration, subtitles are saved to disk; Plex picks them up on its next scheduled scan
- **No subtitle quality control** — machine translation quality depends on DeepL; complex dialogue, slang, and idioms may translate imperfectly

---

## Links
- GitHub: https://github.com/garanda21/deepsubx
- DeepL API: https://www.deepl.com/pro-api
- Container: ghcr.io/garanda21/deepsubx:latest
