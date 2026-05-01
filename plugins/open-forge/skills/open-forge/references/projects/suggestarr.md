---
name: SuggestArr
description: "Self-hosted media recommendation and auto-request tool. Docker. Python + Vue. giuseppe99barchetta/SuggestArr. Jellyfin/Plex/Emby watch history → TMDb similar titles → Seer requests. AI-powered recs, cron scheduling, content filtering."
---

# SuggestArr

**Automated media recommendations based on your watch history.** SuggestArr reads recently watched content from Jellyfin, Plex, or Emby, finds similar movies and TV shows via TMDb, and automatically sends download requests to Seer (Overseerr/Jellyseerr). Optional AI-powered recommendations via any OpenAI-compatible LLM. Runs on a configurable cron schedule; managed via a web UI.

Built + maintained by **giuseppe99barchetta**. See repo license.

- Upstream repo: <https://github.com/giuseppe99barchetta/SuggestArr>
- Docker Hub: <https://hub.docker.com/r/ciuse99/suggestarr>
- Discord: <https://discord.com/invite/JXwFd3PnXY>

## Architecture in one minute

- **Python** backend (Flask) + **Vue.js** frontend
- **SQLite** (default), **PostgreSQL**, or **MySQL** database
- Integrations: Jellyfin / Plex / Emby → TMDb API → Seer (Overseerr/Jellyseerr)
- Optional: OpenAI-compatible LLM for AI-powered recommendations
- Port **5000** (configurable via `SUGGESTARR_PORT`)
- Config stored in `./config_files/` volume
- Resource: **low** — Python; API-call-bound

## Compatible install methods

| Infra      | Runtime                    | Notes                          |
| ---------- | -------------------------- | ------------------------------ |
| **Docker** | `ciuse99/suggestarr`       | **Primary** — Docker Hub       |
| **Python** | `pip install` from source  | Python 3.x + manual setup      |

## Inputs to collect

| Input                         | Example                         | Phase   | Notes                                                                       |
| ----------------------------- | ------------------------------- | ------- | --------------------------------------------------------------------------- |
| Media server type + URL       | Jellyfin `http://jellyfin:8096` | Source  | Jellyfin, Plex, or Emby                                                     |
| Media server API key/token    | from server settings            | Auth    | Jellyfin API key or Plex token                                              |
| TMDb API key                  | from themoviedb.org             | Data    | Free at <https://www.themoviedb.org/settings/api>                          |
| Seer URL + API key            | `http://overseerr:5055`         | Target  | Overseerr or Jellyseerr where requests are sent                             |
| LLM API key (optional)        | OpenAI / Ollama / Gemini        | AI      | For AI-powered recommendations (beta)                                       |

## Install via Docker Compose

```yaml
services:
  suggestarr:
    image: ciuse99/suggestarr:latest
    container_name: SuggestArr
    restart: always
    ports:
      - "${SUGGESTARR_PORT:-5000}:${SUGGESTARR_PORT:-5000}"
    volumes:
      - ./config_files:/app/config/config_files
    environment:
      - LOG_LEVEL=${LOG_LEVEL:-info}
      - SUGGESTARR_PORT=${SUGGESTARR_PORT:-5000}
```

```bash
docker compose up -d
```

Visit `http://localhost:5000`.

## First boot

1. `docker compose up -d`.
2. Visit `http://localhost:5000`.
3. Configure in the web UI:
   - **Media server**: select Jellyfin/Plex/Emby; enter URL + API key
   - **TMDb**: enter TMDb API key
   - **Seer**: enter Overseerr/Jellyseerr URL + API key
   - **User selection**: optionally restrict to specific users' watch histories
   - **Cron schedule**: set how often to run (e.g. daily at 3 AM)
   - **Content filters**: exclude content available on streaming platforms in your country
4. Run manually (or wait for cron) → check logs in real-time.
5. In Seer, review and approve auto-requested titles.

## How it works

```
1. Cron trigger (or manual run)
2. Fetch recently watched content from Jellyfin/Plex/Emby
3. For each watched title → query TMDb for similar movies/shows
4. (Optional) Send history to LLM → AI generates personalized recommendations with reasoning
5. Filter out: already requested, already in library, filtered streaming platforms
6. Send download requests to Seer for new recommendations
7. Review in Seer → approve/deny
```

## AI-powered recommendations (beta)

When an OpenAI-compatible LLM is configured:
- Watch history is sent to the LLM
- LLM generates personalized suggestions with reasoning ("You might like X because you watched Y and Z")
- Results sent to Seer the same way as TMDb recommendations

Compatible with: OpenAI, Ollama (local), Gemini, LiteLLM, and any OpenAI-compatible API.

## AI Search (beta)

Describe in natural language what you want to watch:
> "Something like Breaking Bad but set in the UK"

SuggestArr queries the LLM, which returns matching titles personalised to your watch history, with one-click request to Seer.

## Content filtering

SuggestArr can exclude titles already available on streaming platforms (Netflix, Disney+, etc.) in your country — avoiding requesting content you can watch for free. Configure the streaming country in settings.

## User selection for Seer requests

By default, SuggestArr makes requests as the Seer admin. You can configure it to use a specific local Seer user — useful for separating auto-requests from manual requests and for Seer approval workflows.

## Gotchas

- **Seer (Overseerr or Jellyseerr) is required.** SuggestArr is a recommendation engine, not a download manager — it sends requests to Seer, which handles the actual downloading via Radarr/Sonarr. You need a working Seer instance connected to Radarr/Sonarr.
- **TMDb API key is required.** Free and easy to get at themoviedb.org. Without it, no similarity searches.
- **Only local Seer users supported for user selection.** SSO/OAuth Seer users are not yet supported for the user selection feature. Only local Seer accounts work.
- **AI recommendations are beta.** LLM integration is experimental. Results quality depends on the model and may be inconsistent. TMDb-based recommendations are more stable.
- **Watch history lookback.** SuggestArr fetches "recently watched" content — configure the lookback window in settings to balance recency vs. variety of recommendations.
- **External DB for large libraries.** SQLite works fine for personal use. For large libraries or multiple users, switch to PostgreSQL or MySQL for better performance.
- **Review Seer queue.** SuggestArr sends requests automatically, but Seer can be configured to require approval before downloading. Review the Seer request queue regularly to avoid accumulating unwanted downloads.

## Backup

```sh
sudo tar czf suggestarr-$(date +%F).tgz config_files/
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Python + Vue development, Docker Hub (amd64+arm64), AI recommendations (beta), AI search (beta), Jellyfin + Plex + Emby support, content filtering, external DB support. Solo-maintained by giuseppe99barchetta. Discord community.

## Media-automation-family comparison

- **SuggestArr** — Python, watch history → TMDb recs → Seer requests, AI-powered recs, content filter
- **Overseerr/Jellyseerr** — the request manager that SuggestArr sends TO; not a recommender
- **Radarr/Sonarr** — download managers; SuggestArr feeds Seer which feeds these
- **Plex Discover** — SaaS recommendations within Plex; not self-hosted; different scope
- **Trailarr** — Python, trailer management; different scope

**Choose SuggestArr if:** you want automated media recommendations driven by your watch history, with TMDb similarity matching + optional AI-powered suggestions, feeding directly into your Seer/Radarr/Sonarr pipeline.

## Links

- Repo: <https://github.com/giuseppe99barchetta/SuggestArr>
- Docker Hub: <https://hub.docker.com/r/ciuse99/suggestarr>
- Discord: <https://discord.com/invite/JXwFd3PnXY>
- TMDb API: <https://www.themoviedb.org/settings/api>
