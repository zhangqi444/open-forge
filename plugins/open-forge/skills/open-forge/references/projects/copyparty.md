---
name: copyparty-project
description: Copyparty recipe for open-forge. MIT-licensed "turn any device into a file server" — single-file Python app that does HTTP(S)/WebDAV/FTP(S)/SFTP/SMB/TFTP/zeroconf/mDNS + resumable uploads + deduplication + thumbnails + media indexing + audio transcoding + markdown wiki + share links. Runs as the legendary `copyparty-sfx.py` self-extractor, a pypi module, a zipapp, an OS package (Arch/Homebrew/NixOS), an .exe for Windows, or Docker (`copyparty/ac`). Covers the quickstart, systemd unit, Docker editions (`min`/`im`/`ac`/`iv`/`dj`), accounts-and-volumes config, and the "it's ALSO a BitTorrent client / FTP server / SMB share" feature sprawl.
---

# Copyparty

MIT-licensed file server that speaks practically every file-transfer protocol ever invented, from a single Python file. Upstream: <https://github.com/9001/copyparty>. Online docs: <https://copyparty.eu/>. CLI help: <https://copyparty.eu/cli/>.

Copyparty is the fever-dream maximalist of self-hosted file sharing:

- **HTTP / HTTPS** file browser + uploads (resumable, dedup-by-hash, chunked)
- **WebDAV** for mounting as a filesystem
- **FTP / FTPS / SFTP** servers
- **SMB** server (read-only)
- **TFTP** (for PXE-booting old hardware)
- **Zeroconf / mDNS / SSDP** so the server appears on your LAN automatically
- **Thumbnails** (images, audio waveforms, video keyframes)
- **Audio transcoding** (opus/aac on the fly for browser playback)
- **Full-text media indexing** (metadata + fulltext search)
- **Markdown wiki** + textfile viewer
- **RSS/OPDS** feeds of recent uploads
- **Share links** (pre-auth'd direct URLs)
- **User + volume permissions** (per-path rwmd permissions)

It is a single ~4 MB Python script. Runs on anything that has Python 3 — Windows, macOS, Linux, FreeBSD, Android (via Termux), iOS (via a-Shell), Synology DSM, Raspberry Pi.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| `copyparty-sfx.py` (self-extractor) | <https://github.com/9001/copyparty/releases/latest> | ✅ **Recommended** | One-file install. Unpacks embedded tar.gz into `$TEMP` on run. |
| PyPI (`pip install copyparty`) | <https://pypi.org/project/copyparty/> | ✅ | Installs into Python env. `python3 -m pip install --user -U copyparty`. |
| `copyparty.exe` | Releases page | ✅ | Windows single-binary; bundles Python + Pillow. |
| Docker (`copyparty/ac`, plus `min`/`im`/`iv`/`dj` editions) | <https://hub.docker.com/u/copyparty> | ✅ | Recommended for server deploys; has all optional deps baked in. |
| Arch AUR | `copyparty` package | ✅ Community but upstream-endorsed | Arch Linux. |
| Homebrew | Upstream Homebrew formula | ✅ | macOS. |
| NixOS module | Upstream NixOS module | ✅ | Reproducible NixOS config. |
| Termux (Android) | Upstream guide | ✅ | Turn your phone into a file server. |
| a-Shell (iOS) | Upstream guide | ✅ | Same for iPhone/iPad. |
| Bootable flashdrive / CD-ROM | <https://a.ocv.me/pub/stuff/edcd001/enterprise-edition/> | ✅ (cheeky) | Recovery scenarios. |
| `prisonparty` (chroot wrapper) | `bin/prisonparty.sh` | ✅ | Light sandbox without Docker. |
| `bubbleparty` (bubblewrap wrapper) | `bin/bubbleparty.sh` | ✅ | Stronger sandbox via bubblewrap. |
| `uv tool run copyparty` | `uv` | ✅ | Ephemeral run. |
| Zipapp (`copyparty.pyz`) | Releases page | ✅ | If the sfx scares you; slightly slower startup. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion` | Drives section. |
| preflight | "OS?" | Free-text (Linux / macOS / Windows / FreeBSD / Android / iOS / …) | Platform-specific deps differ. |
| deps | "Enable thumbnails + media indexing + audio transcoding?" | Boolean | Installs Pillow + ffmpeg. |
| shares | "What directories to share? (host path → URL mountpoint)" | Free-text per volume | Maps to `-v <host>:<mountpoint>:<perms>,<user>` CLI flags or `[<mountpoint>]` config sections. |
| users | "Accounts? (username + password + permissions per volume)" | Free-text | `-a user:pass` for users; `r/w/m/d/g/G/h/a` perms per volume. |
| service | "Run as systemd service?" | Boolean | Upstream ships a ready unit file at `contrib/systemd/copyparty.service`. |
| tls | "Reverse proxy or native HTTPS?" | `AskUserQuestion` | Copyparty can do HTTPS natively (self-signed or real cert) OR you reverse-proxy. |
| dns | "Public domain?" | Free-text | Only if exposing beyond LAN. |
| ports | "Enable which protocols?" | Multi-select: HTTP/HTTPS / FTP / FTPS / SFTP / SMB / TFTP / WebDAV / mDNS | Each enables specific listeners; see firewall example below. |

## Install — `copyparty-sfx.py` (upstream quickstart)

```bash
# 1. Download the sfx
wget -O /usr/local/bin/copyparty-sfx.py \
  https://github.com/9001/copyparty/releases/latest/download/copyparty-sfx.py
chmod +x /usr/local/bin/copyparty-sfx.py

# 2. (Recommended) optional deps for thumbnails + media features
# Debian/Ubuntu:
sudo apt install --no-install-recommends python3-pil ffmpeg
# Alpine:
# apk add py3-pillow ffmpeg
# Fedora:
# dnf install python3-pillow ffmpeg --allowerasing  (needs rpmfusion)
# macOS (Homebrew): brew install pillow ffmpeg

# 3. Quick ad-hoc run — shares the CURRENT directory, read+write for ANYONE:
copyparty-sfx.py
# → http://localhost:3923
# ⚠️ This is wide open. Close firewall or add -a/-v right away.

# 4. Typical ad-hoc with a user account + media indexing:
copyparty-sfx.py -a alice:correcthorse -v /mnt/music:/music:r:rw,alice -e2dsa -e2ts
#  -a alice:correcthorse           → create user "alice"
#  -v /mnt/music:/music:r:rw,alice → share /mnt/music as /music, world-readable, alice rw
#  -e2dsa                          → enable filesystem indexing
#  -e2ts                           → enable media tag indexing (needs ffprobe or mutagen)
```

## Install — systemd unit (production Linux)

Upstream ships the unit at `contrib/systemd/copyparty.service`:

```bash
# 1. Install binary + create user
sudo wget -O /usr/local/bin/copyparty-sfx.py \
  https://github.com/9001/copyparty/releases/latest/download/copyparty-sfx.py
sudo chmod +x /usr/local/bin/copyparty-sfx.py
sudo useradd -r -s /sbin/nologin -m -d /var/lib/copyparty copyparty

# 2. Config file
sudo wget -O /etc/copyparty.conf \
  https://raw.githubusercontent.com/9001/copyparty/hovudstraum/contrib/systemd/copyparty.conf
# Edit /etc/copyparty.conf — define accounts + volumes

# 3. Systemd unit
sudo wget -O /etc/systemd/system/copyparty.service \
  https://raw.githubusercontent.com/9001/copyparty/hovudstraum/contrib/systemd/copyparty.service

# 4. Firewall (example — opens every copyparty port; trim to what you use)
# firewall-cmd --permanent --add-port=3923/tcp
# firewall-cmd --reload

# 5. Start
sudo systemctl daemon-reload
sudo systemctl enable --now copyparty
sudo journalctl -fu copyparty
```

The upstream unit ships with sensible hardening: `MemoryMax=50%`, `ProtectKernelLogs`, `ProtectKernelModules`, `RestrictNamespaces`, etc. It also enables `CAP_NET_BIND_SERVICE` so copyparty can bind 80/443 if you uncomment the relevant line in `copyparty.conf`.

## Install — Docker

Upstream publishes 5 editions with increasing dependency bloat:

| Edition | Size | What it adds |
|---|---|---|
| [`copyparty/min`](https://hub.docker.com/r/copyparty/min) | 57 MiB | Just copyparty. |
| [`copyparty/im`](https://hub.docker.com/r/copyparty/im) | 70 MiB | + Pillow (image thumbnails) + mutagen (media tag parsing). |
| [`copyparty/ac`](https://hub.docker.com/r/copyparty/ac) ⭐ **recommended** | 163 MiB | + ffmpeg (audio/video thumbs + transcoding). |
| [`copyparty/iv`](https://hub.docker.com/r/copyparty/iv) | 211 MiB | + vips (faster heif/avif/jxl thumbs). |
| [`copyparty/dj`](https://hub.docker.com/r/copyparty/dj) | 309 MiB | + keyfinder + beatroot (BPM / musical key detection). |

Also available at `ghcr.io/9001/copyparty-<edition>` (GitHub Container Registry mirror).

### Quick run

```bash
docker run --rm -it -u 1000 -p 3923:3923 \
  -v /mnt/nas:/w \
  -v $PWD/cfgdir:/cfg \
  copyparty/ac
```

- `/w` = the default shared folder inside the container. Mount real dirs below `/w`.
- `/cfg` = an optional folder of `.conf` files copyparty auto-loads at startup.
- `-u 1000` = run as UID 1000 on the host. Remove for rootless Podman.
- Add `:z` to volume mounts on SELinux hosts (`-v /mnt/nas:/w:z`).

### Compose

```yaml
# compose.yaml
services:
  copyparty:
    image: copyparty/ac:latest
    container_name: copyparty
    restart: unless-stopped
    user: "1000:1000"
    ports:
      - "3923:3923"
    volumes:
      - /mnt/nas:/w
      - ./cfg:/cfg
    environment:
      # example: bump PUID/PGID via -u above rather than here
      TZ: Europe/London
```

Put a config file at `./cfg/copyparty.conf`:

```ini
# cfg/copyparty.conf
[global]
  p: 3923
  e2dsa         # filesystem indexing
  e2ts          # media tag indexing
  name: my-copyparty

[accounts]
  alice: correcthorse
  bob: batterystaple

[/]
  /w                   # share the /w volume at URL /
  accs:
    r: *                # world-readable
    rw: alice, bob      # alice and bob can write

[/private]
  /w/private           # subfolder
  accs:
    rw: alice           # only alice
```

## Accounts + volumes syntax

Copyparty's permission string is terse. Per-volume perms:

| Letter | Permission |
|---|---|
| `r` | read |
| `w` | write (upload) |
| `m` | move |
| `d` | delete |
| `g` | get (API / download as logged-out) |
| `G` | get + list |
| `h` | hide from directory listing |
| `a` | all (admin) |

CLI form: `-v <realpath>:<urlpath>:<perms>,<user>[:<perms>,<user>]`. Example:

```bash
copyparty-sfx.py \
  -a alice:correcthorse \
  -a bob:batterystaple \
  -v /srv/shared:/:r:rw,alice:rw,bob \
  -v /srv/alice:/home/alice:rw,alice
```

Config-file form in `/etc/copyparty.conf` or `/cfg/*.conf` is easier to audit for anything non-trivial.

## HTTPS

Copyparty can do HTTPS natively:

```bash
# Self-signed on the fly
copyparty-sfx.py --http-only=false --ssl
# Supply a real Let's Encrypt cert
copyparty-sfx.py --ssl-crt /etc/letsencrypt/live/example.com/fullchain.pem \
                 --ssl-key /etc/letsencrypt/live/example.com/privkey.pem
```

Or run behind a reverse proxy (simpler). Upstream ships `contrib/nginx/copyparty.conf` as a reference:

```caddy
files.example.com {
    reverse_proxy 127.0.0.1:3923
    request_body {
        max_size 10GB   # bump for large uploads
    }
}
```

## Making it public (LAN → internet)

Copyparty's own docs suggest **Cloudflare Tunnel** (cloudflared) as the path-of-least-resistance exposure:

```bash
# Install cloudflared, then:
cloudflared tunnel --url http://127.0.0.1:3923
# → a trycloudflare.com URL is printed; share it
```

Permanent tunnel (with your own domain) is documented in the README under "permanent cloudflare tunnel." When behind a tunnel, run copyparty with `--xff-hdr cf-connecting-ip` so it sees real client IPs for rate-limiting / logging.

## Data layout

Copyparty doesn't have a dedicated "data dir" — its state is the filesystems you pointed it at, plus:

| Path | Content |
|---|---|
| `<share>/.hist/` | Index database (sqlite), thumbnails cache, upload history, tags DB. Regenerable from the underlying files. |
| `<share>/.up2k.db` | Upload-resumption state (chunk hashes). |
| `/cfg/*.conf` (Docker) or `/etc/copyparty.conf` | Config. |
| `$LOGS_DIRECTORY` (systemd) = `/var/log/copyparty` | Rotated daily. |

No application-level backup needed — just back up the source filesystems. Copyparty rebuilds indexes/thumbnails on demand if `.hist/` is deleted.

## Upgrade procedure

### sfx / pypi

```bash
# sfx
sudo wget -O /usr/local/bin/copyparty-sfx.py \
  https://github.com/9001/copyparty/releases/latest/download/copyparty-sfx.py
sudo chmod +x /usr/local/bin/copyparty-sfx.py
sudo systemctl restart copyparty

# pypi
python3 -m pip install --user -U copyparty
```

### Docker

```bash
docker compose pull
docker compose up -d
```

Config file format is stable across versions. Release notes: <https://github.com/9001/copyparty/releases>.

## Gotchas

- **Default = read+write for everyone.** Running `copyparty-sfx.py` with no arguments shares the current directory wide open on port 3923. Always pass `-a` + `-v` (or a config file) before exposing beyond localhost.
- **sfx extracts into `$TEMP`.** On systems with `noexec /tmp`, the sfx fails. Either fix `/tmp` or use the zipapp (`.pyz`) instead.
- **Very easy to accidentally upload outside the intended volume.** The `-v` flag's `<urlpath>` is literal — `/` means "root of the copyparty URL tree." If you have overlapping volumes you may confuse yourself; use distinct URL prefixes.
- **File-indexing DB (`.hist/`) is per-volume and non-portable.** If you move a share to a different filesystem, let copyparty re-index.
- **SMB support is read-only** and deliberately minimal. Don't use copyparty as a Samba drop-in for Windows clients — use Samba.
- **FTP passive-mode ports.** If you enable FTP, you need to open the 12000-12099 passive-range (configurable) in the firewall — not just port 21/3921.
- **`e2ts` media tag indexing needs ffprobe or mutagen.** Without either, media tags are empty and thumbnail generation is limited. The `ac` Docker edition includes both; the `min` image doesn't.
- **Thumbnails for HEIC / AVIF / JXL need vips.** Pillow alone can't handle these modern formats well. Use `iv` edition or install `libvips` on bare metal.
- **Running behind Cloudflare / reverse proxy = spoofed IPs without `--xff-hdr`.** Copyparty's IP-based rate limits + logging are useless if it sees the proxy's IP on every request. Set `--xff-hdr x-forwarded-for` (or `cf-connecting-ip` for Cloudflare).
- **`-u 1000` in Docker maps UIDs.** Host files created by copyparty will be owned by UID 1000. If your host user is UID 1001, chown after or `-u 1001`.
- **The author (9001 / "ed") is a one-person show with strong opinions.** Copyparty won't look like any other server. Quirky but battle-tested — it ships with extensive self-tests + fuzz coverage.
- **The docs are ONE huge README.** 3000+ lines. Use the TOC at the top; search is your friend. <https://copyparty.eu/> serves a rendered version.
- **Optional `dj` edition musical-key detection** depends on keyfinder + beatroot — these don't build for every arch. Stick with `ac` unless you specifically need BPM detection.
- **Upload dedup-by-hash means storage is content-addressable.** Two users uploading identical files = one copy on disk. Great for disk usage, but be aware when doing per-user disk quotas — quota usage depends on who uploaded the file *first*.
- **No "admin user sees everything" shortcut.** Permissions are strictly per-volume. An admin who wants to see all files must be granted `a` or `rw` on every relevant volume explicitly.

## Links

- Upstream repo: <https://github.com/9001/copyparty>
- Project website + rendered README: <https://copyparty.eu/>
- Releases: <https://github.com/9001/copyparty/releases>
- Docker images: <https://hub.docker.com/u/copyparty>
- GHCR mirror: <https://github.com/9001?tab=packages&repo_name=copyparty>
- CLI help page: <https://copyparty.eu/cli/>
- Accounts-and-volumes help: <https://copyparty.eu/cli/#accounts-help-page>
- Systemd unit + config examples: <https://github.com/9001/copyparty/tree/hovudstraum/contrib/systemd>
- nginx reverse-proxy example: <https://github.com/9001/copyparty/blob/hovudstraum/contrib/nginx/copyparty.conf>
- Synology DSM guide: <https://github.com/9001/copyparty/blob/hovudstraum/docs/synology-dsm.md>
- Docker docs: <https://github.com/9001/copyparty/blob/hovudstraum/scripts/docker/README.md>
- Matrix / Discord / IRC: see README bottom
