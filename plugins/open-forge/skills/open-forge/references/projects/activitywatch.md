---
name: activitywatch-project
description: ActivityWatch recipe for open-forge. Open-source, privacy-first automated time tracker. Records active application, window title, browser tab, and AFK status. Stores all data locally. Primarily a desktop/client application; aw-server can be exposed for multi-device dashboards. Upstream: https://github.com/ActivityWatch/activitywatch.
---

# ActivityWatch

Open-source, privacy-first automated time tracker. Records which applications you use, how long, and what you were looking at — without sending data anywhere. All data lives on your machine in a local SQLite database served by `aw-server`. Includes a web UI for activity dashboards and timeline views. Upstream: <https://github.com/ActivityWatch/activitywatch>. Docs: <https://docs.activitywatch.net>.

> **Architecture note:** ActivityWatch is primarily a **desktop application**, not a traditional self-hosted server service. `aw-server` (data store + REST API + web UI) runs locally alongside client-side *watchers* (aw-watcher-window, aw-watcher-afk, aw-watcher-input). The watchers must run on the same machine whose activity you want to track — they cannot run inside a container and track a remote desktop. For most self-hosting purposes, run ActivityWatch natively on each tracked machine.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Native installer (Windows/macOS/Linux) | <https://github.com/ActivityWatch/activitywatch/releases> | Yes | Primary path. Installs aw-server + aw-qt system tray launcher + watchers. |
| AppImage / zip (Linux) | <https://github.com/ActivityWatch/activitywatch/releases> | Yes | No-install Linux option. Extract and run `./aw-qt`. |
| AUR (Arch Linux) | `activitywatch-bin` | Community | `yay -S activitywatch-bin` |
| Docker (aw-server only) | Community | No | Exposes the server API and web UI; watchers still must run natively on tracked machines. |
| Android | <https://github.com/ActivityWatch/aw-android> | Yes | Play Store or APK. Tracks app usage on Android. |

---

## Method — Native Install (Primary)

> **Source:** <https://docs.activitywatch.net/en/latest/getting-started.html>

### Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Operating system | Windows, macOS, or Linux. Download matching installer from the releases page. |
| preflight | Server bind address | Default: `127.0.0.1:5600`. Change to `0.0.0.0:5600` only if exposing to other LAN devices (see Gotchas). |

### Setup

```bash
# 1. Download the latest release for your platform
#    https://github.com/ActivityWatch/activitywatch/releases/latest

# Linux (AppImage / zip):
# Extract the zip, then:
cd activitywatch/
./aw-qt   # Launches system tray icon, starts aw-server + watchers automatically

# macOS:
# Open the .dmg, drag ActivityWatch to Applications, then launch it.

# Windows:
# Run the installer (.exe), then launch ActivityWatch from the Start Menu.

# 2. Open the web UI
#    http://localhost:5600

# 3. Enable autostart (if the installer did not set it up automatically)
#    Settings -> General -> Start on login
```

### Configuration

Config file locations:

| Platform | Path |
|---|---|
| Linux | `~/.config/activitywatch/aw-server-rust/config.toml` |
| macOS | `~/Library/Application Support/activitywatch/aw-server-rust/config.toml` |
| Windows | `%APPDATA%\activitywatch\aw-server-rust\config.toml` |

Key options (aw-server-rust):

```toml
# Bind address — change to 0.0.0.0 to allow LAN access (see Gotchas first)
address = "127.0.0.1"
port = 5600

# Additional CORS origins (e.g. for a custom dashboard on another device)
# cors = ["http://my-nas:3000"]
```

### Data directory

| Platform | Path |
|---|---|
| Linux | `~/.local/share/activitywatch/` |
| macOS | `~/Library/Application Support/activitywatch/` |
| Windows | `%APPDATA%\activitywatch\` |

Data is stored as SQLite databases, one per watcher bucket. Back this directory up to preserve history.

---

## Method — Docker (aw-server only, advanced)

> Exposes the aw-server REST API and web UI in a container. You still need to run watchers natively on each tracked machine and configure them to report to this server.

```yaml
# docker-compose.yml (community approach — not upstream-maintained)
services:
  aw-server:
    image: ghcr.io/activitywatch/aw-server-rust:latest
    container_name: aw-server
    ports:
      - "5600:5600"
    volumes:
      - aw-data:/root/.local/share/activitywatch
    restart: unless-stopped

volumes:
  aw-data:
```

Then configure your native watchers on each tracked machine to report to the server:

```toml
# aw-watcher-window config on each tracked machine
# ~/.config/activitywatch/aw-watcher-window/aw-watcher-window.toml
host = "192.168.1.50"
port = 5600
```

---

## Upgrade procedure

**Native:** Download the latest release from the releases page and re-run the installer (Windows/macOS), or replace the AppImage/zip directory (Linux). Existing data is preserved.

**Docker:**
```bash
docker compose pull
docker compose up -d
```

Data persists in the named volume.

---

## Gotchas

- **Watchers cannot run inside Docker.** The window and AFK watchers need direct access to the desktop session (X11/Wayland/macOS/Windows display APIs). Running them containerized is not supported. The Docker image only works for the data server (aw-server).
- **No authentication on aw-server.** Anyone who can reach port 5600 can read all your activity data. Do not expose it to the internet without a reverse proxy with HTTP Basic Auth, or restrict it to VPN/LAN access only.
- **Multi-device sync is experimental.** Official sync between multiple ActivityWatch instances is still a work-in-progress. See <https://github.com/ActivityWatch/activitywatch/issues/35>. Each machine currently has its own independent data store.
- **Browser tab tracking needs an extension.** Install `aw-watcher-web` (Firefox/Chrome) for URL and tab tracking — it is not bundled with the main installer. See <https://docs.activitywatch.net/en/latest/watchers.html#aw-watcher-web>.
- **aw-server-rust vs aw-server (Python).** Recent releases default to the Rust server (faster, lower memory). The Python `aw-server` is legacy. They run on different default ports (5600 vs 5666 in test mode).
- **Data is local-only.** There is no cloud sync or account. Back up your data directory regularly.

### Links

- Upstream README: <https://github.com/ActivityWatch/activitywatch/blob/master/README.md>
- Documentation: <https://docs.activitywatch.net>
- Getting started: <https://docs.activitywatch.net/en/latest/getting-started.html>
- Watchers reference: <https://docs.activitywatch.net/en/latest/watchers.html>
- REST API reference: <https://docs.activitywatch.net/en/latest/api.html>
- Releases: <https://github.com/ActivityWatch/activitywatch/releases>
- Android app: <https://github.com/ActivityWatch/aw-android>
