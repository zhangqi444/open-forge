# SoFE (Sonarr Anime Filler Excluder)

**What it is:** A Python tool that integrates Sonarr and Anime Filler List to configure Sonarr to monitor only non-filler anime episodes. Optionally creates separate Plex collections for non-filler and filler episodes. Run once per series via Docker — not a persistent daemon.

**Official URL:** https://github.com/chkpwd/sofe
**Container:** `ghcr.io/chkpwd/sofe:latest`
**License:** MIT
**Stack:** Python; Docker (one-shot container)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any homelab | Docker (one-shot) | Run once per anime series to configure Sonarr |
| Any homelab | Docker Compose (manual trigger) | Define as a compose service; run with `docker compose run` |

---

## Inputs to Collect

### Per-run (required)
- `SONARR_URL` — URL to your Sonarr instance (e.g. `https://sonarr.local`)
- `SONARR_API_KEY` — Sonarr API key (Settings → General → API Key)
- `SONARR_SERIES_ID` — Sonarr's internal ID for the anime series (find in the series URL: `/series/<id>`)
- `AFL_ANIME_NAME` — the anime's URL slug on AnimeFillerList.com (e.g. `one-piece` from `https://www.animefillerlist.com/shows/one-piece`)

### Optional (Plex collections)
- `PLEX_URL` — Plex server URL (e.g. `http://127.0.0.1:32400`)
- `PLEX_TOKEN` — Plex authentication token
- `CREATE_PLEX_COLLECTION` — `True` to create Plex collections for filler/non-filler episodes
- `MONITOR_NON_FILLER_SONARR_EPISODES` — `True` to unmonitor filler episodes in Sonarr
- `PLEX_ANIME_LIBRARY` — name of your Plex anime library (e.g. `Anime`)

---

## Software-Layer Concerns

**Docker run (one-shot):**
```bash
docker run --rm \
  -e SONARR_URL="https://sonarr.local" \
  -e SONARR_API_KEY="<your_api_key>" \
  -e SONARR_SERIES_ID="187" \
  -e AFL_ANIME_NAME="one-piece" \
  -e PLEX_URL="http://127.0.0.1:32400" \
  -e PLEX_TOKEN="<your_plex_token>" \
  -e CREATE_PLEX_COLLECTION="True" \
  -e MONITOR_NON_FILLER_SONARR_EPISODES="True" \
  -e PLEX_ANIME_LIBRARY="Anime" \
  ghcr.io/chkpwd/sofe:latest
```

**Finding the anime name for AFL:**
1. Go to https://www.animefillerlist.com/shows
2. Find your anime and note the URL slug (e.g. `naruto` from `.../shows/naruto`)
3. Use that slug as `AFL_ANIME_NAME`

**Finding Sonarr series ID:**
- Open the series in Sonarr — the ID appears in the URL: `http://sonarr:8989/series/187`

**Plex token retrieval:**
1. Open Plex in a browser, log in
2. Open DevTools → Network tab → reload
3. Find any `plex.tv` request and look for `X-Plex-Token` in headers or URL params

**Upgrade procedure:** Pull the latest image tag before each run:
```bash
docker pull ghcr.io/chkpwd/sofe:latest
```

---

## Gotchas

- **One-shot tool** — not a daemon; run it once per series to apply filler filtering; re-run after new seasons air
- **AFL anime name must match the URL slug exactly** — if it doesn't match, SoFE can't find filler episode data
- **Sonarr series ID is internal** — different from the TVDB/IMDB ID; find it from the Sonarr series URL
- **Plex integration is optional** — if you only want Sonarr monitoring, omit Plex env vars
- **AnimeFillerList coverage** — only anime with entries on animefillerlist.com are supported; not all anime are listed

---

## Links
- GitHub: https://github.com/chkpwd/sofe
- Container: ghcr.io/chkpwd/sofe:latest
- Anime Filler List: https://www.animefillerlist.com
