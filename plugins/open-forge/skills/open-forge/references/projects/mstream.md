---
name: mstream
description: mStream recipe for open-forge. Covers self-hosting the personal music streaming server that uses the folder hierarchy directly (no scan-to-play required). Upstream: https://github.com/IrosTheBeggar/mStream
---

# mStream

Personal music streaming server where the file browser IS the music browser — files stream directly from disk via `express.static`, no database scan required to play. Supports Subsonic API, DLNA/UPnP, on-the-fly transcoding, YouTube download, file upload, and multi-user accounts. Also ships as desktop apps (server tray app + player). Upstream: <https://github.com/IrosTheBeggar/mStream>.

**License:** GPL-3.0

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (LinuxServer.io image) | https://github.com/linuxserver/docker-mstream | Community (LSIO) | Recommended for headless/server deployments |
| npm from source | https://github.com/IrosTheBeggar/mStream/blob/master/docs/install.md | ✅ | Manual installs; requires Node.js v22.5+ |
| Desktop installer (Win/macOS/Linux) | https://mstream.io/server | ✅ | Personal machines; includes tray icon + auto-update |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| app | "Path to your music library on the host?" | Absolute path | All |
| app | "Port to expose mStream on?" | Number (default: 3000) | Docker |
| app | "PUID/PGID for file permissions?" | UID:GID (default: 1000:1000) | Docker (LSIO) |
| app | "Timezone?" | TZ string (e.g. America/New_York) | Docker |

## Docker Compose (LinuxServer.io)

```yaml
services:
  mstream:
    image: lscr.io/linuxserver/mstream:latest
    container_name: mstream
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - /path/to/mstream/data:/config
      - /path/to/music:/music
    ports:
      - 3000:3000
    restart: unless-stopped
```

## Software-layer concerns

### Config / data directories

| Path (container) | Purpose |
|---|---|
| `/config` | mStream config files, database (SQLite), and app state |
| `/music` | Read-only mount of your music library |

### Key settings (config file)

mStream stores its config in `/config/config.json` (LSIO image). Key settings:

- **Library paths** — configured on first run via the wizard or web UI
- **User accounts** — managed in the admin UI (`/admin`)
- **Public mode** — no accounts required; suitable for trusted local networks
- **Write-permission toggles** — `lockAdmin`, `noUpload`, `noMkdir`, `noFileModify`
- **Subsonic API** — enabled by default; configure users with Subsonic API access in the admin UI

### npm from source (quick start)

```bash
git clone https://github.com/IrosTheBeggar/mStream.git
cd mStream
npm run-script wizard    # interactive setup; requires Node.js v22.5+
```

## Upgrade procedure

```bash
# Docker
docker compose pull && docker compose up -d

# npm source
git pull && npm install
```

## Gotchas

- **Subsonic clients still need a scan.** The native mStream UI is "drop and play" — no scan needed. But third-party Subsonic clients (DSub, Symfonium, etc.) use the Subsonic protocol which requires an index scan for metadata-driven features.
- **LSIO image, not upstream.** There is no official Docker image from the upstream author. The LinuxServer.io image (`lscr.io/linuxserver/mstream`) is the community-recommended approach and is well-maintained.
- **Node.js v22.5+ required for source installs.** Check `node --version` before installing from source.
- **YouTube download requires yt-dlp.** The YouTube → library feature depends on `yt-dlp` being available in the PATH (pre-installed in the LSIO image).
- **ffmpeg for transcoding.** On-the-fly transcoding requires ffmpeg; pre-installed in the LSIO image.
- **No auth by default (public mode).** If exposing to the internet, configure user accounts in the admin UI and disable public mode.

## Upstream docs

- GitHub README: https://github.com/IrosTheBeggar/mStream
- Install guide: https://github.com/IrosTheBeggar/mStream/blob/master/docs/install.md
- LinuxServer.io Docker image: https://github.com/linuxserver/docker-mstream
- Demo: https://demo.mstream.io/
