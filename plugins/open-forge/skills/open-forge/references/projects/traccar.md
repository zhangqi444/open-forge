---
name: Traccar
description: "Open-source GPS tracking server — back-end for 2000+ GPS tracker models, 200+ protocols. Real-time tracking, geofencing, routes, reports, alerts. Java back-end + web app + mobile apps. Works with phones, fleet trackers, vehicle OBD dongles. Apache-2.0."
---

# Traccar

Traccar is **the** open-source GPS tracking server — a Java daemon that speaks **200+ tracker protocols** and works with **2000+ GPS device models** (personal trackers, fleet telematics, OBD dongles, phones). Your trackers (or smartphones) push location to Traccar; Traccar stores it in SQL and exposes a real-time web UI + REST API + mobile apps.

Use cases:

- **Fleet management** — track company vehicles, driver behavior, fuel
- **Personal tracking** — car, bike, boat, kids' phones
- **Asset tracking** — valuable equipment with GPS tags
- **Phone tracking** — family location sharing (Traccar Client app)
- **Hobbyist** — drone flights, hiking, etc.

Features:

- **Protocols** — 200+ (Teltonika, Queclink, Meitrack, OsmAnd, H02, GT06, TK103, and many more)
- **Real-time map** — live positions + trails
- **Geofences** — polygons + circles; entry/exit alerts
- **Routes / trips** — auto-detected start/stop
- **Reports** — summary, trips, stops, events, fuel, maintenance
- **Driver behavior** — speeding, harsh braking/accel (protocol-dependent)
- **Alerts** — SMS, email, push, webhook
- **User + group management**, multi-tenant
- **Multi-language** (50+ translations)
- **Mobile apps** — Android + iOS "Traccar Client" (phone → server)
- **Admin app** — Traccar Manager (for admins)
- **Free / self-host / Apache-2.0**. Separate **Traccar Cloud** (hosted tier, paid) funds development.

- Upstream repo (server): <https://github.com/traccar/traccar>
- Web app: <https://github.com/traccar/traccar-web>
- Manager app: <https://github.com/traccar/traccar-manager>
- Client app: <https://github.com/traccar/traccar-client>
- Website: <https://www.traccar.org>
- Docs: <https://www.traccar.org/documentation/>
- API docs: <https://www.traccar.org/traccar-api/>
- Forum: <https://www.traccar.org/forums/>

## Architecture in one minute

- **Java 17+** (runs on JRE); single JAR with bundled Jetty web server
- **DB**: H2 (default, embedded), MySQL, MariaDB, Postgres, SQL Server
- **Ports**: 8082 web UI; plus 5000-5200+ (one per enabled protocol); trackers push TCP/UDP to those
- **Storage**: positions + events in SQL; web app is static (part of the JAR)
- **Very mature** — 10+ years, widely deployed

## Compatible install methods

| Infra        | Runtime                                                  | Notes                                                              |
| ------------ | -------------------------------------------------------- | ------------------------------------------------------------------ |
| Single VM    | **Upstream installer (Linux/Windows/macOS)** or **Docker**   | **Both are standard**                                                  |
| Docker       | `traccar/traccar` or `jlesage/traccar`                            | Many community images                                                      |
| Raspberry Pi | arm64 install / Docker                                                | Great for personal                                                                 |
| Kubernetes   | Community manifests                                                        | Works                                                                                   |
| Managed      | Traccar Cloud (`www.traccar.org/cloud/`)                                       | Commercial tier                                                                                    |

## Inputs to collect

