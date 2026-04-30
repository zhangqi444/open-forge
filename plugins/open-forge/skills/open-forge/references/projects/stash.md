---
name: Stash
description: Self-hosted media organizer and browser for adult video/image collections — "Jellyfin for adult content". Go binary (cross-platform) + SQLite; metadata scraping from 100+ community sources, tagging, performers/studios/scenes, streaming in-browser. AGPL-3.0.
---

# Stash

Stash is a media organizer purpose-built for adult video + image libraries. Point it at your files, it scans + extracts metadata + generates thumbnails/sprites/previews, lets you tag/organize by performer/studio/scene/tag, and streams everything in a polished web UI. 100+ community-maintained scrapers pull metadata from adult-industry sites.

Cross-platform Go binary. Single process. Ships as: Windows .exe, macOS .app, Linux binary, or Docker. SQLite DB.

- Upstream repo: <https://github.com/stashapp/stash>
- Website: <https://stashapp.cc>
- Docs: <https://docs.stashapp.cc>
- Community forum: <https://discourse.stashapp.cc>
- Discord: <https://discord.gg/2TsNFKt>

**NSFW notice**: Stash explicitly organizes adult content. Ensure your use complies with applicable laws; it's designed for adults managing their own legally-acquired content.

## Architecture in one minute

- **Single Go binary** (`stash`) — HTTP server + UI + scanner + thumbnailer
- **SQLite** DB (default); MySQL/Postgres in newer versions (experimental)
- **ffmpeg** — required for transcoding, sprite generation, preview clips (bundled in Docker image; system-installed for native installs)
- **Generated assets**: thumbnails, animated previews, sprite maps for scrubbing, transcoded files — written to a separate `generated/` dir
- **Scrapers**: community plugins, YAML-configured, pull from adult industry sites (RarBG clones, studio websites, AV databases)

## Compatible install methods

| Platform | Runtime                                                  | Notes                                                             |
| -------- | -------------------------------------------------------- | ----------------------------------------------------------------- |
| Docker   | `stashapp/stash:<VERSION>`                               | **Recommended** — bundles ffmpeg                                    |
| Windows  | `stash-win.exe`                                           | Win10+ only (v0.27.0 dropped Win7/8/Server 2008/2012)              |
| macOS    | `Stash.app.zip`                                           | Unsigned → needs Right-Click → Open first time                      |
| Linux    | `stash-linux` binary (amd64) / other arches via release   | ffmpeg must be system-installed                                     |
| NAS      | Unraid / Synology / QNAP community packages              | Widely available                                                    |

## Version/OS support note (from README)

As of **v0.27.0**, Stash no longer supports Windows 7, 8, Server 2008, Server 2012. Current releases target Win10+, recent macOS, recent Linux distros.

## Inputs to collect

| Input                 | Example                   | Phase     | Notes                                                    |
| --------------------- | ------------------------- | --------- | -------------------------------------------------------- |
| Port                  | `9999:9999`               | Network   | Default `STASH_PORT=9999`                                 |
| Config dir            | `./config`                | Storage   | `/root/.stash` inside container                            |
| Data (media) dir      | `./data`                  | Storage   | Your media library                                        |
| Metadata dir          | `./metadata`              | Storage   | DB + settings                                             |
| Cache dir             | `./cache`                 | Storage   | Temp transcodes                                            |
| Blobs dir             | `./blobs`                 | Storage   | Scene covers, images (binary blobs)                        |
| Generated dir         | `./generated`             | Storage   | Thumbnails, sprites, preview clips, transcodes              |
| Admin password        | set on first-run wizard   | Bootstrap | Optional — can run open on trusted LAN, but strongly recommend setting one |
| ffmpeg                | bundled in Docker          | Runtime   | Native installs: `apt install ffmpeg` or equivalent         |

## Install via Docker Compose

Upstream-sanctioned compose (`/docker/production/docker-compose.yml`):

```yaml
# APPNICENAME=Stash
# APPDESCRIPTION=An organizer for your porn, written in Go
services:
  stash:
    image: stashapp/stash:v0.28.1    # pin; check https://github.com/stashapp/stash/releases
    container_name: stash
    restart: unless-stopped
    ports:
      - "9999:9999"
    # For DLNA: use host networking (and comment out ports above)
    # network_mode: host
    logging:
      driver: "json-file"
      options:
        max-file: "10"
        max-size: "2m"
    environment:
      - STASH_STASH=/data/
      - STASH_GENERATED=/generated/
      - STASH_METADATA=/metadata/
      - STASH_CACHE=/cache/
      - STASH_PORT=9999
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./config:/root/.stash        # configs, scrapers, plugins
      - ./data:/data                 # your media library
      - ./metadata:/metadata         # SQLite DB + settings
      - ./cache:/cache               # transient
      - ./blobs:/blobs               # scene covers, images
      - ./generated:/generated       # generated thumbnails, previews, sprites
```

Quickstart:

```sh
mkdir stashapp && cd stashapp
curl -o docker-compose.yml https://raw.githubusercontent.com/stashapp/stash/develop/docker/production/docker-compose.yml
# Edit image tag to pin; edit volume paths
docker compose up -d
```

Then browse `http://<host>:9999` → setup wizard → set username + password + library path (`/data`) → run initial scan.

