---
name: NzbDav
description: "Self-hosted WebDAV server that mounts NZB files as a virtual file system for streaming Usenet content without downloading. Docker. Node.js. nzbdav-dev/nzbdav. SABnzbd-compatible API, Sonarr/Radarr integration, RAR/7z archive streaming, seek support, healthchecks, Stremio/AIOStreams support. Proprietary license."
---

# NzbDav

**Stream Usenet content via WebDAV — no storage required.** NzbDav acts as a WebDAV server that mounts NZB documents as a virtual file system. Mount it in Plex or Jellyfin and stream directly from your Usenet provider at full speed, with no disk space used. Supports RAR/7z archives (including password-protected), full seeking, automatic healthchecks and repairs. SABnzbd-compatible API means Sonarr and Radarr can use it as a download client.

Built + maintained by **nzbdav-dev**. Proprietary license — check repo for terms.

- Upstream repo: <https://github.com/nzbdav-dev/nzbdav>
- Docker Hub: `nzbdav/nzbdav`
- Comprehensive setup guide: <https://github.com/nzbdav-dev/nzbdav/blob/main/docs/setup-guide.md>

> **⚠️ Security notice:** Versions 0.2.46–0.6.1 had an auth-bypass vulnerability (reported 2026-03-17, patched 2026-03-18). Pull the latest image to ensure you're on a patched version. Patched versions show a `+260317` suffix on the version string in the UI.

## Architecture in one minute

- **Node.js** single container
- Port **3000**
- Config stored at `/config`
- Speaks directly to your Usenet provider (NNTP)
- SABnzbd-compatible API on same port
- Optional **Rclone** sidecar to mount the WebDAV share into media servers
- Resource: **low-medium** — Node.js; RAM scales with concurrent streams

## Compatible install methods

| Infra      | Runtime          | Notes                                              |
| ---------- | ---------------- | -------------------------------------------------- |
| **Docker** | `nzbdav/nzbdav`  | **Primary** — single container; multi-arch         |

## Install via Docker

```yaml
services:
  nzbdav:
    image: nzbdav/nzbdav:latest
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - PUID=1000
      - PGID=1000
    volumes:
      - ./nzbdav-config:/config
```

```bash
docker compose up -d
```

Visit `http://localhost:3000` → **Settings** → configure Usenet connection + WebDAV credentials.

## Features overview

| Feature | Details |
|---------|---------|
| WebDAV server | Serve virtual file system over HTTP; mount in media servers |
| Virtual filesystem | NZB files appear as real files — no disk space used |
| Full streaming | Watch videos; jump to any point without waiting for download |
| RAR/7z streaming | Stream archived content without extracting |
| Password-protected archives | Stream content in password-protected RAR archives |
| SABnzbd-compatible API | Sonarr and Radarr can add NzbDav as a download client |
| Sonarr/Radarr integration | Automatic queue management; repairs via arr apps |
| Healthchecks | Detect content removed from Usenet provider |
| Automatic repairs | Replace missing articles automatically |
| WebDAV auth | Username/password protection for the WebDAV share |
| Stremio support | Stream Usenet content via Stremio + AIOStreams addon |
| Rclone mount | Use Rclone to mount WebDAV into Plex/Jellyfin |
| Performance tuning | Configure WebDAV connection limits for benchmarked speeds |

## First boot

1. Start NzbDav → navigate to `http://localhost:3000`.
2. Go to **Settings → Usenet** → enter your Usenet provider hostname, port, credentials, and connection count.
3. Go to **Settings → WebDAV** → set a username and password for the WebDAV share.
4. Upload an NZB file → it appears as a virtual file in the file browser.
5. Mount the WebDAV share in Plex/Jellyfin via Rclone sidecar (see setup guide).
6. Configure Sonarr/Radarr to use NzbDav as a SABnzbd download client (point to `http://nzbdav:3000`).

## Sonarr/Radarr setup (SABnzbd-compatible API)

In Sonarr/Radarr:
- **Download client type**: SABnzbd
- **Host**: NzbDav host
- **Port**: 3000
- **API key**: from NzbDav settings

Sonarr/Radarr sends NZBs to NzbDav; NzbDav streams them without downloading. The arr apps track queue/history via the SABnzbd-compatible API.

## Rclone sidecar for Plex/Jellyfin

See the [comprehensive guide](https://github.com/nzbdav-dev/nzbdav/blob/main/docs/setup-guide.md) for a Docker Compose example using Rclone to mount the NzbDav WebDAV share into Plex/Jellyfin as a regular directory.

## Gotchas

- **Proprietary license.** NzbDav is not open source — check the repo for usage terms before deploying. The source code may not be available or freely redistributable.
- **Requires a Usenet provider with NZB retention.** NzbDav streams from your Usenet provider. You need a Usenet provider (e.g. Newshosting, UsenetExpress, Frugal Usenet) with sufficient retention and a fast connection. Content must still be on the server — if articles are missing, healthcheck/repair kicks in but can't restore content not on any provider.
- **Not a downloader.** Files are never written to disk (by design). If you need permanent local copies, use a traditional downloader (SABnzbd, NZBGet).
- **Patch the auth-bypass.** If upgrading from 0.2.46–0.6.1, repull the same tag — the images were patched in-place. Verify with the `+260317` version suffix in the UI.
- **Performance scales with connection count.** More NNTP connections = faster streaming. Match to your Usenet provider's allowed connection count.

## Backup

```sh
# Config contains API keys, settings, NZB queue
cp -r ./nzbdav-config nzbdav-config-$(date +%F)
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Node.js development, SABnzbd API, Sonarr/Radarr integration, RAR/7z streaming, healthchecks. Proprietary license.

## Usenet-streaming-family comparison

- **NzbDav** — Node.js, WebDAV virtual FS, no-storage streaming, SABnzbd API, Sonarr/Radarr, proprietary
- **SABnzbd** — Python, traditional downloader; files written to disk; open source
- **NZBGet** — C++, traditional downloader; lightweight; open source
- **Plex's Usenet support** — not a thing natively; NzbDav fills this gap

**Choose NzbDav if:** you want to stream Usenet content directly in Plex/Jellyfin/Stremio without consuming disk space, with full Sonarr/Radarr integration via the SABnzbd-compatible API.

## Links

- Repo: <https://github.com/nzbdav-dev/nzbdav>
- Setup guide: <https://github.com/nzbdav-dev/nzbdav/blob/main/docs/setup-guide.md>
