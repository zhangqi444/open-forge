---
name: radarec-project
description: Web GUI for finding similar movies to selected Radarr movies. Upstream: https://github.com/TheWicklowWolf/RadaRec
---

# RadaRec

Web GUI for finding similar movies to selected Radarr movies, powered by TMDB. Suggests similar titles and can automatically add them to Radarr. Upstream: <https://github.com/TheWicklowWolf/RadaRec>.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | [GitHub README](https://github.com/TheWicklowWolf/RadaRec#run-using-docker-compose) | ✅ | Recommended |
| Docker run | [Docker Hub](https://hub.docker.com/r/thewicklowwolf/radarec) | ✅ | Quick start |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Which install method?" | options | All |
| config | Radarr URL (e.g. http://192.168.1.2:8686) | URL | All |
| config | Radarr API key | string | All |
| config | Root folder path for movies | path | All |
| config | TMDB API key | string | All |
| config | Port to expose RadaRec on | number | All |

## Docker Compose install

Source: <https://github.com/TheWicklowWolf/RadaRec>

```yaml
services:
  radarec:
    image: thewicklowwolf/radarec:latest
    container_name: radarec
    volumes:
      - /path/to/config:/radarec/config
      - /etc/localtime:/etc/localtime:ro
    ports:
      - 5000:5000
    restart: unless-stopped
```

## Configuration

Environment variables (set in compose or pass via `-e`):

| Variable | Default | Description |
|---|---|---|
| `PUID` | `1000` | User ID to run as |
| `PGID` | `1000` | Group ID to run as |
| `radarr_address` | `http://192.168.1.2:8686` | Radarr URL |
| `radarr_api_key` | `` | Radarr API key |
| `root_folder_path` | `/data/media/movies/` | Movies root folder |
| `tmdb_api_key` | `` | TMDB API key |
| `quality_profile_id` | `1` | Radarr quality profile ID |
| `minimum_rating` | `5.5` | Minimum TMDB movie rating |
| `minimum_votes` | `50` | Minimum vote count |
| `language_choice` | `all` | ISO-639 two-letter language code |
| `auto_start` | `False` | Run automatically at startup |
| `dry_run_adding_to_radarr` | `False` | Test without adding to Radarr |

Data directory: `/radarec/config`

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

## Gotchas

- Both a Radarr API key and a TMDB API key are required.
- Default port is 5000 — may conflict with other services.
- `dry_run_adding_to_radarr=True` is useful for testing before live adds.

## References

- GitHub: <https://github.com/TheWicklowWolf/RadaRec>
- Docker Hub: <https://hub.docker.com/r/thewicklowwolf/radarec>