| Input             | Example                           | Phase      | Notes                                                           |
| ----------------- | --------------------------------- | ---------- | --------------------------------------------------------------- |
| Domain / IP       | `gps.example.com` / public IP           | URL        | **Trackers need a reachable endpoint** (not just your laptop)          |
| Web port          | `8082`                                       | Network    | HTTP UI + API                                                                     |
| Protocol ports    | `5000-5200` range                                    | Network    | Which protocols to enable = which ports to open                                         |
| DB                | MySQL/Postgres recommended for prod                            | DB         | H2 is fine for single-user / testing                                                              |
| Admin account     | `admin/admin` default                                                  | Bootstrap  | **Change immediately**                                                                                  |
| Tracker types     | per your device(s)                                                             | Integration| You'll need the device-specific SMS config to point it at your server                                                          |
| TLS               | Let's Encrypt                                                                         | Security   | For web UI; trackers often use plain TCP (no TLS)                                                                                     |

## Install — Linux / Docker

### Linux native

```sh
wget https://www.traccar.org/download/traccar-linux-64-bit.zip
unzip traccar-linux-64-bit.zip
sudo ./traccar.run
sudo systemctl start traccar
# Web: http://<host>:8082/  (admin/admin; change password now)
```

### Docker

```yaml
services:
  traccar:
    image: traccar/traccar:6.13.3-debian              # pin specific version in prod
    container_name: traccar
    restart: unless-stopped
    ports:
      - "8082:8082"
      # expose protocol ports you're using:
      - "5055:5055"        # OsmAnd / Traccar Client
      - "5027:5027"        # Teltonika
      # ... add others as needed
    volumes:
      - ./data:/opt/traccar/data
      - ./conf/traccar.xml:/opt/traccar/conf/traccar.xml
      - ./logs:/opt/traccar/logs
```

## Config highlights (`conf/traccar.xml`)

```xml
<entry key='database.driver'>org.postgresql.Driver</entry>
<entry key='database.url'>jdbc:postgresql://db:5432/traccar</entry>
<entry key='database.user'>traccar</entry>
<entry key='database.password'>...</entry>

<entry key='web.port'>8082</entry>
<entry key='server.statistics'>false</entry>       <!-- opt out of usage telemetry -->
<entry key='geocoder.enable'>true</entry>
<entry key='geocoder.type'>nominatim</entry>        <!-- reverse-geocode addresses -->
<entry key='geocoder.url'>https://nominatim.openstreetmap.org/reverse</entry>
```

## First boot

1. Browse `http://<host>:8082/` → `admin` / `admin` → **change password immediately**
2. Settings → Server → configure geocoding, map provider, notifications
3. Devices → + Add Device → give it an ID (the "IMEI" or unique ID your tracker sends)
4. Configure your tracker:
   - GPS tracker via SMS: send config SMS pointing at `<host>:<protocol-port>`
   - Phone via Traccar Client app: install → point at `<host>:5055` (OsmAnd protocol) → enter device ID
5. Drive around → positions appear on the map in real time
6. Reports → Trips / Summary / Stops → historical views
7. Geofences → add your home/office → configure alerts

## Tracker configuration

Each GPS tracker has its own SMS config syntax. Upstream documents it per model:

- **Teltonika FM / FMB series**: SMS commands (`  setparam 2001:gps.example.com; setparam 2002:5027`)
- **H02 / GT06 / TK103**: SMS commands from the cheap-tracker manual
- **Phone (Android/iOS)**: install "Traccar Client" → enter URL, device ID, interval

See <https://www.traccar.org/devices/> for per-device config.

## Data & config layout

- `conf/traccar.xml` — main config
- `data/database.mv.db` — H2 DB (default) or external MySQL/Postgres
- `logs/` — tracker connection logs (rotated)
- Web app is bundled into the JAR; no separate frontend dir for basic setups

## Backup

```sh
# DB (CRITICAL — all position history)
# For H2:
cp data/database.mv.db data/backup-$(date +%F).mv.db

# For Postgres:
pg_dump -U traccar traccar | gzip > traccar-$(date +%F).sql.gz

# Config
cp conf/traccar.xml conf-$(date +%F).bak
```

Position data grows linearly with devices × update frequency. 5 devices × 1 update/min = ~2.6M rows/year. Plan DB sizing.

## Upgrade

