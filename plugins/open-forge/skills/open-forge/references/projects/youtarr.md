---
name: Youtarr
description: "Self-hosted YouTube channel downloader for media servers. Docker. Node.js + yt-dlp. DialmasterOrg/Youtarr. Channel subscriptions, SponsorBlock, NFO metadata, Plex/Jellyfin/Kodi/Emby, content ratings, Discord notifications, REST API, Unraid ready."
---

# Youtarr

**Self-hosted YouTube downloader for media servers.** Subscribe to YouTube channels and auto-download videos, shorts, and streams. Generates NFO files, poster images, and embedded MP4 metadata for Plex, Jellyfin, Kodi, and Emby. SponsorBlock integration, per-channel quality settings, content ratings, age-based auto-cleanup, Discord notifications, and a full REST API.

Built + maintained by **DialmasterOrg (Chris Dial)**. See repo license.

- Upstream repo: <https://github.com/DialmasterOrg/Youtarr>
- Docs: <https://github.com/DialmasterOrg/Youtarr/tree/main/docs>
- ElfHosted managed hosting: <https://store.elfhosted.com/product/youtarr/>
- Unraid template: Community Applications (DialmasterOrg repo)
- Swagger API: `http://localhost:3087/swagger`

## Architecture in one minute

- **Node.js** backend + **React** frontend
- **yt-dlp** for all YouTube interaction and downloads
- **SQLite** (default) or external **MariaDB/MySQL** database
- Port **3087** (web UI + API)
- Videos stored in mounted `/downloads` volume
- Config in `/config` volume
- Cron-scheduled auto-downloads
- Resource: **low-medium** — Node.js + yt-dlp; disk and bandwidth bound during downloads

## Compatible install methods

| Infra      | Runtime             | Notes                                                        |
| ---------- | ------------------- | ------------------------------------------------------------ |
| **Docker** | official image      | **Only supported method** — no bare Node deployments         |
| **Unraid** | Community Apps      | Template via DialmasterOrg repo                              |
| **ElfHosted** | managed          | <https://store.elfhosted.com/product/youtarr/>               |

Installation guide: <https://github.com/DialmasterOrg/Youtarr/blob/main/docs/INSTALLATION.md>

## Install via Docker Compose

```bash
git clone https://github.com/DialmasterOrg/Youtarr.git
cd Youtarr
docker compose up -d
```

Default port: **3087**. Visit `http://localhost:3087`.

See environment variable reference: <https://github.com/DialmasterOrg/Youtarr/blob/main/docs/ENVIRONMENT_VARIABLES.md>

## First boot

1. Deploy via Docker Compose.
2. Visit `http://localhost:3087`.
3. Complete initial setup (admin credentials).
4. Add a **YouTube channel** (URL or channel ID):
   - Set per-channel quality (360p–4K)
   - Enable/disable shorts and streams
   - Set content rating
   - Assign to a subfolder/library group (optional)
5. Configure **schedule** for automatic downloads.
6. Configure **media server** (Plex API for auto-refresh; Jellyfin/Kodi/Emby via library scan).
7. Enable **SponsorBlock** in settings.
8. Configure **Discord webhook** for download notifications.
9. Put behind TLS.

## Channel subscriptions

- Subscribe to a YouTube channel by URL or channel ID
- Choose which content to download: **Videos**, **Shorts**, **Streams** (per-tab toggles)
- Per-channel resolution override (or use global default)
- Per-channel subfolder for multi-library support
- Per-channel content rating (G/PG/PG-13/R/NC-17/TV-*)

## Smart organization

Downloaded videos organized as:
```
downloads/
├── Channel Name/
│   ├── Channel Name - YYYY-MM-DD - Video Title.mp4
│   ├── Channel Name - YYYY-MM-DD - Video Title.nfo   ← metadata
│   └── Channel Name - YYYY-MM-DD - Video Title.jpg   ← poster
├── __kids/
│   └── Safe Channel/
└── __music/
    └── Music Channel/
```

Subfolder groups (`__kids`, `__music`, `__news`) create separate Plex/Jellyfin libraries for content curation.

## Features overview

