---
name: jellyfin-project
description: Jellyfin recipe for open-forge. GPL-2.0 volunteer-built free media solution — fork of Emby (MIT days), a self-hosted Plex/Emby alternative for streaming movies/TV/music/photos/books. .NET 9 server + web client. Covers upstream install paths (official apt/dnf repos, Docker `jellyfin/jellyfin`, Docker `linuxserver/jellyfin`, Windows installer, macOS DMG, portable tarball) and the operational essentials (hardware transcoding with VAAPI / NVENC / QSV, media library layout, client apps, reverse proxy with websocket, remote-access patterns for LAN vs VPN vs public).
---

# Jellyfin

GPL-2.0 free, volunteer-built, self-hosted media server. Fork of Emby (from when Emby was open-source). Streams movies, TV, music, photos, books, audiobooks, live-TV/DVR. Upstream: <https://github.com/jellyfin/jellyfin>. Website: <https://jellyfin.org/>. Docs: <https://jellyfin.org/docs/>.

Core architecture: .NET 9 server + web client (bundled) + ffmpeg (a Jellyfin fork at <https://github.com/jellyfin/jellyfin-ffmpeg>). Default HTTP port `:8096`. Supports hardware transcoding via VAAPI, QuickSync, NVENC, VideoToolbox, RKMPP.

## Compatible install methods

All listed at <https://jellyfin.org/docs/general/installation/>:

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| APT repo (Debian/Ubuntu) | <https://jellyfin.org/docs/general/installation/linux#repository-manual> | ✅ Recommended for bare-metal Linux | Production on a dedicated VM or home-server. Includes systemd unit, handles ffmpeg dependency. |
| DNF / YUM repo (RHEL/Fedora/Alma) | Same docs page | ✅ | RPM-based distros. |
| Docker (`jellyfin/jellyfin`) | <https://hub.docker.com/r/jellyfin/jellyfin> | ✅ Recommended for container hosts | Upstream-maintained official image. |
| Docker (`linuxserver/jellyfin`) | <https://docs.linuxserver.io/images/docker-jellyfin/> | ⚠️ Community-maintained | LinuxServer.io's variant with s6-overlay, easier PUID/PGID handling. Very popular but not upstream. |
| Portable tarball | <https://jellyfin.org/downloads/server> | ✅ | Air-gapped / unusual distros. |
| Windows installer `.exe` | Same downloads page | ✅ | Windows hosts. |
| macOS `.dmg` | Same | ✅ | macOS hosts. |
| Build from source | <https://jellyfin.org/docs/general/installation/source> | ✅ | Dev / custom. Needs .NET 9 SDK + jellyfin-ffmpeg. |
| Unraid / TrueNAS / Synology plugins | Platform app stores | ⚠️ Third-party packaging | NAS users; tracks upstream Docker image. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion` | Drives section. |
| preflight | "Host has a GPU?" | `AskUserQuestion`: `Intel iGPU (QSV/VAAPI)` / `NVIDIA (NVENC)` / `AMD (VAAPI/AMF)` / `Apple (VideoToolbox)` / `None (CPU only)` | Drives hardware-transcoding setup. |
| media | "Media library root path(s)?" | Free-text (repeatable) | Each library = one or more directories. Common layout: `/srv/media/movies`, `/srv/media/tv`, `/srv/media/music`. |
| dns | "Public domain?" | Free-text | E.g. `jellyfin.example.com`. Required for remote access with TLS. |
| remote | "Remote access pattern?" | `AskUserQuestion`: `LAN only` / `VPN (Tailscale/WireGuard)` / `Public with reverse proxy + TLS` | Each has different gotchas (§Remote access). |
| tls | "Reverse proxy? (Caddy / nginx / Traefik)" | `AskUserQuestion` | For public access. LAN-only can skip TLS. |
| admin | "Initial admin user + password?" | Free-text (sensitive) | Set via first-run setup wizard (web). First user is auto-admin. |

## Install — APT (Debian/Ubuntu, upstream-recommended)

Upstream ships signed APT repos for `bullseye`, `bookworm`, `focal`, `jammy`, `noble`:

```bash
# 1. Add upstream's repo
sudo apt-get install -y curl gnupg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.jellyfin.org/jellyfin_team.gpg.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/jellyfin.gpg

# Adjust for your distro/release:
. /etc/os-release
echo "Types: deb
URIs: https://repo.jellyfin.org/${ID}
Suites: ${VERSION_CODENAME}
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/jellyfin.gpg" | sudo tee /etc/apt/sources.list.d/jellyfin.sources

# 2. Install
sudo apt-get update
sudo apt-get install -y jellyfin

# 3. Service is enabled + started automatically
sudo systemctl status jellyfin
# UI at http://<host>:8096 — first-run wizard creates admin
```

## Install — Docker (official image)

```yaml
# compose.yaml
services:
  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    user: 1000:1000          # match the owner of your media dir
    network_mode: host       # see §Ports below — simplest for DLNA/broadcast discovery
    volumes:
      - ./config:/config
      - ./cache:/cache
      - /srv/media:/media:ro
      # Optional — hardware transcoding
      - /dev/dri:/dev/dri    # Intel/AMD VAAPI
    restart: unless-stopped
    environment:
      - JELLYFIN_PublishedServerUrl=https://jellyfin.example.com
    # If you don't want host networking:
    # ports:
    #   - "8096:8096"
    #   - "8920:8920"        # HTTPS (if Jellyfin terminates TLS itself)
    #   - "1900:1900/udp"    # DLNA SSDP
    #   - "7359:7359/udp"    # Jellyfin client discovery
    # NVIDIA transcoding:
    # deploy:
    #   resources:
    #     reservations:
    #       devices:
    #         - driver: nvidia
    #           count: all
    #           capabilities: [gpu]
```

### LinuxServer.io variant (popular community image)

```yaml
services:
  jellyfin:
    image: lscr.io/linuxserver/jellyfin:latest
    container_name: jellyfin
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
      - JELLYFIN_PublishedServerUrl=https://jellyfin.example.com
    volumes:
      - ./config:/config
      - /srv/media:/data/media:ro
    devices:
      - /dev/dri:/dev/dri     # Intel VAAPI
    ports:
      - "8096:8096"
      - "8920:8920"
      - "7359:7359/udp"
      - "1900:1900/udp"
    restart: unless-stopped
```

LinuxServer.io's variant handles non-root UID/GID better and uses s6-overlay for supervision. Functionally equivalent to the upstream image for most users.

## First-run wizard

1. Visit `http://<host>:8096/`.
2. Pick UI language.
3. Create admin user + password.
4. Add libraries: pick a content type (Movies / Shows / Music / Photos / Books / Mixed), set display name, point at library path(s) on disk, choose metadata language.
5. Preferred metadata provider: TheMovieDb (default) for movies/TV.
6. Remote access: enable if you'll hit it over the internet.
7. Finish — dashboard + initial library scan kicks off.

## Hardware transcoding

Upstream docs: <https://jellyfin.org/docs/general/administration/hardware-acceleration/>.

### Intel QSV / VAAPI

```bash
# Host: give the Jellyfin user access to /dev/dri
sudo usermod -aG render,video jellyfin
```

Or in Docker, mount `/dev/dri:/dev/dri` and ensure the container user has access.

In Jellyfin admin UI: **Dashboard → Playback → Hardware acceleration** → choose `QSV` or `VAAPI` → enable `Enable hardware decoding for <codecs>`.

### NVIDIA NVENC

- Install NVIDIA Container Toolkit on host (<https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html>).
- Add `deploy.resources.reservations.devices` block to compose (see example above).
- Admin UI: Hardware acceleration → `Nvidia NVENC`.

### AMD AMF / VAAPI

Linux: VAAPI works. Windows: AMF works natively. Admin UI: `VAAPI` or `AMF`.

### VideoToolbox (macOS)

Automatic if running on macOS hardware.

### Verification

After enabling HW transcoding, play a video that requires transcoding (e.g. HEVC to a client that only supports H.264). In Dashboard → **Activity** → check the "Play Method" — should say `Transcoding (HW)`. Check `ffmpeg-transcode-*.txt` in the log dir for the actual ffmpeg command.

## Reverse proxy (Caddy example)

```caddy
jellyfin.example.com {
    reverse_proxy 127.0.0.1:8096 {
        # Jellyfin uses WebSockets for realtime UI updates + sync-play
        # Caddy's reverse_proxy handles WS automatically.
    }
    # Optional — large library request body (artwork uploads)
    request_body {
        max_size 100MB
    }
}
```

Nginx needs explicit `proxy_set_header Upgrade $http_upgrade;` + `Connection "upgrade";` for websockets. Jellyfin's docs site has a verified nginx config at <https://jellyfin.org/docs/general/networking/nginx>.

### `JELLYFIN_PublishedServerUrl`

Set this env var (or Dashboard → Networking → Published Server URL) to the canonical public URL. Client apps use it for connection setup; without it, the discover-and-connect flow returns internal Docker IPs.

## Remote access patterns

### LAN-only (simplest, safest)

No reverse proxy, no TLS. Clients on the same LAN hit `http://<host>:8096` directly. Best for pure home use.

### VPN (Tailscale / WireGuard)

Install Tailscale on the server + each client device. Jellyfin is reachable at the server's Tailscale IP from anywhere. No public exposure, no reverse proxy, no TLS hassle. This is the upstream-recommended pattern for non-power-users who want "Jellyfin away from home."

### Public with reverse proxy + TLS

See §Reverse proxy above. **Enable rate limiting and auth protection at the proxy** — Jellyfin's own login has no built-in brute-force protection. Fail2ban on the Jellyfin auth log is a common add-on.

**Do NOT port-forward `:8096` directly to the internet without a proxy.** Clients like Android's official Jellyfin app work fine through a reverse proxy and require no special handling.

## Media library layout

Upstream's strict-ish conventions (<https://jellyfin.org/docs/general/server/media/>):

```
/srv/media/
├── movies/
│   ├── The Matrix (1999)/
│   │   ├── The Matrix (1999).mkv
│   │   └── poster.jpg        # optional — pulled from TMDb otherwise
│   └── Inception (2010)/
│       └── Inception (2010).mkv
├── shows/
│   ├── Breaking Bad/
│   │   ├── Season 01/
│   │   │   ├── Breaking Bad S01E01.mkv
│   │   │   └── Breaking Bad S01E02.mkv
│   │   └── Season 02/
│   └── Better Call Saul/
└── music/
    └── Miles Davis/
        └── Kind of Blue/
            ├── 01 - So What.flac
            └── 02 - Freddie Freeloader.flac
```

Deviating from this naming breaks metadata matching. Use tools like `filebot` or `tinyMediaManager` to rename before adding to Jellyfin.

## Data layout

| Path (native) | Path (Docker) | Content |
|---|---|---|
| `/var/lib/jellyfin/` | `/config/` | Main state: user DB, plugins, metadata cache, image cache. |
| `/etc/jellyfin/` | `/config/` (merged) | Config files (system.xml, logging.xml). |
| `/var/cache/jellyfin/` | `/cache/` | Transcoding cache — large, ephemeral. Put on fast disk. |
| `/var/log/jellyfin/` | `/config/log/` | Logs. |

**Backup = stop Jellyfin + `tar` the config dir.** The library DB (SQLite) in `/config/data/` is the main thing to protect. Media files themselves are usually too large to back up — treat them as replaceable.

## Upgrade procedure

### APT

```bash
sudo apt-get update && sudo apt-get upgrade jellyfin jellyfin-server jellyfin-web jellyfin-ffmpeg7
sudo systemctl restart jellyfin
sudo journalctl -u jellyfin -n 200
```

### Docker

```bash
docker compose pull jellyfin
docker compose up -d jellyfin
docker compose logs -f jellyfin
```

**Major version bumps** (e.g. 10.8 → 10.9) sometimes require re-scanning libraries or plugin re-installation. Read the release notes at <https://github.com/jellyfin/jellyfin/releases>. Always back up `/config/` first.

## Gotchas

- **The bundled ffmpeg is a Jellyfin fork** (`jellyfin-ffmpeg`). Don't replace it with stock ffmpeg — Jellyfin's patches enable hardware transcoding features stock ffmpeg doesn't have.
- **Transcode cache can fill disks.** Heavy transcoding loads GB/hour into `/var/cache/jellyfin/`. Put it on a dedicated disk or set retention limits in admin UI → Playback → Transcoding.
- **DLNA / client discovery needs host networking or broadcast ports.** Ports `1900/udp` (SSDP) and `7359/udp` (Jellyfin discovery) must reach the LAN. Docker bridge networking breaks this; use `network_mode: host` or expose UDP ports explicitly.
- **`PublishedServerUrl` matters for clients.** Without it, iOS/Android apps get the internal Docker IP and fail to connect. Set it to your public/Tailscale URL.
- **No built-in rate limiting on login.** Expose publicly without a protective reverse proxy at your peril. Fail2ban jail on `/var/log/jellyfin/log_*.log` + `nginx access_log` is the common fix.
- **First user is admin.** Until you complete the wizard, anyone hitting `:8096` can claim admin. Firewall off from the internet until setup is done.
- **HEVC/AV1 to older clients = heavy transcode.** HW acceleration matters a lot for a family/multi-user setup. Budget for an iGPU (Intel N100 mini-PC is the sweet spot).
- **Subtitle burn-in is CPU-only unless using tonemap.** Some subtitle formats (PGS, SSA) require burn-in, which typically falls back to CPU even with HW transcoding enabled.
- **LAN-only Jellyfin over HTTP is fine.** The noise about "HTTP is insecure" mostly doesn't apply on a home LAN. Reverse proxy + TLS is only strictly required for public / VPN-routable deployments.
- **Emby compatibility is NOT guaranteed.** Jellyfin forked from Emby years ago; while the web UI looks similar, config files and plugin ABIs diverged. Don't mix Emby plugins or configs.
- **Live TV / DVR needs a tuner.** HDHomeRun (network tuner) is the best-supported. USB tuners via TVHeadend-as-middleware work but are fiddly.
- **Repo signing changed in late 2024** — if you pinned an old GPG key, `apt update` will fail until you replace it with the current `jellyfin_team.gpg.key`.
- **Plugin repositories are community-run.** The main catalog is curated by Jellyfin, but plugins are still user-contributed. Treat new plugins like any third-party software.
- **macOS client app is a WebView, not native.** Performance reflects WKWebView + OS ffmpeg — for best macOS experience, use Infuse (paid, native) or the native iOS app via Silicon.

## Links

- Upstream repo: <https://github.com/jellyfin/jellyfin>
- Docs: <https://jellyfin.org/docs/>
- Downloads: <https://jellyfin.org/downloads/>
- Installation index: <https://jellyfin.org/docs/general/installation/>
- Hardware acceleration: <https://jellyfin.org/docs/general/administration/hardware-acceleration/>
- Media library conventions: <https://jellyfin.org/docs/general/server/media/>
- Networking + reverse proxy: <https://jellyfin.org/docs/general/networking/>
- Client apps: <https://jellyfin.org/clients>
- Docker image: <https://hub.docker.com/r/jellyfin/jellyfin>
- LinuxServer.io variant: <https://docs.linuxserver.io/images/docker-jellyfin/>
- Releases: <https://github.com/jellyfin/jellyfin/releases>
- Forum: <https://forum.jellyfin.org/>
