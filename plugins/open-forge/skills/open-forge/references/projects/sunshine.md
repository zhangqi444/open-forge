---
name: sunshine-project
description: Sunshine recipe for open-forge. GPL-3.0 self-hosted game stream host for Moonlight clients — a free/open-source alternative to NVIDIA GameStream. Runs on Windows / Linux / macOS / FreeBSD hosts with a GPU (NVENC/AMF/QuickSync/VAAPI/VideoToolbox) to encode the desktop and stream it with low latency to Moonlight clients (Android, iOS, Apple TV, Steam Deck, browser, Raspberry Pi, etc.). This recipe covers the upstream install packages (Windows MSI, macOS DMG, Linux .deb/.rpm/Flatpak/AppImage/Arch), the Docker image (Linux GPU-host only; complex), and the canonical gotchas: HDR + encoder support, the GPU-can't-be-headless problem on Linux, the web-config port 47990 admin bootstrap, and PIN-pairing with Moonlight clients.
---

# Sunshine

GPL-3.0 self-hosted game stream host for Moonlight clients. Low-latency desktop/game streaming with hardware-accelerated encoding (AMD, Intel, NVIDIA). Upstream: <https://github.com/LizardByte/Sunshine>. Docs: <https://docs.lizardbyte.dev/projects/sunshine>.

Pair with any Moonlight client — Android, iOS, tvOS, Windows, macOS, Linux, Steam Deck, ChromeOS, webOS, browser. Sunshine is essentially the "host half" that replaces NVIDIA's deprecated GameStream protocol, but works on non-NVIDIA GPUs too.

## What you deploy

- One **Sunshine daemon** per machine with the GPU you want to stream from.
- Sunshine runs in the user session (Windows service / Linux systemd user unit / launchctl), listens on:
  - `47989/tcp` — HTTP (pairing, control)
  - `47984/tcp` — HTTPS (pairing, control)
  - `47990/tcp` — Web configuration UI (localhost-only by default)
  - `48010/tcp` + `48010/udp` — Stream (RTSP/control)
  - Plus dynamic ports for video/audio/input.
- A **web config UI** at `https://<host>:47990/` for setup and client pairing.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Windows MSI | <https://github.com/LizardByte/Sunshine/releases> | ✅ | Windows 10/11 gaming PC. Recommended for Windows hosts. |
| macOS DMG | Same releases page | ✅ (experimental) | Apple Silicon + Intel Mac. Encoding via VideoToolbox. |
| Debian/Ubuntu `.deb` | Releases page (`sunshine-*-amd64.deb`) | ✅ | Debian 12+, Ubuntu 22.04/24.04. |
| Fedora/RHEL `.rpm` | Releases page | ✅ | Fedora 40+, RHEL 9+. |
| Arch Linux (AUR: `sunshine`) | Community-packaged | ⚠️ AUR | Arch-family distros. Upstream points at it but doesn't maintain. |
| Flathub Flatpak (`dev.lizardbyte.app.Sunshine`) | <https://flathub.org/apps/dev.lizardbyte.app.Sunshine> | ✅ | Sandboxed install; works across most Linux distros. |
| AppImage | Releases page | ✅ | Portable, no install; Linux. |
| Winget (`LizardByte.Sunshine`) | Winget pkgs | ✅ | Windows CLI install. |
| Docker (`lizardbyte/sunshine` / `ghcr.io/lizardbyte/sunshine`) | <https://hub.docker.com/r/lizardbyte/sunshine> | ✅ (Linux only, GPU passthrough required) | Server/NAS Linux host with a GPU. Complex — requires `--gpus all`, Wayland/X socket mounts, `--cap-add SYS_NICE`, etc. |
| Build from source | `CMakeLists.txt` | ✅ | Custom builds / unsupported GPU drivers. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Host OS?" | `AskUserQuestion`: `Windows` / `macOS` / `Linux (package)` / `Linux (Flatpak)` / `Linux (Docker)` | Drives install section. |
| preflight | "GPU vendor?" | `AskUserQuestion`: `NVIDIA` / `AMD` / `Intel` / `Apple Silicon` / `Software-only (no GPU)` | Determines which encoder Sunshine will select (NVENC / AMF / QuickSync / VAAPI / VideoToolbox / CPU). |
| preflight | "Display state on Linux?" | `AskUserQuestion`: `X11 session` / `Wayland (GNOME 46+/KDE)` / `Headless (virtual display)` | Linux streaming requires an active display session. Headless needs a virtual-display driver. |
| admin | "Web UI admin username?" | Free-text, default `sunshine` | Set on first `https://localhost:47990/` visit. |
| admin | "Web UI admin password?" | Free-text (sensitive) | Set on first visit; used for the PIN-pair flow. |
| network | "LAN IP / hostname?" | Free-text | Moonlight clients need to reach this host; make it static-IP or reserve a DHCP lease. |
| firewall | "Open ports on host firewall?" | Boolean | Windows Defender Firewall + Linux ufw/firewalld need the ~10 Sunshine ports allowed on LAN. |

