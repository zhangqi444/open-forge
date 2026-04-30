---
name: YourSpotify
description: "Self-hosted Spotify listening-stats dashboard — tracks what you listen to via Spotify Web API, stores in MongoDB, displays rich statistics (top tracks/artists/albums/genres/hours, listen history import, Prometheus metrics). Node.js + MongoDB. GPL-3.0."
---

# YourSpotify

YourSpotify is **"last.fm for self-hosters, but it tracks YOUR Spotify plays"** — a self-hosted stats dashboard for Spotify listening habits. The server polls your Spotify account periodically via the **Spotify Web API** (once you've authorized via OAuth), stores plays in MongoDB, and the web client presents rich visualizations: top tracks/artists/albums/genres by time period, listening hours per day/week/month, import of past listening history from Spotify privacy-data exports, sharing between users, Prometheus metrics.

Built + maintained by **Yooooomi**; active project; donation-funded. Used by Spotify nerds, Obsidian-dashboard-integrators, homelab-completionists.

**IMPORTANT: requires a Spotify app registration (free — any Spotify account).** This is NOT a "just deploy and it works" app — you must create your own **Spotify Developer application** for your deployment.

Features:

- **Automatic tracking** via Spotify Web API polling
- **Top tracks/artists/albums/genres** by time period
- **Listening hours** heatmaps + trends
- **Historical import** from Spotify privacy-data download (GDPR export) — "streaming history" JSON files
  - **Privacy data**: last 12 months
  - **Full privacy data** (recommended): entire account history, ordered from Spotify (takes ~30 days to receive)
- **Multi-user** — each user links their own Spotify
- **Prometheus metrics** — basic-auth protected
- **CORS configurable** for multi-origin setups
- **Timezone configurable**

- Upstream repo: <https://github.com/Yooooomi/your_spotify>
- LinuxServer.io alt image: <https://github.com/linuxserver/docker-your_spotify>
- Donation: <https://www.paypal.com/donate/?hosted_button_id=BLAPT49PK9A8G>
- Spotify dashboard (for app registration): <https://developer.spotify.com/dashboard/applications>
- Docker images:
  - `yooooomi/your_spotify_server`
  - `yooooomi/your_spotify_client`
- Releases: <https://github.com/Yooooomi/your_spotify/releases>

## Architecture in one minute

- **Server (Node.js)** — polls Spotify Web API, stores to MongoDB, serves API to web client
- **Web client (Node.js/React)** — UI
- **MongoDB** — stores plays + user tokens
- **Spotify Developer Application** — YOU register one for your deployment
- **Resource**: small — 200-500 MB RAM typical; Mongo footprint scales with play history

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Docker Compose** (server + client + mongo)                       | **Upstream-primary**                                                               |
| LinuxServer image  | `linuxserver/your_spotify`                                                | Alternate single-image variant                                                             |
| Bare-metal         | Node 18+ + MongoDB — upstream documents but discouraged                                         | "not recommended"                                                                                      |
| Kubernetes         | Community manifests                                                                               | Works                                                                                                  |
| ARM                | Use `mongo:4.4` (not 5+) on older ARM hardware                                                           | Upstream warning                                                                                                    |

## Inputs to collect

| Input                    | Example                                                   | Phase        | Notes                                                                    |
| ------------------------ | --------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain                   | `stats.example.com` (client) + `api.example.com` (server)       | URL          | Two endpoints; API + client                                                      |
| Spotify app              | Create at Spotify Developer Dashboard                                   | Prereq       | **REQUIRED — free** with any Spotify account                                                     |
| `SPOTIFY_PUBLIC`         | App's Client ID                                                       | OAuth        | From Spotify dashboard                                                                          |
| `SPOTIFY_SECRET`         | App's Client Secret                                                            | OAuth        | From Spotify dashboard — **treat as password**                                                                     |
| Redirect URI             | `http://<server>:8080/oauth/spotify/callback`                                        | OAuth        | Must be added to Spotify app's allowed list — EXACT match                                                                                  |
| `API_ENDPOINT`           | Server URL (what the client uses + what Spotify redirects to)                                     | Config       | Must match Spotify app redirect URI domain                                                                                        |
| `CLIENT_ENDPOINT`        | Web client URL                                                                                    | Config       | CORS accepts this by default                                                                                                                  |
| MongoDB                  | bundled or external                                                                                         | DB           | Version 6 preferred; 4.4 for older ARM                                                                                                                         |

## Install via Docker Compose

```yaml
services:
  server:
    image: yooooomi/your_spotify_server               # pin version in prod
    restart: always
    ports: ["8080:8080"]
    depends_on: [mongo]
    environment:
      API_ENDPOINT: http://stats-api.example.com       # must be Spotify-authorized
      CLIENT_ENDPOINT: http://stats.example.com
      SPOTIFY_PUBLIC: ${SPOTIFY_CLIENT_ID}
      SPOTIFY_SECRET: ${SPOTIFY_CLIENT_SECRET}
      TIMEZONE: America/Los_Angeles
  mongo:
    image: mongo:6
    volumes:
      - ./your_spotify_db:/data/db
  web:
    image: yooooomi/your_spotify_client
    restart: always
    ports: ["3000:3000"]
    environment:
      API_ENDPOINT: http://stats-api.example.com
```

## First boot

1. Create Spotify app at <https://developer.spotify.com/dashboard/applications>
2. Copy Client ID + Client Secret into `.env`
3. Set redirect URI in Spotify app config → EXACTLY match `API_ENDPOINT + /oauth/spotify/callback`
4. Deploy + start services
5. Browse client → click "Login with Spotify" → OAuth flow → authorize
6. Wait — first polls begin; listen to some music to populate data
7. Import history (see below for recommended "Full privacy data" path)
8. Put both endpoints behind TLS reverse proxy
9. Set up backups for Mongo data volume

## Data & config layout

- MongoDB `your_spotify` DB — users, plays, artists, albums, tracks, tokens
- `.env` — Spotify credentials (guard carefully)
- No file storage

## Backup

```sh
mongodump --uri "mongodb://localhost:27017/your_spotify" --out ./backup-$(date +%F)/
# Or volume tar:
sudo tar czf your-spotify-db-$(date +%F).tgz your_spotify_db/
```

## Upgrade

1. Releases: <https://github.com/Yooooomi/your_spotify/releases>. Active.
2. Docker: bump tags on server + client images.
3. MongoDB major version upgrades (e.g., 4.4→6) = follow Mongo guide separately.
4. **Back up Mongo before upgrading schemas.**

## Gotchas

- **Spotify Developer App is MANDATORY.** No shared/official credentials exist. Each self-host instance needs its own app. Free to create; process takes 5 minutes.
- **Redirect URI must match EXACTLY** — scheme (http/https) + host + port + path. Common failure: localhost during test → real domain in prod. Add BOTH to Spotify app's redirect URIs if using both environments.
- **API_ENDPOINT must be in Spotify's allowed redirects.** Changing domain after deployment = go update Spotify app config.
- **Spotify API rate limits** — YourSpotify polls periodically. Aggressive polling can hit Spotify's rate limit (429). Default cadence is tuned reasonably; don't cranky-modify it.
- **MongoDB version on ARM caveat**: upstream explicit note — Mongo 5+ has issues on some ARM hardware. Use `mongo:4.4` if on older Pi / ARMv7.
- **Mongo on NFS = bad idea**. MongoDB officially doesn't support NFS/SMB. Use local disk for DB volume.
- **Historical data import**:
  - **Privacy data** (instant download) = last 12 months
  - **Full privacy data** (extended archive) = entire history but takes ~30 days to receive
  - YourSpotify accepts both; upstream recommends requesting full archive early + using privacy-data in the meantime
- **SPOTIFY_SECRET = treat as password.** Don't commit to git. Use `.env` + proper permissions. Rotating = generate new secret in Spotify dashboard + update config.
- **Cookie validity + auth**: default 1h cookie; reauth fails will auto-renew via Spotify refresh token. If refresh token is revoked (user disconnected app in Spotify's UI), user must re-login.
- **`FRAME_ANCESTORS` env var** — controls where YourSpotify can be iframe-embedded. The sentinel value `i-want-a-security-vulnerability-and-want-to-allow-all-frame-ancestors` is LITERALLY that — don't use it in production. This is a great example of upstream UX of making the insecure option self-documenting.
- **`MONGO_NO_ADMIN_RIGHTS=false` default** asks for admin on Mongo — fine for bundled Mongo; set `true` if you point at an external Mongo where your user lacks admin (typical for DB-as-a-service).
- **Prometheus metrics** exposed with optional basic auth — pair with Grafana for long-term retention + dashboards beyond YourSpotify's built-in.
- **Privacy awareness**: your Spotify play history is personal. Some songs reveal mood + life-stage + medical context (grief playlists, breakup playlists). Encrypt backups. Consider carefully who else has access to your instance.
- **Spotify account types**: Free accounts work (read access). Premium unnecessary for YourSpotify.
- **Multi-user sharing**: each user independently links their own Spotify. YourSpotify has per-user stats with optional sharing.
- **License**: **GPL-3.0** (check repo).
- **Project health**: Yooooomi solo + active; donation-funded (PayPal); active release cadence. Bus-factor-1 mitigated by active community + clean Node stack (re-buildable by any Node dev).
- **Alternatives worth knowing:**
  - **last.fm** — commercial cloud music scrobbler; broader (not just Spotify)
  - **Libre.fm** — FOSS last.fm-alt
  - **Maloja** — self-hosted music scrobbler; broader format support
  - **Multi-Scrobbler** — self-hosted; polls multiple sources (Spotify/Plex/Jellyfin/Subsonic) + forwards to scrobble services
  - **Stats.fm** — commercial Spotify-stats web app
  - **Choose YourSpotify if:** Spotify-specific + self-host + rich stats UI + history import.
  - **Choose Maloja if:** want multi-source scrobbling (Plex + Spotify + Jellyfin etc.).
  - **Choose Multi-Scrobbler if:** want to aggregate + re-scrobble to last.fm.

## Links

- Repo: <https://github.com/Yooooomi/your_spotify>
- Releases: <https://github.com/Yooooomi/your_spotify/releases>
- Docker Hub (server): <https://hub.docker.com/r/yooooomi/your_spotify_server>
- Docker Hub (client): <https://hub.docker.com/r/yooooomi/your_spotify_client>
- LinuxServer image: <https://github.com/linuxserver/docker-your_spotify>
- Spotify Developer Dashboard: <https://developer.spotify.com/dashboard/applications>
- Spotify API docs: <https://developer.spotify.com/documentation/web-api>
- Spotify privacy-data request: <https://www.spotify.com/account/privacy/>
- last.fm (alt): <https://www.last.fm>
- Maloja (alt): <https://github.com/krateng/maloja>
- Multi-Scrobbler (alt): <https://github.com/FoxxMD/multi-scrobbler>