| Feature | Details |
|---------|---------|
| Channel subscriptions | Subscribe + auto-download on schedule |
| Manual URL download | Paste a YouTube URL; preview metadata before downloading |
| Browse channels | Search all videos from a subscribed channel; filter by Videos/Shorts/Streams |
| In-app playback | Play downloaded videos in browser (no media server required) |
| YouTube search | Search YouTube from inside Youtarr; see what's downloaded/missing |
| SponsorBlock | Auto-remove sponsored segments |
| Quality control | Global + per-channel resolution (360p–4K) |
| NFO metadata | `*.nfo` files for Plex/Jellyfin/Kodi/Emby |
| Poster images | `*.jpg` poster per video |
| Content ratings | Per-video + per-channel; G/PG/PG-13/R/NC-17/TV-* |
| Plex integration | Auto-trigger library refresh via Plex API |
| Multi-library support | Subfolder groups for separate media server libraries |
| Auto-cleanup | Age and space-based video removal with dry-run preview |
| Discord notifications | Webhook alerts for new downloads |
| Download history | Duplicate detection; track what's downloaded |
| REST API | Full API with Swagger docs at `/swagger` |
| External DB | MariaDB/MySQL for large libraries |
| Synology NAS guide | DSM 7+ optimized setup in docs |
| Unraid CA template | Community Applications template |

## SponsorBlock

Youtarr passes SponsorBlock segment data to yt-dlp at download time. Sponsored segments, intros, outros, and non-music segments in music videos are automatically removed from downloaded files.

## Auto-cleanup

Configure rules to remove old videos:
- **Age-based**: remove videos older than N days
- **Space-based**: remove oldest videos when storage exceeds N GB
- **Dry-run mode**: preview what would be deleted before committing

## External database (MariaDB/MySQL)

For large libraries (10,000+ downloaded videos), switch to an external MariaDB/MySQL database. See: <https://github.com/DialmasterOrg/Youtarr/blob/main/docs/platforms/external-db.md>

## Gotchas

- **Docker only — no bare Node.js deployment.** The README explicitly states direct `npm start` or Node deployments are unsupported. Use Docker.
- **yt-dlp updates matter.** YouTube changes its API regularly. Keep the Youtarr Docker image updated (which bundles yt-dlp) to avoid download failures. The `dev-latest` image tracks unreleased fixes.
- **Plex auto-refresh requires Plex Pass + API key.** Plex library refresh requires a Plex API token. Jellyfin/Kodi/Emby refresh is triggered differently — see the respective media server guides.
- **Storage fills up fast.** Video content is large. Configure auto-cleanup rules or manually manage storage. Monitor disk usage.
- **Content ratings are manual (mostly).** Content ratings must be set per-channel or per-video in the UI. Some ratings can be derived from yt-dlp metadata (e.g., YouTube's age-restriction flags) but most require manual assignment.
- **YouTube rate limits.** yt-dlp respects rate limits but aggressive subscriptions with many channels may occasionally hit YouTube throttling. The scheduler spreads downloads; don't set schedules too aggressively.
- **`/config` volume contains your subscription database.** Back this up — it contains all your channel subscriptions, settings, and download history. The `/downloads` volume is regenerable (just re-download); `/config` is not.

## Backup

```sh
docker compose stop youtarr
sudo tar czf youtarr-config-$(date +%F).tgz config/
docker compose start youtarr
# downloads/ are the actual video files — back up separately if needed
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Node.js development, Docker, SponsorBlock, content ratings, Plex + Kodi + Jellyfin + Emby, Swagger REST API, Synology + Unraid guides, ElfHosted hosting. Maintained by DialmasterOrg.

## YouTube-downloader-family comparison

- **Youtarr** — Node.js, channel subscriptions, media server metadata, SponsorBlock, content ratings, REST API
- **Pinchflat** — Elixir, similar concept, channel subscriptions, also Jellyfin-ready; independent project
- **Tube Archivist** — Python+ElasticSearch, YouTube archive focus, custom media server UI; heavier
- **yt-dlp** — CLI; the underlying tool Youtarr uses; no web UI or subscriptions
- **Yubal** — Python+yt-dlp, YouTube Music-focused, organized music library; different scope

**Choose Youtarr if:** you want a self-hosted YouTube channel subscription + auto-download tool that organizes videos with proper media server metadata (NFO/posters), SponsorBlock, content ratings, and auto-cleanup.

## Links

- Repo: <https://github.com/DialmasterOrg/Youtarr>
- Install guide: <https://github.com/DialmasterOrg/Youtarr/blob/main/docs/INSTALLATION.md>
- Media servers: <https://github.com/DialmasterOrg/Youtarr/blob/main/docs/MEDIA_SERVERS.md>
- API (Swagger): `http://localhost:3087/swagger`
- ElfHosted: <https://store.elfhosted.com/product/youtarr/>
