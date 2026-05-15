---
name: OwnTracks Recorder
description: "Self-hosted location data storage and viewer for OwnTracks apps. Docker or packages. C. owntracks/recorder. Stores GPS tracks from iOS/Android OwnTracks apps via MQTT or HTTP, REST API, live map, GeoJSON, heatmaps."
---

# OwnTracks Recorder

**Lightweight storage and retrieval backend for OwnTracks location data.** The OwnTracks apps (iOS/Android) publish GPS positions to MQTT or HTTP — the Recorder stores those in plain files and serves them via a built-in REST API and web interface. Live map, track visualization, GeoJSON export, reverse geocoding, and `ocat` CLI for data queries.

Built + maintained by **OwnTracks team**. MIT license.

- Upstream repo: <https://github.com/owntracks/recorder>
- Docs: <https://owntracks.org/booklet/clients/recorder/>
- Docker Hub: <https://hub.docker.com/r/owntracks/recorder>
- OwnTracks iOS: <https://apps.apple.com/app/owntracks/id692424691>
- OwnTracks Android: <https://play.google.com/store/apps/details?id=org.owntracks.android>

## Architecture in one minute

- **C** daemon — compiled binary with no external database
- Storage: plain files on filesystem (JSON location records per user/device/date)
- LMDB for key-value lookups (last position, friends, tokens)
- **MQTT** subscriber mode: connects to broker, receives OwnTracks publishes
- **HTTP** mode: acts as HTTP server receiving OwnTracks HTTP POSTs
- Built-in web server: REST API + static pages + WebSocket (live map)
- `ocat` — CLI utility for querying stored data
- Docker Hub: `owntracks/recorder`
- Port: **8083** (HTTP API + web UI)
- Resource: **very low** — C binary; handles years of location history with minimal RAM

## Compatible install methods

| Infra          | Runtime                    | Notes                                             |
| -------------- | -------------------------- | ------------------------------------------------- |
| **Docker**     | `owntracks/recorder`       | **Primary** — Docker Hub; official image          |
| **Packages**   | APT repo                   | Debian/Ubuntu packages at repo.owntracks.org      |
| **Source**     | C build from GitHub        | `cmake` + `make`; see README                      |

## Inputs to collect

| Input                    | Example                         | Phase   | Notes                                                              |
| ------------------------ | ------------------------------- | ------- | ------------------------------------------------------------------ |
| MQTT broker (if MQTT mode) | `mqtt://mosquitto:1883`       | MQTT    | OwnTracks apps publish to this broker; Recorder subscribes        |
| `OTR_HOST`               | `0.0.0.0`                       | Config  | Bind address for HTTP server                                       |
| `OTR_PORT`               | `8083`                          | Config  | HTTP server port                                                   |
| `OTR_STORAGEDIR`         | `/store`                        | Storage | Where location data files are stored (volume)                      |
| `OTR_TOPICS`             | `owntracks/#`                   | MQTT    | MQTT topic pattern to subscribe to                                 |
| Google Maps API key (opt.)| Google Cloud Console           | Maps    | For reverse geocoding and map tiles in the web UI                  |

## Install via Docker (MQTT mode)

```yaml
services:
  recorder:
    image: owntracks/recorder:1.0.1
    container_name: recorder
    ports:
      - "8083:8083"
    volumes:
      - ./store:/store
    environment:
      - OTR_HOST=0.0.0.0
      - OTR_PORT=8083
      - OTR_STORAGEDIR=/store
      - OTR_MQTT_HOST=mosquitto
      - OTR_MQTT_PORT=1883
      - OTR_TOPICS=owntracks/#
    restart: unless-stopped

  mosquitto:
    image: eclipse-mosquitto:2
    ports:
      - "1883:1883"
    volumes:
      - ./mosquitto.conf:/mosquitto/config/mosquitto.conf
    restart: unless-stopped
```

## Install via Docker (HTTP mode)

In HTTP mode, OwnTracks apps POST directly to the Recorder's HTTP endpoint instead of through MQTT. Configure the OwnTracks app with HTTP mode and the Recorder URL.

```bash
docker run -d \
  --name recorder \
  -p 8083:8083 \
  -v ./store:/store \
  -e OTR_HOST=0.0.0.0 \
  -e OTR_STORAGEDIR=/store \
  owntracks/recorder:1.0.1
```

## First boot

1. Deploy Recorder + Mosquitto (if using MQTT mode).
2. Configure OwnTracks app (iOS/Android):
   - **MQTT mode**: Settings → Connection → MQTT → enter broker host, port, credentials
   - **HTTP mode**: Settings → Connection → HTTP → enter Recorder URL (`http://host:8083/pub`)
   - Set device ID, tracker ID (short 2-char label shown on map)
