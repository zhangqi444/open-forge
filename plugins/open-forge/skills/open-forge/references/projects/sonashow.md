---
name: sonashow
description: SonaShow recipe for open-forge. Web GUI for finding similar TV shows to selected Sonarr shows, powered by TVDB/TMDB APIs.
---

# SonaShow

Web GUI for finding TV shows similar to ones already in your Sonarr library. Upstream: <https://github.com/TheWicklowWolf/SonaShow>.

SonaShow queries TVDB and TMDB to surface similar shows, then offers to add them directly to Sonarr. It runs as a single Docker container on port `5000`.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | README docker-compose snippet | ✅ | Recommended — single container, volume for config |
| Docker run | Docker Hub `thewicklowwolf/sonashow` | ✅ | Quick test / no Compose |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | Sonarr URL | Free-text | e.g. `http://192.168.1.2:8989` |
| preflight | Sonarr API key | Free-text (sensitive) | Settings → General → Security in Sonarr |
| preflight | Root folder path for TV shows | Free-text | e.g. `/data/media/shows/` |
| preflight | TVDB API key | Free-text (sensitive) | Required for show lookups |
| preflight | TMDB API key | Free-text (sensitive) | Optional fallback |
| preflight | Minimum show rating | Number | Default `5.5` |
| preflight | Minimum vote count | Number | Default `50` |
| preflight | Language (ISO-639 2-letter) | Free-text | Default `all` |
| preflight | Quality profile ID in Sonarr | Number | Default `1` |
| preflight | Metadata profile ID in Sonarr | Number | Default `1` |

## Software-layer concerns

Single-container deployment. Config persists in a mounted volume. No external database required.

```yaml
services:
  sonashow:
    image: thewicklowwolf/sonashow:latest
    container_name: sonashow
    environment:
      - PUID=1000
      - PGID=1000
      - sonarr_address=http://192.168.1.2:8989
      - sonarr_api_key=YOUR_SONARR_API_KEY
      - root_folder_path=/data/media/shows/
      - tvdb_api_key=YOUR_TVDB_API_KEY
      - tmdb_api_key=YOUR_TMDB_API_KEY
      - minimum_rating=5.5
      - minimum_votes=50
      - language_choice=all
      - quality_profile_id=1
      - metadata_profile_id=1
      - search_for_missing_episodes=False
      - dry_run_adding_to_sonarr=False
      - auto_start=False
      - auto_start_delay=60
    volumes:
      - /path/to/config:/sonashow/config
      - /etc/localtime:/etc/localtime:ro
    ports:
      - 5000:5000
    restart: unless-stopped
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

No database migrations documented upstream. Config file in the mounted volume persists across upgrades.

## Gotchas

- All configuration is via environment variables — no UI config editor.
- `dry_run_adding_to_sonarr=True` lets you preview what would be added without making changes.
- `fallback_to_top_result` will use the highest-ranked result if no close match is found — may add unexpected shows.
- `language_choice` filters results; use `all` if you want results regardless of language.
- TVDB API key is separate from TMDB — both are recommended for best coverage.
