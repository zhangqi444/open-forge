---
name: Unpackerr
description: "Daemon that extracts completed downloads for Starr apps (Sonarr/Radarr/Lidarr/Readarr). Go. Docker + packages. Unpackerr/unpackerr. Tars, rars, zips, 7zips, ISOs. Watch folder mode too."
---

# Unpackerr

**Daemon that extracts completed downloads so Starr apps can import them.** If rar files are stuck in your Sonarr/Radarr/Lidarr/Readarr activity queue, Unpackerr is your solution. Runs alongside your download client, watches for completed downloads, and extracts archives (tar, rar, zip, 7zip, gzip, bzip, ISO, encrypted archives) so the Starr apps can find and import the media. Also supports standalone watch-folder mode without Starr apps.

Built + maintained by **Go Lift**. MIT license.

- Upstream repo: <https://github.com/Unpackerr/unpackerr>
- Website + docs: <https://unpackerr.zip>
- Discord: <https://golift.io/discord>
- Docker Hub: `golift/unpackerr`
- GHCR: `ghcr.io/unpackerr/unpackerr`
- Packages: deb, rpm, pkg, dmg via packagecloud

## Architecture in one minute

- **Go** daemon — single binary / single container
- Runs continuously, polling Starr apps' APIs and/or a watch folder for completed downloads
- Connects to **Sonarr, Radarr, Lidarr, Readarr** APIs to identify completed downloads needing extraction
- Alternatively: standalone **watch folder** mode (no Starr app required)
- Resource: **tiny** — Go binary, low CPU/RAM

## Compatible install methods

| Infra          | Runtime                      | Notes                                                        |
| -------------- | ---------------------------- | ------------------------------------------------------------ |
| **Docker**     | `golift/unpackerr`           | **Primary** — Docker Hub + GHCR                              |
| **deb/rpm**    | packagecloud repo            | For bare-metal Linux servers                                 |
| **pkg/dmg**    | packagecloud / direct        | macOS (Homebrew tap also available)                          |
| **Unraid**     | Community App                | Available in Unraid CA                                       |

## Inputs to collect

| Input                          | Example                          | Phase    | Notes                                                                                   |
| ------------------------------ | -------------------------------- | -------- | --------------------------------------------------------------------------------------- |
| Download dir (host path)       | `/data/downloads`                | Storage  | Mount same path as your download client uses; Unpackerr needs to read/write archives   |
| Sonarr URL + API key           | `http://sonarr:8989` + API key   | Config   | In `unpackerr.conf` or env vars; repeat for each Starr app                             |
| Radarr URL + API key           | `http://radarr:7878` + API key   | Config   | Same                                                                                    |
| Lidarr/Readarr (optional)      | URL + API key                    | Config   | Add any Starr apps you use                                                              |
| Watch folders (optional)       | `/data/downloads/watch`          | Config   | For standalone mode without Starr apps                                                 |

## Install via Docker

```yaml
services:
  unpackerr:
    image: golift/unpackerr:0.15.2
    container_name: unpackerr
    volumes:
      - /data/downloads:/data/downloads    # same path as download client
    environment:
      # Timezone
      - TZ=America/New_York
      # Sonarr
      - UN_SONARR_0_URL=http://sonarr:8989
      - UN_SONARR_0_API_KEY=your-sonarr-api-key
      # Radarr
      - UN_RADARR_0_URL=http://radarr:7878
      - UN_RADARR_0_API_KEY=your-radarr-api-key
      # Optional: standalone watch folder
      # - UN_FOLDER_0_PATH=/data/downloads/watch
    restart: unless-stopped
```

Alternatively, use a config file (`unpackerr.conf`) mounted at the default path — see docs.

## Config file approach

```toml
# /config/unpackerr.conf
[sonarr]
  [[sonarr.instances]]
  url = "http://sonarr:8989"
  api_key = "your-key"
  paths = ["/data/downloads"]

[radarr]
  [[radarr.instances]]
  url = "http://radarr:7878"
  api_key = "your-key"
  paths = ["/data/downloads"]

[folder]
  [[folder.instances]]
  path = "/data/downloads/watch"
  extract_path = "/data/downloads/extracted"
  delete_after = "10m"
```

Full config reference: <https://unpackerr.zip/docs/install/configuration>

## How it works

1. Unpackerr queries Sonarr/Radarr/etc. APIs for completed downloads.
2. When it finds a completed item whose path contains an archive, it extracts it to the same directory.
3. The Starr app detects the extracted media and imports it.
4. After successful import, Unpackerr optionally deletes the extracted files (configurable).

## Supported archive types

**Rar, Zip, 7-Zip, Tar, Gzip, Tarred Gzips + Bzips, ISO disc images.** Recursive extraction (archives within archives). Encrypted rars and 7-zips (provide password in config).

## Backup

Unpackerr is stateless — nothing to back up. Config is in env vars or a config file (commit to your infrastructure git repo).

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Gotchas

- **Path mapping is critical.** Unpackerr must see archive files at the same filesystem path that the Starr apps report. If your Sonarr path is `/data/tv` but Unpackerr can only see `/downloads/tv`, configure `paths` in the Starr app section accordingly, or fix the volume mounts.
- **Delete original.** `delete_orig` setting removes the original archive after successful extraction. Default is `false` — the archive stays and you clean it up manually (or via the Starr app). Set to `true` carefully; confirm extraction works first.
- **`delete_delay`.** After Starr app marks the import complete, Unpackerr waits `delete_delay` (default 5min) before deleting extracted files. This prevents deleting files while import is still in progress.
- **Watch folder mode runs independently.** In watch-folder mode, Unpackerr extracts everything it finds without consulting any Starr app. Great for non-Starr workflows (Nextcloud auto-unzip, download folder maintenance) but won't know what Radarr has imported — may re-extract on restart.
- **Encrypted archives need passwords in config.** Provide `rar_password` or `zip_password` in the relevant section. There's no per-file password support — one password per folder/app section.
- **Multiple Starr instances.** Array indexing in env vars (`UN_SONARR_0_`, `UN_SONARR_1_`, etc.) supports multiple Sonarr/Radarr instances. Useful for 4K + 1080p split setups.
- **Logs level.** Default log level shows normal operations. Raise to `debug` temporarily if extractions aren't triggering — often a path mapping issue.

## Project health

Active Go development, Docker Hub + GHCR, deb/rpm packages, Unraid CA, Discord (Go Lift), docs site. Maintained by Go Lift (also authors of Notifiarr). MIT license.

## Download-extraction-family comparison

- **Unpackerr** — Go, daemon, Starr-app API integration, watch folder, all archive formats
- **Manual extraction** — one-off; doesn't scale
- **qBittorrent `Run external program`** — one-shot scripts per download; brittle
- **Sonarr/Radarr built-in extraction** — available since some versions; less configurable

**Choose Unpackerr if:** you use Sonarr/Radarr/Lidarr/Readarr and rar archives are getting stuck in your import queue.

## Links

- Repo: <https://github.com/Unpackerr/unpackerr>
- Docs: <https://unpackerr.zip>
- Discord: <https://golift.io/discord>
- Docker Hub: `golift/unpackerr`
