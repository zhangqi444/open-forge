---
name: qbittorrent-project
description: qBittorrent recipe for open-forge. GPL-2.0 BitTorrent client (C++/Qt + libtorrent-rasterbar). For self-host, the relevant shape is the headless Web UI daemon (`qbittorrent-nox`), not the desktop GUI. Covers distro packages (apt/dnf/pacman), the upstream PPA for Ubuntu, Docker (LinuxServer.io `lscr.io/linuxserver/qbittorrent` — the de facto standard; upstream does not ship a first-party image), systemd unit for the nox daemon, and the canonical default-credentials footgun (`admin / adminadmin` — MUST change before exposing).
---

# qBittorrent

GPL-2.0 BitTorrent client. Upstream: <https://github.com/qbittorrent/qBittorrent>. Site: <https://www.qbittorrent.org>. Wiki: <https://wiki.qbittorrent.org>.

For self-host use, you want **`qbittorrent-nox`** — the headless daemon that exposes a Web UI. The GUI `qbittorrent` binary is a desktop app and is not the typical self-host target.

**The most common self-host pattern is actually the LinuxServer.io `lscr.io/linuxserver/qbittorrent` Docker image, NOT an upstream-first-party image.** Upstream does not publish an official Docker container — any Docker recipe below is community-maintained.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Distro package (`apt install qbittorrent-nox`) | <https://wiki.qbittorrent.org/Linux> | ✅ (distro) | Debian/Ubuntu/Fedora/Arch headless server. Version may lag. |
| Ubuntu PPA (`ppa:qbittorrent-team/qbittorrent-stable`) | <https://launchpad.net/~qbittorrent-team> | ✅ (upstream-maintained) | Latest stable on Ubuntu. |
| Docker — LinuxServer.io (`lscr.io/linuxserver/qbittorrent`) | <https://docs.linuxserver.io/images/docker-qbittorrent/> | ⚠️ Community-maintained (NOT upstream) | The de facto Docker image used in selfh.st / TRaSH-guides stacks. |
| Docker — hotio (`ghcr.io/hotio/qbittorrent`) | <https://hotio.dev/containers/qbittorrent/> | ⚠️ Community | Alternative to linuxserver's image with libtorrent-version tags. |
| Build from source | <https://github.com/qbittorrent/qBittorrent/blob/master/INSTALL> | ✅ | Custom libtorrent versions / bleeding-edge features. |
| Windows / macOS installers | GitHub releases | ✅ | Desktop GUI. Not a self-host target. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `apt/dnf/pacman` / `PPA` / `Docker (LinuxServer)` / `Docker (hotio)` / `source` | Drives section. |
| preflight | "Run behind a VPN?" | Boolean | **Strongly recommended for public trackers.** Drives whether to network-mount the container into a Gluetun / Wireguard sidecar. |
| network | "Host port for Web UI?" | Free-text, default `8080` (legacy default) or `8081` (linuxserver default) | Different images use different defaults. |
| network | "Torrent ports (TCP+UDP)?" | Free-text, default `6881` | Must be port-forwarded at the router (or use VPN port-forwarding). |
| storage | "Downloads path?" | Free-text, e.g. `/data/torrents` | Bind-mounted to `/downloads` in the container. |
| storage | "Config path?" | Free-text, default `/config` | Persists UI settings, session state, .torrent files. |
| auth | "New Web UI password? (replace default `admin/adminadmin`)" | Free-text (sensitive) | MANDATORY change before public exposure. |
| PUID/PGID | "Host user UID/GID to run as?" | `id -u` / `id -g` output | Matches file ownership to the host user that accesses downloads. |

## Install — apt (Debian/Ubuntu)

Stable in distro repos (may be several minor versions old):

```bash
sudo apt-get update
sudo apt-get install -y qbittorrent-nox
```

Latest stable via PPA (Ubuntu only):

```bash
sudo add-apt-repository -y ppa:qbittorrent-team/qbittorrent-stable
sudo apt-get update
sudo apt-get install -y qbittorrent-nox
```

### Systemd unit