1. Releases: <https://github.com/traccar/traccar/releases>. Very active (monthly-ish).
2. **Back up DB first.**
3. Linux: stop service → re-run installer → start.
4. Docker: bump tag, pull, up -d. DB migrations run on start.
5. Major version bumps: read release notes; protocol parser updates are routine.

## Gotchas

- **Tracker needs to reach your server** — this is a public-internet-facing workload by design (your fleet GPS isn't on your LAN). Open the right ports; consider a VPS with static IP or Dynamic DNS.
- **Default admin `admin/admin`** — change it immediately. Bots scan for default Traccar.
- **Web UI ≠ tracker protocols** — the UI is on 8082 (HTTPS via reverse proxy), but tracker protocol ports (5000-5200) usually run plain TCP. Most cheap GPS trackers don't support TLS — accept that the tracker→server channel is unencrypted (often mitigated with per-device auth tokens).
- **Device ID collisions** — two trackers with same IMEI/ID will confuse Traccar. Assign unique IDs.
- **H2 database is fine for single-user small setups** but switches slow under concurrent load. Move to Postgres/MySQL for >5 devices or fleet.
- **Geocoding rate limits** — Nominatim (OSM) free tier has usage policy (absolute max 1 req/s). For heavy use, self-host Nominatim or pay for a provider.
- **Map tiles** — Traccar defaults to OSM tiles. For commercial use, self-host tiles or pay a provider (Mapbox, HERE, Carto).
- **Data retention** — by default, Traccar never deletes position history. Configure `database.maxDays` (or whatever the current name is) to prune old positions if disk is tight.
- **Alerts spam** — geofence entry/exit + speeding + idle alerts can flood email/SMS. Tune thresholds and notification schedules.
- **Driver behavior metrics** (harsh braking, acceleration) — protocol-dependent. Cheap trackers just send position; premium fleet devices (Teltonika, Queclink) send CAN-bus + accelerometer data.
- **OBD-II dongles** — cheap ones sometimes come with built-in data plans + SIM; ensure the plan isn't roaming-expensive.
- **Fuel monitoring** — requires CAN-bus-integrated trackers or external fuel-level sensors.
- **Privacy**: you're collecting continuous location on vehicles/people. Follow local laws. GDPR-covered for EU residents.
- **Ownership of data**: self-hosted = your data. Traccar Cloud = your data on Traccar's servers (commercial SaaS).
- **Traccar Manager app** (Android/iOS) — for admins on the go. Less-featured than web.
- **Traccar Client app** — for using a phone as a tracker. Battery-draining at short intervals; tune update interval.
- **License**: Apache-2.0. Great for commercial deployments.
- **Alternatives worth knowing:**
  - **GPSLogger** (Android) — phone-to-server logger; pair with Traccar
  - **OwnTracks** — private MQTT-based location; separate recipe
  - **phpTraccar** — older PHP variant
  - **Gpsd** + custom — very low-level
  - **Haven** (Guardian Project) — different niche (security-sensor)
  - **Life360 / Google Maps location sharing** — commercial alternatives
  - **Choose Traccar if:** you need the most-compatible OSS GPS tracking server + flexibility.
  - **Choose OwnTracks if:** you only need phones + prefer MQTT privacy model.
  - **Choose commercial SaaS if:** you want zero ops.

## Links

- Repo (server): <https://github.com/traccar/traccar>
- Web app: <https://github.com/traccar/traccar-web>
- Manager app: <https://github.com/traccar/traccar-manager>
- Client app: <https://github.com/traccar/traccar-client>
- Website: <https://www.traccar.org>
- Docs: <https://www.traccar.org/documentation/>
- Protocols + devices: <https://www.traccar.org/devices/>
- REST API: <https://www.traccar.org/traccar-api/>
- Forums: <https://www.traccar.org/forums/>
- Build docs: <https://www.traccar.org/build/>
- Releases: <https://github.com/traccar/traccar/releases>
- Traccar Cloud (hosted): <https://www.traccar.org/cloud/>
- Docker Hub: <https://hub.docker.com/r/traccar/traccar>