## Install on bare metal (Linux)

```sh
# Install ffmpeg first
sudo apt install ffmpeg

# Download binary
wget https://github.com/stashapp/stash/releases/latest/download/stash-linux
chmod +x stash-linux
./stash-linux
```

Browse `http://localhost:9999`.

## Windows + macOS quirks

- **Windows**: Unsigned Authenticode — Defender may flag it on first run. "Run anyway" or sign it yourself.
- **macOS**: Gatekeeper blocks unsigned apps. Right-Click → **Open** → Open Anyway. Or strip quarantine: `xattr -dr com.apple.quarantine /Applications/Stash.app`.

## Data & config layout

In-container paths (match env vars):

- `/root/.stash/` — config + scrapers + plugins
- `/data/` — your media files (read-only mount fine if you never want Stash to move/rename)
- `/metadata/` — `stash-go.sqlite` or similar DB
- `/cache/` — temp transcodes; can delete to reclaim space
- `/blobs/` — scene cover images, performer photos
- `/generated/` — thumbnails + animated previews + sprite maps + pre-transcoded files (can be very large for big libraries)

## Backup

```sh
docker compose exec -T stash tar czf - -C /metadata . \
  | split -b 2G - stash-metadata-$(date +%F).tgz.

# Config + plugins
tar czf stash-config-$(date +%F).tgz config/

# Generated dir: regeneratable; optional to back up (saves CPU on restore)
tar czf stash-generated-$(date +%F).tgz generated/
```

Critical: `metadata/` (DB) + `config/` + `blobs/`. `generated/` + `cache/` are regeneratable.

## Upgrade

1. Releases: <https://github.com/stashapp/stash/releases>.
2. Development Preview builds at "latest_develop" tag for bleeding-edge.
3. Docker: `docker compose pull && docker compose up -d`. DB migrations on startup.
4. **Back up `metadata/` before every upgrade.** Schema migrations are one-way.
5. v0.27+ dropped older Windows; check if you're affected.
6. Release notes per version.

## Gotchas

- **Reverse proxy needs WebSocket support.** UI live-updates scan progress via WS.
- **DLNA requires host networking** (`network_mode: host`) — breaks port mapping; only enable if you need it.
- **Generated dir can be huge.** 10k scenes = 50+ GB of thumbnails + sprites + previews. Plan storage.
- **Scrapers scrape publicly-available sites** that often change HTML; expect scraper breakage as sites update. Community updates scrapers frequently.
- **First scan can be slow.** Thumbnail + sprite generation on a large library = hours. Runs CPU-bound with ffmpeg.
- **SQLite is the default** and scales to 100k+ scenes. MySQL/Postgres support is experimental in newer versions.
- **Community-maintained scrapers** are at <https://github.com/stashapp/CommunityScrapers>. Drop YAML files into `config/scrapers/`.
- **Plugins** (Python / JavaScript) at <https://github.com/stashapp/CommunityScripts>. Extend with custom tasks.
- **StashDB** is a community metadata network (like MusicBrainz for adult content). Integration optional.
- **Authentication**: OFF by default — anyone on your LAN can access. **Set a username + password** in the wizard. For internet exposure: add OIDC via the oauth2-proxy sidecar pattern or an auth middleware.
- **No native 2FA** yet. Put behind SSO/oauth2-proxy if you need it.
- **Performer privacy**: Stash stores performer images + scene links from the web; if you don't want "my collection browsable by someone who grabs my DB", encrypt the volume.
- **File organization**: Stash CAN rename/move files based on its metadata (dangerous; off by default).
- **Transcoding on-the-fly**: only if client can't play natively; adjusts quality per connection.
- **Development Preview** builds at `latest_develop` tag — use at your own risk; DB forward-compat only.
- **Logging** defaults are verbose; rotate via Docker's `max-size` + `max-file` as shown in compose.
- **Legal**: managing your own legally-acquired content on your own server = fine in most jurisdictions. Hosting for others or distributing = different legal surface.
- **Alternatives worth knowing:**
  - **Whisparr / Radarr-fork** — Radarr for adult; downloads, no media server UI
  - **Jellyfin / Plex / Emby** — general media servers; limited adult-metadata support
  - **Grrrid** (community project) — alternative UI
  - **MediaCMS** (general) — different focus; user-generated content

## Links

- Repo: <https://github.com/stashapp/stash>
- Website: <https://stashapp.cc>
- Docs: <https://docs.stashapp.cc>
- Docker README: <https://github.com/stashapp/stash/blob/develop/docker/production/README.md>
- Sample docker-compose: <https://raw.githubusercontent.com/stashapp/stash/develop/docker/production/docker-compose.yml>
- Releases: <https://github.com/stashapp/stash/releases>
- Docker Hub: <https://hub.docker.com/r/stashapp/stash>
- Community scrapers: <https://github.com/stashapp/CommunityScrapers>
- Community plugins: <https://github.com/stashapp/CommunityScripts>
- StashDB: <https://stashdb.org>
- Community forum: <https://discourse.stashapp.cc>
- Discord: <https://discord.gg/2TsNFKt>
- FAQ: <https://discourse.stashapp.cc/c/support/faq/28>
- Reverse proxy guide: <https://docs.stashapp.cc/guides/reverse-proxy/>