## Install — Windows (MSI, upstream-recommended)

1. Download the latest MSI from <https://github.com/LizardByte/Sunshine/releases>.
2. Run the installer (accept UAC). It installs:
   - Sunshine service ("Sunshine Service" in `services.msc`, **manual** start by default)
   - Virtual display driver (optional)
   - Firewall rules
3. Start the service: **services.msc → Sunshine Service → Start**, or `net start SunshineService` (as admin).
4. Open `https://localhost:47990/` in a browser. You'll get a self-signed cert warning — accept for localhost.
5. Set the admin username + password on the first-run page.
6. **Applications tab → Add Application** for each game/app you want streamable (Steam Big Picture is a common one-click target). "Desktop" is auto-added.

### Winget alternative

```powershell
winget install LizardByte.Sunshine
```

## Install — Linux (`.deb` on Ubuntu/Debian)

```bash
# Download the latest .deb for your Ubuntu/Debian version
wget https://github.com/LizardByte/Sunshine/releases/latest/download/sunshine-debian-bookworm-amd64.deb
sudo apt-get install -y ./sunshine-debian-bookworm-amd64.deb

# The .deb installs a systemd USER unit (not system-wide)
systemctl --user enable --now sunshine
systemctl --user status sunshine
journalctl --user -u sunshine -f
```

For GPU encoding on Linux, also install the vendor driver + VAAPI stack:

```bash
# Intel / AMD (VAAPI)
sudo apt-get install -y mesa-va-drivers vainfo

# NVIDIA — install proprietary driver matching your GPU gen
# (nvidia-driver-550 or later for NVENC; check `nvidia-smi`)
```

Then visit `https://<lan-ip>:47990/` and complete first-run setup.

### Flatpak alternative

```bash
flatpak install flathub dev.lizardbyte.app.Sunshine
flatpak run dev.lizardbyte.app.Sunshine
```

Flatpak Sunshine starts as a normal user process (no systemd integration), so pair-and-stream works but you need to launch it manually or add it to autostart.

## Install — macOS

1. Download the DMG from <https://github.com/LizardByte/Sunshine/releases>.
2. Mount + drag Sunshine.app to Applications.
3. First launch prompts for Accessibility + Screen Recording + Input Monitoring permissions (macOS privacy system). Grant each.
4. Web UI at `https://localhost:47990/`.

macOS support is flagged "experimental" upstream — some features (virtual displays, HDR) are Windows/Linux-only.

## Install — Docker (Linux, GPU-passthrough)

Upstream Docker image is Linux-only and **requires GPU access on the host**. Minimal compose:

```yaml
services:
  sunshine:
    image: lizardbyte/sunshine:latest
    container_name: sunshine
    restart: unless-stopped
    network_mode: host    # Sunshine uses ~10 ports including dynamic ones; host networking is simplest
    cap_add:
      - SYS_ADMIN
      - NET_ADMIN
    security_opt:
      - seccomp:unconfined
    devices:
      - /dev/dri:/dev/dri     # VAAPI (Intel/AMD)
    # For NVIDIA, also add:
    # runtime: nvidia
    # environment:
    #   NVIDIA_VISIBLE_DEVICES: all
    #   NVIDIA_DRIVER_CAPABILITIES: all
    volumes:
      - ./config:/config
      - /tmp/.X11-unix:/tmp/.X11-unix        # If running an X11 session
      - /run/user/1000/wayland-0:/run/user/1000/wayland-0  # If Wayland
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - DISPLAY=:0
```

**Docker installs are complex.** Read <https://docs.lizardbyte.dev/projects/sunshine/latest/md_docs_2docker.html> carefully — GPU passthrough, display-socket access, and audio routing are all fragile. For most users, installing the native package on the GPU host is much simpler than containerizing.

## First-run web UI setup

1. Open `https://<host>:47990/` (accept self-signed cert).
2. Set admin username + password. This is ONLY for the web UI — Moonlight clients pair via PIN, not this login.
3. **Applications tab**: default "Desktop" works out of the box. Add apps (full-screen games, Steam, etc.) — each app spec can specify working dir, command, image, detached processes.
4. **Configuration tab → Network**: if you need to allow LAN access (not just localhost), set `origin_web_ui_allowed = lan` and `upnp = on` to auto-forward.
5. **Configuration tab → Audio/Video**: pick encoder (`auto` works for most setups). For HDR, enable if your GPU+OS support it — typically NVIDIA + Windows + HDR10 display.

