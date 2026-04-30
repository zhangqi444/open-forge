---
name: LinuxServer Webtop
description: "Full Linux desktop in a browser — Alpine/Ubuntu/Fedora/Arch with XFCE/KDE/MATE/i3/Openbox, accessible via any modern browser. KasmVNC-based. Hardware-accelerated options. GPL-3.0 (upstream components)."
---

# LinuxServer Webtop

Webtop is **"Linux desktop as a Docker container you access in a browser"** — the **LinuxServer.io** team's containerized port of full desktop environments. Spin up an Alpine/Ubuntu/Fedora/Arch base with your choice of **XFCE / KDE / MATE / i3 / Openbox** desktop environment; access via any modern web browser via **KasmVNC** (WebRTC-style browser-native VNC). Paste-through, audio, clipboard, file-upload, and hardware-accelerated GPU options supported.

Built + maintained by **LinuxServer.io** — established community team known for clean, multi-arch, well-documented Docker images across hundreds of apps. Standard LS.io conventions: `PUID`/`PGID` user mapping, s6-overlay init, multi-arch manifests, weekly OS + app updates.

Use cases: (a) **cloud/remote Linux desktop** without a full VM (b) **disposable browser environment** (security-sensitive Linux work, ephemeral dev env) (c) **kiosk / demo** desktop (d) **tutorial / training** environments (e) **headless CI runner with GUI apps** (f) **legacy desktop apps exposed via browser**.

Features:

- **Full desktop environments**: XFCE, KDE, MATE, i3, Openbox, LXDE, LXQt (per flavor)
- **Base OSes**: Alpine, Ubuntu, Fedora, Arch
- **KasmVNC** — modern VNC with HTML5 client; no plugins needed
- **Clipboard + audio + file-upload** support
- **GPU acceleration** (Nvidia via proper flags) for 3D / video
- **PUID/PGID** user mapping (host UID = container UID)
- **Multi-arch**: x86-64, arm64
- **Auto-update** via Watchtower/LS.io pattern
- **Web console access** via HTTPS with auto-generated cert OR your own

- Upstream repo: <https://github.com/linuxserver/docker-webtop>
- LinuxServer.io: <https://linuxserver.io>
- Docker Hub: <https://hub.docker.com/r/linuxserver/webtop>
- GHCR: <https://github.com/linuxserver/docker-webtop/pkgs/container/webtop>
- Quay: <https://quay.io/repository/linuxserver.io/webtop>
- Blog: <https://blog.linuxserver.io>
- Discord: <https://linuxserver.io/discord>
- Discourse: <https://discourse.linuxserver.io>
- OpenCollective: <https://opencollective.com/linuxserver>

## Architecture in one minute

- **KasmVNC** server inside container, served via HTTPS (port 3000 / 3001 by default)
- **s6-overlay** init system
- **Docker image tags** denote base OS + DE — e.g., `ubuntu-xfce`, `alpine-kde`, `arch-i3`
- **Resource**: varies — 500MB-2GB RAM baseline; DE choice dominates (KDE heavier than i3)
- **GPU passthrough** for 3D acceleration (Nvidia `--gpus` + specific device mapping)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker             | **`lscr.io/linuxserver/webtop:<flavor>`**                      | **Upstream-primary**                                                               |
| Docker Compose     | Example in README                                                          | Persistent `/config` volume essential                                                      |
| Kubernetes         | Standard Docker deploy                                                                 | Community charts exist                                                                                 |
| GPU-enabled        | With `--gpus` + Nvidia Container Toolkit                                                            | For Blender, Unity, video work                                                                            |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Image flavor         | `ubuntu-xfce`, `alpine-kde`, `fedora-mate`, `arch-i3`, etc.              | Choice       | Pin the specific flavor tag                                                                              |
| `PUID` / `PGID`      | Usually 1000/1000 (match host user)                                                         | Permissions  | Avoids permission issues on mounted volumes                                                             |
| `TZ`                 | `America/Los_Angeles`                                                                       | Time         | Container timezone                                                                                                 |
| `/config` volume     | Persistent user home                                                                                     | Storage      | All user data, settings, installed apps live here                                                                                  |
| Password             | Set via container username + password OR disable auth (only internal network!)                                            | Security     | Default often NO password — **ALWAYS set**                                                                                              |
| Ports                | 3000 (HTTP), 3001 (HTTPS)                                                                                                              | Network      | Reverse-proxy + TLS recommended; Webtop's self-signed is ok for internal                                                                                                                |
| `SUBFOLDER` (opt)    | `/webtop/` if reverse-proxied at sub-path                                                                                                              | Proxy        | For nginx at `/webtop/` path                                                                                                                                 |
| GPU (opt)            | `--gpus all`                                                                                                                                                            | Hardware     | Nvidia Container Toolkit setup required                                                                                                                                                             |