```bash
sudo useradd --system --home /var/lib/qbittorrent --create-home --shell /usr/sbin/nologin qbittorrent
sudo mkdir -p /var/lib/qbittorrent/downloads /var/lib/qbittorrent/config
sudo chown -R qbittorrent:qbittorrent /var/lib/qbittorrent

sudo tee /etc/systemd/system/qbittorrent-nox.service > /dev/null <<'EOF'
[Unit]
Description=qBittorrent-nox service
Documentation=man:qbittorrent-nox(1)
Wants=network-online.target
After=network-online.target nss-lookup.target

[Service]
Type=exec
User=qbittorrent
Group=qbittorrent
UMask=0002
ExecStart=/usr/bin/qbittorrent-nox --webui-port=8080
Restart=on-failure
RestartSec=5s
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now qbittorrent-nox
sudo journalctl -u qbittorrent-nox -f
```

On first boot, `qbittorrent-nox` prints a one-time generated default password to stdout/journal (recent versions; older versions use `admin/adminadmin`). Either way, **log in and set a real password immediately**.

## Install — Docker (LinuxServer.io)

The de facto Docker image:

```yaml
# compose.yaml
services:
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    restart: unless-stopped
    environment:
      - PUID=1000       # id -u on host
      - PGID=1000       # id -g on host
      - TZ=Etc/UTC
      - WEBUI_PORT=8081 # internal port; MUST match the host port mapping
      - TORRENTING_PORT=6881
    ports:
      - "8081:8081"
      - "6881:6881"
      - "6881:6881/udp"
    volumes:
      - ./config:/config
      - /mnt/downloads:/downloads
```

```bash
docker compose up -d
docker compose logs qbittorrent | grep -iE 'password|temporary'
# Note the temporary password from logs → log in → change it immediately.
```

### VPN sidecar pattern (Gluetun)

Public-tracker qBittorrent without a VPN exposes your IP on torrent swarms. Typical setup routes qBittorrent through a Gluetun container:

```yaml
services:
  gluetun:
    image: qmcgaw/gluetun:latest
    cap_add:
      - NET_ADMIN
    environment:
      - VPN_SERVICE_PROVIDER=mullvad   # or other
      - VPN_TYPE=wireguard
      - WIREGUARD_PRIVATE_KEY=<your-key>
      - WIREGUARD_ADDRESSES=10.x.x.x/32
    ports:
      - "8081:8081"    # qBittorrent UI (published by gluetun now)
      - "6881:6881"
      - "6881:6881/udp"
    restart: unless-stopped

  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    network_mode: "service:gluetun"   # All network goes through Gluetun
    depends_on:
      - gluetun
    environment:
      - PUID=1000
      - PGID=1000
      - WEBUI_PORT=8081
    volumes:
      - ./config:/config
      - /mnt/downloads:/downloads
    restart: unless-stopped
```

Verify the VPN is working:

```bash
docker exec gluetun wget -qO- https://ifconfig.io
# → Should return the VPN provider's exit IP, NOT your home IP.
```

## Reverse proxy (Caddy example)

```caddy
qbt.example.com {
    basicauth {
        reverse_proxy_fallback_user $2a$14$...hashed...
    }
    reverse_proxy qbittorrent:8081
}
```

qBittorrent has **built-in basic auth** in its Web UI, but many users add an extra reverse-proxy layer to keep it off the public internet. If you do, set `Host header validation` to off in qBittorrent **Settings → Web UI** or requests break.

## Configuration

Web UI → **Settings** covers everything. Key things to set on first login:

- **Web UI → Authentication:** change from `admin/adminadmin` (or the temp password) immediately. Enable "Bypass authentication for clients in whitelisted IP subnets" only if you trust your LAN.
- **Web UI → Use HTTPS:** recommended if exposing outside LAN.
- **Downloads → Default Save Path:** point at your mounted volume (`/downloads`).
- **BitTorrent → Enable DHT / PeX / LSD:** on for public trackers; off for private trackers (most private trackers ban DHT).
- **Advanced → Network interface:** set to `tun0` or whatever the VPN interface is named if you're not using Gluetun's network_mode pattern.
- **Connection → Peer connection protocol:** TCP+uTP by default; some networks prefer uTP-only.

## Data layout

### Native install