3. Open the Recorder web UI at `http://localhost:8083`.
4. Start moving — location reports appear on the live map.
5. Explore: view tracks, last positions, GeoJSON exports.
6. Put behind TLS with authentication (nginx basic auth).

## Web UI features

| Feature | Details |
|---------|---------|
| Last positions table | Table of all users + devices with last known location |
| Live map | WebSocket-powered real-time location updates |
| Track map | View historical GPS tracks for any user/device/date range |
| GeoJSON export | Export tracks as GeoJSON for external tools |
| Tabular display | Table view of location records |
| Heatmap | Concentration view of all recorded positions |

## `ocat` CLI

```bash
# List all users and devices
ocat --list

# Show last position for a user
ocat --user=alice --device=iphone

# Show last 4 positions
ocat --user=alice --device=iphone --last=4

# Export GeoJSON track for a date range
ocat --user=alice --device=iphone --from=2024-01-01 --to=2024-01-31 --format=geojson
```

## Reverse geocoding

Recorder supports reverse geocoding (coordinate → address) via:
- **OpenCage** (preferred; `OTR_REVGEO` = opencage + API key)
- **Local OpenStreetMap data** (offline; requires downloaded OSM data)
- **Google** (Maps API key)

Without reverse geo, coordinates are shown without address labels.

## Storage layout

```
store/
├── rec/            # Location records (JSON), by user/device/year-month
│   └── alice/
│       └── iphone/
│           ├── 2024-01.rec
│           └── 2024-02.rec
├── last/           # LMDB: last positions
└── ghash/          # Reverse geo cache
```

Storage is plain files — human-readable JSON records in `.rec` files. Easy to inspect, backup, and process with standard tools.

## Gotchas

- **Mosquitto config for external connections.** By default, recent Mosquitto images require authentication and don't allow anonymous connections. Create a `mosquitto.conf` that configures listener + authentication, or allow anonymous access for internal-only setups.
- **OwnTracks app requires exactly the right connection settings.** MQTT credentials, topic format (`owntracks/<user>/<device>`), and TLS settings must match between the app and the broker/recorder. Use the Recorder's `/api/0/version` endpoint to verify it's reachable from the app.
- **HTTP mode vs MQTT mode.** HTTP mode is simpler to set up (no MQTT broker needed) but loses MQTT features like QoS and message queuing. MQTT mode is more reliable for intermittent mobile connections.
- **No authentication built-in.** The Recorder's web UI and API have no authentication. Put behind nginx with basic auth (or OAuth2 proxy) before exposing externally.
- **Friends feature.** OwnTracks supports "friends" — seeing other users' locations. Recorder stores friend relationships in LMDB. Configure in the app.
- **Lua hooks.** The Recorder supports Lua scripts triggered on location events — for custom notifications, database writes, or integrations. See `HOOKS.md` in the repo.
- **LMDB files can corrupt.** LMDB is generally safe but corruption is possible after unclean shutdown. Back up the `store/` directory regularly; LMDB includes recovery tools.
- **TLS for MQTT.** If OwnTracks app is connecting from the internet, use MQTT over TLS (port 8883). Configure Mosquitto with TLS certificates.

## Backup

```sh
docker compose stop recorder
sudo tar czf owntracks-$(date +%F).tgz store/
docker compose start recorder
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active C development, Docker Hub, APT packages, iOS + Android app, extensive docs (booklet), REST API, `ocat` CLI, Lua hooks, GeoJSON, WebSocket live map. OwnTracks team. MIT license.

## Location-tracking-family comparison

- **OwnTracks Recorder** — C, plain-file storage, MQTT+HTTP, live map, GeoJSON, `ocat`, MIT
- **Traccar** — Java, 200+ GPS protocols (not just OwnTracks), PostgreSQL, web UI, more complex
- **Dawarich** — Ruby, imports from Google Maps / OwnTracks, trip detection, beautiful UI
- **GPSLogger** — Android app only; logs to various backends; no web server
- **µTrack** — minimalist; similar but smaller project

**Choose OwnTracks Recorder if:** you use the OwnTracks iOS/Android apps and want a lightweight self-hosted backend for storing and visualizing your location history.

## Links

- Repo: <https://github.com/owntracks/recorder>
- Docs: <https://owntracks.org/booklet/clients/recorder/>
- Docker Hub: <https://hub.docker.com/r/owntracks/recorder>
- OwnTracks iOS: <https://apps.apple.com/app/owntracks/id692424691>
- OwnTracks Android: <https://play.google.com/store/apps/details?id=org.owntracks.android>