## Install via Docker

```yaml
services:
  webtop:
    image: lscr.io/linuxserver/webtop:ubuntu-xfce     # **pin** to a flavor; avoid raw :latest
    container_name: webtop
    security_opt:
      - seccomp:unconfined                            # required for some DEs/kernels
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - SUBFOLDER=/                                   # /webtop/ if behind proxy at subpath
      - TITLE=Webtop
    volumes:
      - ./webtop-config:/config
      # Optionally mount Docker socket for nested-docker-in-webtop
      # - /var/run/docker.sock:/var/run/docker.sock
    ports:
      - "3000:3000"
      - "3001:3001"
    shm_size: "1gb"
    restart: unless-stopped
```

## First boot

1. Deploy with chosen flavor + PUID/PGID + TZ
2. Browse `https://<host>:3001` (or HTTP 3000 for internal)
3. Accept self-signed cert (or put behind reverse proxy with real cert)
4. Set a password on first login (via container env var or KasmVNC config)
5. Open Terminal in the desktop → install apps via the base distro's package manager
6. Customize DE settings — they persist in `/config`
7. Put behind TLS reverse proxy for external access
8. Back up `/config` volume

## Data & config layout

- `/config/` — the entire user home (`~`) lives here, including:
  - Installed apps config
  - Desktop settings (themes, panels)
  - Browser profiles, editor configs
  - SSH keys (if you add them)
  - Any files you download or create
- **Everything else** in the container is ephemeral — apps you `apt install` persist only for the container's lifetime of that image; rebuilding = reinstall

## Backup

```sh
# Stop for consistency then tar the config volume
docker compose stop webtop
sudo tar czf webtop-config-$(date +%F).tgz webtop-config/
docker compose start webtop
```

**Big config volumes** (users install lots of apps + download files) may grow quickly — budget accordingly.

## Upgrade

1. LS.io images rebuilt weekly with OS + app security updates. **Pin the flavor tag** (e.g., `ubuntu-xfce`) but let the rolling rebuild handle patches.
2. **BUT**: if you `apt install` packages in the container, those are LOST on image rebuild. For persistent apps, either (a) add to a custom Dockerfile extending the LS.io image (b) install to `/config/` paths (tricky) (c) accept the tradeoff.
3. **Manual pull**: `docker compose pull && docker compose up -d`. Watchtower / Diun (batch 79) can automate notification.
4. **Base-OS switches** (e.g., `ubuntu-xfce` → `alpine-kde`) mean different package ecosystem; treat as reinstall.

## Gotchas

- **Apt-installed apps don't persist across image updates** unless you build a custom image extending LS.io's. This is the #1 Webtop gotcha. Solutions:
  - Install apps into `~/.local/` (persists in `/config`)
  - Flatpak / AppImage in `/config`
  - Custom Dockerfile: `FROM lscr.io/linuxserver/webtop:ubuntu-xfce` + your `RUN apt install ...`
  - Accept re-install as part of updates (homelab-OK; production-annoying)
