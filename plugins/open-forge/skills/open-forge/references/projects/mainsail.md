---
name: mainsail
description: Mainsail recipe for open-forge. Covers self-hosting the Klipper 3D printer web interface. Upstream: https://github.com/mainsail-crew/mainsail
---

# Mainsail

Lightweight, responsive web UI for Klipper 3D printer firmware. Makes Klipper accessible from any browser with a consistent design. Features printer farm support, print history, G-code viewer, bed mesh visualisation, webcam support, timelapse integration, and power control. Upstream: <https://github.com/mainsail-crew/mainsail>. Docs: <https://docs.mainsail.xyz>.

**License:** GPL-3.0

> **Note:** Mainsail is a **frontend only**. It requires a running [Klipper](https://github.com/Klipper3d/klipper) instance and [Moonraker](https://github.com/Arksine/moonraker) API server to function. The recommended install path is [KIAUH](https://github.com/dw-0/kiauh) (Klipper Installation And Update Helper) or [MainsailOS](https://github.com/mainsail-crew/MainsailOS) (Raspberry Pi image).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| MainsailOS (Raspberry Pi image) | https://github.com/mainsail-crew/MainsailOS | ✅ | New Raspberry Pi setup; all-in-one image with Klipper + Moonraker + Mainsail |
| KIAUH (Klipper Installation And Update Helper) | https://github.com/dw-0/kiauh | Community | Recommended for Linux installs; handles Klipper + Moonraker + Mainsail |
| Manual (nginx + static files) | https://docs.mainsail.xyz/setup/manual-setup | ✅ | Advanced; serves pre-built static files behind nginx |
| Docker | https://docs.mainsail.xyz/setup/docker | Community | Via `mkuf/mainsail` or Klipper-docker-compose stacks |
| my.mainsail.xyz (remote) | https://my.mainsail.xyz | ✅ | Cloud-hosted frontend connecting to a local Moonraker; no local install needed |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| app | "Moonraker API URL?" | e.g. http://printer.local:7125 | All |
| app | "Port to serve Mainsail on?" | Number (default: 80) | Manual/Docker |
| infra | "Running on Raspberry Pi?" | Yes/No | Determines whether to recommend MainsailOS |

## Manual install (nginx)

```bash
# Download latest release
mkdir -p /var/www/mainsail
wget -q -O /tmp/mainsail.zip \
  $(curl -sf https://api.github.com/repos/mainsail-crew/mainsail/releases/latest | grep '"browser_download_url"' | grep '\.zip"' | cut -d'"' -f4)
unzip /tmp/mainsail.zip -d /var/www/mainsail

# Configure nginx to serve /var/www/mainsail
# See: https://docs.mainsail.xyz/setup/manual-setup#nginx-configuration
```

## Software-layer concerns

### config.json (Mainsail configuration)

Mainsail reads a `config.json` from its root. Key settings:

```json
{
  "instancesDB": "browser",
  "instances": [
    {
      "hostname": "printer.local",
      "port": 7125
    }
  ]
}
```

Or configure printer connections via the web UI on first launch.

### Moonraker dependency

Mainsail communicates exclusively via the [Moonraker](https://github.com/Arksine/moonraker) WebSocket/REST API (default port 7125). Klipper must be running and Moonraker must be configured to allow CORS from the Mainsail origin.

### Moonraker update_manager (auto-update)

Add to `moonraker.conf` to enable Mainsail updates via KIAUH or the UI:

```ini
[update_manager mainsail]
type: web
channel: stable
repo: mainsail-crew/mainsail
path: ~/mainsail
```

## Upgrade procedure

```bash
# Via KIAUH (recommended)
# Run KIAUH → Update → Mainsail

# Manual
wget -q -O /tmp/mainsail.zip <latest-release-url>
unzip -o /tmp/mainsail.zip -d /var/www/mainsail
```

## Gotchas

- **Frontend only.** Mainsail does nothing without Klipper + Moonraker. For a new printer setup, start with MainsailOS or KIAUH.
- **Moonraker CORS config.** If Mainsail is served from a different host/port than Moonraker, configure `cors_domains` in `moonraker.conf`.
- **my.mainsail.xyz is a convenience shortcut.** It's a CDN-hosted version of the same static frontend. Printer data stays local; only the HTML/JS is loaded from the cloud.
- **MainsailOS vs KIAUH.** MainsailOS is a full SD card image for Raspberry Pi. KIAUH is a script that installs components on an existing Linux system (Debian/Ubuntu/Armbian recommended).
- **Timelapse requires moonraker-timelapse.** Install [moonraker-timelapse](https://github.com/mainsail-crew/moonraker-timelapse) separately for automatic timelapse recording.

## Upstream docs

- Documentation: https://docs.mainsail.xyz
- Setup guide: https://docs.mainsail.xyz/setup
- GitHub README: https://github.com/mainsail-crew/mainsail
- MainsailOS: https://github.com/mainsail-crew/MainsailOS
- KIAUH: https://github.com/dw-0/kiauh