## Pair a Moonlight client

1. In the Moonlight client, add your Sunshine host by IP (or it auto-discovers on LAN via mDNS).
2. Moonlight says "This host requires a PIN. Enter the following PIN on your host: 1234".
3. In Sunshine's web UI → **PIN** tab → enter the PIN from Moonlight → **Submit**.
4. The client appears in Sunshine's Clients list. You can now stream.

## Configuration

All config in `sunshine.conf` (Windows: `%AppData%\Sunshine\`; Linux: `~/.config/sunshine/`). The web UI edits this file. Key options:

| Option | Purpose |
|---|---|
| `min_log_level` | `debug` / `info` / `warn` / `error` (default `info`). |
| `encoder` | `auto` / `nvenc` / `amfenc` / `quicksync` / `vaapi` / `software`. |
| `hdr_mode` | Enable HDR streaming (host+display+client must all support). |
| `upnp` | Auto-forward Sunshine ports via UPnP. |
| `origin_web_ui_allowed` | `lan` or `pc` — who can access the web UI. |
| `file_apps` / `file_state` | Override locations of `apps.json` and `sunshine_state.json`. |
| `ping_timeout` | Client disconnect timeout (ms). |

## Gotchas

- **Headless Linux = no display = no streaming.** Sunshine needs an active display session to capture. Headless servers need a virtual-display driver (Intel: VBIOS dummy HDMI plug; NVIDIA: `xorg.conf` with `ConnectedMonitor`) or use the virtual display plugin — this is the single biggest footgun for "stream from my Linux server in the basement" setups. Windows has a built-in virtual display driver option in the MSI installer.
- **`https://localhost:47990/` ALWAYS uses a self-signed cert.** First-time browser visit requires accept-exception. For remote admin over LAN, the cert still won't validate — use a browser profile that remembers the exception.
- **Port forwarding is not enabled by default.** UPnP off by default. For internet streaming (rare — most streaming is LAN-only), you must manually forward the Sunshine port range at the router.
- **Windows Defender Firewall can silently block.** The MSI installer adds firewall rules; if you use a non-MSI install (Winget sometimes misses this), manually add inbound rules for TCP 47989, 47984, 47990, 48010 and UDP 48010.
- **HDR only works on specific combos.** Windows 10 22H2+ / Windows 11, NVIDIA RTX 20-series or later, HDR10 display, Moonlight client that also supports HDR (Apple TV, some Android TV). AMD/Intel HDR support is limited.
- **Audio capture on Linux is finicky.** PulseAudio vs PipeWire: newer distros use PipeWire and need `pipewire-pulse` installed for Sunshine to find the audio source.
- **Steam Big Picture vs Gamepad mapping.** Windows gamepad mapping Just Works. Linux requires `uinput` device access — the Flatpak grants it automatically, but a manual binary install needs the user in the `input` group and a udev rule for `/dev/uinput`.
- **No Web UI auth for pairing PINs.** Anyone who can reach `:47990/` can enter a PIN and pair a new client. Keep the web UI off the public internet; `origin_web_ui_allowed = lan` is the minimum.
- **Controller emulation has platform gaps** (see the compatibility matrix in upstream README). Switch Pro on macOS: not supported. DualShock on Linux: DS4 yes, DS5 via a different driver path.
- **Sunshine + Moonlight Embedded (Raspberry Pi client) = great latency.** This is the "stream from Windows gaming PC to cheap Pi connected to TV" setup that makes Sunshine popular. Works over wired gigabit LAN.
- **Sunshine is NOT a remote-desktop tool.** Don't use it for general remote admin — use something like RustDesk, Parsec, or standard RDP/VNC. Sunshine is optimized for gaming (low latency, high bandwidth, video encoding) and lacks features like file transfer, clipboard sync, or session persistence.
- **GPL-3.0 license.** Client-server model means the GPL-3.0 reciprocity applies — if you distribute a modified Sunshine, you must provide source. Moonlight is also GPL-3.0.

## Links

- Upstream repo: <https://github.com/LizardByte/Sunshine>
- Docs (Read the Docs): <https://docs.lizardbyte.dev/projects/sunshine>
- Stable docs: <https://docs.lizardbyte.dev/projects/sunshine/latest/>
- Releases: <https://github.com/LizardByte/Sunshine/releases>
- Flatpak: <https://flathub.org/apps/dev.lizardbyte.app.Sunshine>
- Docker image: <https://hub.docker.com/r/lizardbyte/sunshine>
- Moonlight clients: <https://moonlight-stream.org/>
- Community Discord: <https://app.lizardbyte.dev/> (link tree)