- **Browser audio/clipboard/microphone permissions** vary — check KasmVNC docs for the current quirks per browser. Firefox usually works; Safari has more edge cases.
- **GPU passthrough** is advanced — requires Nvidia Container Toolkit; matching driver versions; specific compose flags. Worth it for 3D/video work; skip if CPU-rendering is fine.
- **`seccomp:unconfined`** is commonly needed for some DEs (especially KDE) due to container seccomp filters blocking syscalls. Security tradeoff: relaxes one layer of isolation. Evaluate threat model.
- **Expose with MFA or VPN-only access.** A Webtop is essentially a remote desktop — same attack surface as Nexterm (batch 81): hub-of-credentials / hub-of-browser-sessions / full shell. Don't leave the default port open on the public Internet. Use:
  - Tailscale / WireGuard / Cloudflare Tunnel
  - Authentik / Authelia forward-auth
  - KasmVNC password (minimum)
- **No native MFA in KasmVNC** — protect at proxy/network layer.
- **Persistent browser sessions** inside Webtop = session tokens stored. If the container is compromised, those tokens leak. Consider ephemeral Firefox profiles or a browser-in-container-in-Webtop pattern for sensitive work.
- **Clipboard-through-browser** means copy-paste between your local laptop and Webtop works → also means the Webtop can potentially read / write your browser's clipboard. Review browser permission prompts.
- **File upload/download** via KasmVNC works but is slower than native. For large files, use SSH/SFTP to the host or mount a shared volume.
- **shm_size** default in Docker is 64MB — too small for Chrome/Firefox in a desktop. Bump to 1-2GB as in example above.
- **Audio**: KasmVNC supports audio but requires correct browser permissions + the base image's PulseAudio setup. Some flavors work better than others.
- **Kasm vs noVNC**: LS.io uses KasmVNC (modern fork with better performance). Older Webtop images used noVNC. Performance difference is noticeable.
- **Regional compute cost**: running a full desktop 24/7 on a cloud VM costs more than ephemeral SaaS alternatives (GitHub Codespaces, Gitpod, Coder). Do the math for your use case.
- **License + component-level licensing**: LS.io packaging is GPL/Apache-mixed; the containerized desktops are each under their own upstream licenses (XFCE = LGPL+GPL; KDE = LGPL+GPL; etc.). For internal use: nothing to worry about. For redistributing a modified Webtop: audit per-component.
- **LS.io trust signal**: established team; clean images; weekly updates; no surprises. Strong track record. Positive bus-factor signal — LS.io has survived multiple maintainer transitions over the years.
- **Ethical support**: LS.io OpenCollective. Classic community-funded OSS. Donate if heavily used.
- **Alternatives worth knowing:**
  - **Kasm Workspaces** (the company) — commercial product LS.io's images are derived from; full multi-user admin UI
  - **Apache Guacamole** — HTML5 remote-desktop gateway; handles SSH/VNC/RDP to ANY backend
  - **XPipe** — desktop multi-protocol connection manager (not browser-based)
  - **Nexterm** (batch 81) — browser-based remote-access; different scope (manages external servers, not one desktop)
  - **Coder** / **Gitpod** — dev-env-in-browser
  - **noVNC + manual VNC server** — DIY
  - **Choose Webtop if:** want "quick full desktop in a container" + LS.io conventions + single-user.
  - **Choose Kasm Workspaces if:** enterprise + multi-user + audit.
  - **Choose Guacamole if:** need gateway to multiple existing servers (not a new desktop).

## Links

- Repo: <https://github.com/linuxserver/docker-webtop>
- Docker Hub: <https://hub.docker.com/r/linuxserver/webtop>
- GHCR: <https://github.com/linuxserver/docker-webtop/pkgs/container/webtop>
- Quay: <https://quay.io/repository/linuxserver.io/webtop>
- LinuxServer.io: <https://linuxserver.io>
- Discord: <https://linuxserver.io/discord>
- Discourse: <https://discourse.linuxserver.io>
- Blog: <https://blog.linuxserver.io>
- OpenCollective: <https://opencollective.com/linuxserver>
- KasmVNC: <https://github.com/kasmtech/KasmVNC>
- Kasm Workspaces (commercial parent tech): <https://www.kasmweb.com>
- Apache Guacamole (alt): <https://guacamole.apache.org>
- Coder (alt): <https://coder.com>