| Path | Content |
|---|---|
| `~/.config/qBittorrent/` | UI config (`qBittorrent.conf`). |
| `~/.local/share/qBittorrent/` | Session state: `.torrent` files, DHT state, resume data. |
| Downloads path | User data (per the "Default Save Path" setting). |

### Docker (LinuxServer)

| Path | Content |
|---|---|
| `/config/qBittorrent/` | Config + session (mirrors native layout inside the mounted config dir). |
| `/downloads/` | Downloads. |

**Back up `/config` regularly** — losing the session state means qBittorrent forgets everything in progress and has to re-verify every torrent on import.

## Upgrade procedure

### APT / PPA

```bash
sudo apt-get update && sudo apt-get upgrade qbittorrent-nox
sudo systemctl restart qbittorrent-nox
```

### Docker

```bash
docker compose pull
docker compose up -d
```

**Back up `/config` before major-version upgrades.** libtorrent-rasterbar version bumps (e.g. lt1.2 → lt2.0) change session-state format; downgrading after a failed upgrade may require the backup.

## Gotchas

- **Default credentials `admin/adminadmin`.** Legacy builds; recent versions generate a random temp password on first boot. Either way, **change it before exposing the UI**. This is the #1 public-exposure vuln for qBittorrent — scanners actively probe for the default creds.
- **No upstream Docker image.** Every "qBittorrent Docker" image is community-maintained (LinuxServer, hotio, johngong, etc.). Pick one and stick with it — don't switch between them and expect the config volume to be portable.
- **WEBUI_PORT env MUST match the published host port.** On LinuxServer.io's image, if you set `WEBUI_PORT=8080` but publish `8081:8081`, the UI will 404. Keep them identical.
- **Host-header validation blocks reverse-proxy requests by default.** Either disable it (Settings → Web UI → "Host header validation") or list your proxy hostname in the whitelist.
- **Torrent ports must be reachable from the internet for seeding.** Otherwise you're leech-only. Either port-forward at the router, or use a VPN with port-forwarding (Mullvad dropped this in 2023; ProtonVPN / AirVPN still support it).
- **Public trackers without VPN → DMCA risk.** If you're on public trackers (ThePirateBay, RARBG mirrors, etc.), your residential IP is visible to copyright enforcement firms. Either stick to private trackers or use a VPN.
- **libtorrent 2.x uses significantly more RAM than 1.2.x for the same torrent count.** If a Raspberry Pi suddenly OOMs after an upgrade, pin an lt1.2 Docker tag (hotio publishes both).
- **PUID/PGID mismatch = permission errors.** Files saved by the container owned by root won't be writable by your host user. Set `PUID`/`PGID` to your host `id -u`/`id -g`.
- **SavePath inside container ≠ host path.** The UI's "Default Save Path" should reference the container-internal path (e.g. `/downloads`), NOT the host path (e.g. `/mnt/downloads`). Beginners frequently mis-configure this and wonder why moves fail.
- **Private trackers hate announces from VPN IPs flagged as datacenter.** If you're on private trackers AND behind a VPN, check the tracker's policy — some allow it, some ban on first offense. Residential-VPN routing can work around this.
- **Search plugins are a foot-gun.** The built-in search plugin framework can execute arbitrary Python — only install plugins from trusted sources (the qBittorrent-official plugin repo).
- **GPL-2.0, but with OpenSSL exception.** Upstream COPYING includes an OpenSSL linking exception for Windows builds; most distros ignore this (they use GnuTLS or bundle their own OpenSSL).

## Links

- Upstream repo: <https://github.com/qbittorrent/qBittorrent>
- Wiki (canonical docs): <https://wiki.qbittorrent.org>
- Linux install guide: <https://wiki.qbittorrent.org/Linux>
- Web UI guide: <https://github.com/qbittorrent/qBittorrent/wiki/WebUI>
- LinuxServer.io image docs: <https://docs.linuxserver.io/images/docker-qbittorrent/>
- hotio image docs: <https://hotio.dev/containers/qbittorrent/>
- Ubuntu PPA: <https://launchpad.net/~qbittorrent-team>
- Forum: <https://forum.qbittorrent.org>
- Releases: <https://github.com/qbittorrent/qBittorrent/releases>
