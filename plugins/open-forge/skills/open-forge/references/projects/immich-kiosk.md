---
name: Immich Kiosk
description: "Highly configurable slideshow display for Immich assets on browsers and TV/kiosk devices. Docker. Go. damongolding/immich-kiosk. Requires existing Immich install."
---

# Immich Kiosk

**Highly configurable slideshow for displaying your Immich photo/video library on browsers and kiosk devices.** Run it on a TV, digital photo frame, Raspberry Pi with Chromium, or any browser. Supports people, albums, random, oldest/newest ordering, clock overlay, transition effects, burn-in protection, multi-client sync, and a ton of configuration options.

**Requires an existing Immich server** — Kiosk is a display layer, not a photo storage server.

Built + maintained by **Damon Golding**. Not affiliated with Immich.

- Upstream repo: <https://github.com/damongolding/immich-kiosk>
- Docs: <http://docs.immichkiosk.app>
- Demo: <http://demo.immichkiosk.app>
- Docker Hub: `ghcr.io/damongolding/immich-kiosk`
- Immich Discord channel: `#kiosk` in the Immich Discord

## Architecture in one minute

- **Go** web server — serves the kiosk slideshow UI to browsers
- Connects to **Immich API** (read-only) to fetch assets
- Port **3000** (default)
- Config via **`config.yaml`** file or **environment variables** or **URL query parameters** (all three work)
- Multi-client: multiple browser tabs/devices can display the same Kiosk instance simultaneously
- Resource: **tiny** — lightweight Go binary

## Compatible install methods

| Infra        | Runtime                                  | Notes                                          |
| ------------ | ---------------------------------------- | ---------------------------------------------- |
| **Docker**   | `ghcr.io/damongolding/immich-kiosk`      | **Primary** — Docker Hub / GHCR                |

## Prerequisites

- A running **Immich** instance (any version supported by the Kiosk release — check release notes)
- An Immich **API key** (Settings → API Keys in Immich web UI)
- The Immich server URL (must be reachable from the Kiosk container's network)

## Inputs to collect

| Input                    | Example                              | Phase   | Notes                                                                          |
| ------------------------ | ------------------------------------ | ------- | ------------------------------------------------------------------------------ |
| Immich URL               | `http://immich-server:2283`          | Config  | Must be reachable from Kiosk container; internal Docker network URL works      |
| Immich API key           | `xxxxxxxx`                           | Auth    | Read-only key sufficient; create in Immich Settings → API Keys                |
| Album or person IDs      | from Immich URL/settings             | Config  | Optional; defaults to all assets if not specified                              |
| Slide duration           | `60` (seconds)                       | Config  | Default 60s per slide                                                          |

## Install via Docker

```yaml
services:
  immich-kiosk:
    image: ghcr.io/damongolding/immich-kiosk:latest
    container_name: immich-kiosk
    ports:
      - "3000:3000"
    environment:
      KIOSK_IMMICH_API_KEY: "your-api-key-here"
      KIOSK_IMMICH_URL: "http://immich-server:2283"
    restart: unless-stopped
```

Or use a `config.yaml` file:

```yaml
services:
  immich-kiosk:
    image: ghcr.io/damongolding/immich-kiosk:latest
    ports:
      - "3000:3000"
    volumes:
      - ./config.yaml:/config.yaml:ro
    restart: unless-stopped
```

## Configuration (`config.yaml`)

```yaml
immich_api_key: "your-api-key"
immich_url: "http://immich-server:2283"

duration: 60              # seconds per slide
show_time: true           # clock overlay
show_date: true
time_format: 24           # 12 or 24

# Asset sources (choose one or more)
albums:
  - "ALBUM_UUID_HERE"     # specific album(s)
# people:
#   - "PERSON_UUID"       # face-recognition filtered
# show_archived: false    # include archived assets

album_order: random       # random | newest | oldest

# Transitions
transition: fade          # fade | cross-fade | none

# Burn-in protection (for OLED/plasma displays)
burn_in_interval: 120     # minutes between cycles (0 = disabled)
burn_in_duration: 30      # seconds per cycle
```

Full config reference: <http://docs.immichkiosk.app>

URL params also work — e.g. `http://kiosk:3000?duration=30&album=ALBUM_ID` — useful for per-device customization without multiple config files.

## First boot

1. Get an Immich API key (Immich → Settings → API Keys).
2. Note the album/person UUIDs you want to display (visible in Immich URLs).
3. Deploy Kiosk with `KIOSK_IMMICH_API_KEY` + `KIOSK_IMMICH_URL` env vars.
4. Visit `http://<host>:3000` in a browser — slideshow starts.
5. Point a TV, photo frame, or Pi + Chromium at the URL.
6. Enable burn-in protection if using OLED/plasma.
7. Optionally put behind TLS if accessing remotely.

## Backup

Kiosk is stateless. Nothing to back up — config is in `config.yaml` (commit to git) or env vars. All photos live in Immich.

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Gotchas

- **Immich must be reachable from the Kiosk container.** If Kiosk and Immich are in separate Docker Compose stacks, put them on the same Docker network, or use the host IP. `localhost` inside the Kiosk container points to Kiosk, not Immich.
- **API key is sufficient read-only.** You don't need admin credentials. Create a read-only API key in Immich.
- **Album/person UUIDs, not names.** Kiosk uses Immich's internal UUIDs (visible in the URL when you open an album or person in Immich). Copy from the URL bar.
- **URL params override config.yaml.** Handy for per-device customization (e.g., one device shows the `family` album, another shows `vacation`) by appending `?album=UUID` to the URL.
- **Burn-in protection for OLED/plasma.** If running on an OLED TV or plasma display, enable `burn_in_interval` + `burn_in_duration` to periodically shift the image — prevents permanent screen burn.
- **Multi-client sync.** Multiple browser tabs showing the same Kiosk URL stay in sync (same slide shown across all clients). Intentional feature for multi-TV setups.
- **Not affiliated with Immich.** Kiosk is a third-party project. Immich API changes can break Kiosk — check the Kiosk release notes when updating Immich.
- **Chromium kiosk mode on Pi.** For a dedicated photo frame: `chromium-browser --kiosk http://kiosk:3000` — fullscreen, no UI chrome. DietPi has a guide in the docs.

## Project health

Active Go development, GHCR CI, docs site, demo instance, Immich Discord channel, Buy Me A Coffee. Solo-maintained by Damon Golding.

## Photo-frame-display comparison

- **Immich Kiosk** — Go, Immich-native, highly configurable, URL params, burn-in protection
- **Photoprism Slideshow** — built into Photoprism, less configurable
- **Memories (Nextcloud app)** — Nextcloud-native photo app; has slideshow view
- **Screenly OSE** — digital signage for Pi; shows any URL including Kiosk

**Choose Immich Kiosk if:** you already use Immich and want a dedicated, configurable photo-frame slideshow for TVs and kiosk devices.

## Links

- Repo: <https://github.com/damongolding/immich-kiosk>
- Docs: <http://docs.immichkiosk.app>
- Demo: <http://demo.immichkiosk.app>
- Immich: <https://github.com/immich-app/immich>
- Config reference: <http://docs.immichkiosk.app>
