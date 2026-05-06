---
name: fluidd
description: Fluidd recipe for open-forge. Lightweight responsive web interface for Klipper 3D printer firmware, running alongside Moonraker API. Supports multiple printers, customizable layouts, and real-time print monitoring. Source: https://github.com/fluidd-core/fluidd
---

# Fluidd

Lightweight and responsive web UI for Klipper, the 3D printer firmware. Provides real-time print monitoring, printer configuration editing, file management, temperature graphs, macros, and multi-printer support. Runs as a static web app served by nginx alongside the Moonraker API layer. Upstream: https://github.com/fluidd-core/fluidd. Docs: https://docs.fluidd.xyz.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| KIAUH (Klipper Installation And Update Helper) | Linux (Raspberry Pi / SBC) | Recommended. Installs Klipper + Moonraker + Fluidd together. |
| Manual (nginx + static files) | Linux | Download release zip, serve with nginx. |
| Docker (official image) | Docker | ghcr.io/fluidd-core/fluidd — serves Fluidd on port 80. |
| Docker (unprivileged) | Docker | ghcr.io/fluidd-core/fluidd-unprivileged — port 8080. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Moonraker API URL?" | e.g. http://localhost:7125 — Fluidd connects to Moonraker for printer control |
| setup | "Port to serve Fluidd on?" | Default 80 (or 8080 for unprivileged Docker) |
| printer | "Multiple printers?" | Fluidd supports managing multiple Moonraker instances from one UI |

## Software-layer concerns

### Architecture

Fluidd is a static Vue.js SPA. It does NOT communicate with Klipper directly.
The stack is: Klipper (firmware) → Moonraker (API/WebSocket) → Fluidd (browser UI).
Moonraker must be installed and running before Fluidd is useful.

### KIAUH install (recommended for Raspberry Pi / SBC)

  # Install KIAUH
  git clone https://github.com/dw-0/kiauh.git
  cd kiauh
  ./kiauh.sh

  # In the KIAUH menu:
  # 1) Install > Klipper
  # 2) Install > Moonraker
  # 3) Install > Fluidd
  # KIAUH handles nginx config, systemd services, and dependencies.

### Manual install

  # Download latest release
  mkdir -p /home/pi/fluidd
  wget https://github.com/fluidd-core/fluidd/releases/latest/download/fluidd.zip
  unzip fluidd.zip -d /home/pi/fluidd/

  # nginx config: serve /home/pi/fluidd as root, proxy /websocket and /printer/* to Moonraker
  # See: https://docs.fluidd.xyz/installation/manual-install

### Docker

  # Standard (port 80)
  docker run -d \
    --name fluidd \
    -p 80:80 \
    ghcr.io/fluidd-core/fluidd

  # Unprivileged (port 8080)
  docker run -d \
    --name fluidd \
    -p 8080:8080 \
    ghcr.io/fluidd-core/fluidd-unprivileged

  # When using Docker, Moonraker still needs to be accessible.
  # Set MOONRAKER_URL env var or configure via Fluidd's UI Settings > Printer.

### Key nginx proxy config (manual install)

  location /websocket {
      proxy_pass http://127.0.0.1:7125/websocket;
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
  }
  location ~* ^/(printer|api|access|machine|server)/ {
      proxy_pass http://127.0.0.1:7125;
  }

## Upgrade procedure

  # Via KIAUH: run ./kiauh.sh > Update > Fluidd
  # Manual: download new release zip, extract over existing files, clear browser cache
  # Docker: docker pull ghcr.io/fluidd-core/fluidd && docker restart fluidd

## Gotchas

- **Moonraker is required**: Fluidd is a frontend only. Without a running Moonraker instance, the UI shows a connection error.
- **Klipper printer.cfg**: Fluidd expects certain macros (PAUSE, RESUME, CANCEL_PRINT) to exist in printer.cfg. Add them for full UI functionality.
- **CORS / same-origin**: Fluidd must be served from the same host as Moonraker, or Moonraker's cors_domains must include the Fluidd URL.
- **Camera support**: webcam integration requires additional setup (mjpeg-streamer or crowsnest). See Fluidd docs.
- **Browser cache**: after upgrades, hard-refresh (Ctrl+Shift+R) the browser to clear cached JS/CSS.
- **Multi-printer**: each printer needs its own Klipper + Moonraker instance. Fluidd's UI can switch between multiple Moonraker endpoints.

## References

- Upstream GitHub: https://github.com/fluidd-core/fluidd
- Documentation: https://docs.fluidd.xyz
- KIAUH installer: https://github.com/dw-0/kiauh
- Moonraker (API layer): https://github.com/Arksine/moonraker
- Klipper firmware: https://github.com/Klipper3d/klipper
- Container images: https://github.com/fluidd-core/fluidd/pkgs/container/fluidd
