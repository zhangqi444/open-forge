---
name: TeslaMate
description: "Self-hosted data logger + dashboards for Tesla vehicles. Drives, charges, battery health, efficiency, geo-fences, addresses, cost tracking. Elixir backend + Postgres + MQTT + Grafana. Official Tesla API auth (Tesla Fleet API). AGPL-3.0."
---

# TeslaMate

TeslaMate is **the** self-hosted data logger for Tesla owners. It talks to the Tesla API, polls your car at smart intervals (without preventing sleep → **no extra vampire drain**), and stores every drive, charge, and parked state in Postgres. Beautiful Grafana dashboards answer every question you'd ever ask: efficiency vs temperature, degradation over time, cost per kWh at home vs Supercharger, which Supercharger is closest to your route, etc.

> **SECURITY WARNING (from upstream):** Use **only** the official repo at <https://github.com/teslamate-org/teslamate>. **Deceptive websites + fake App Store apps exist that steal Tesla credentials.** Don't install "TeslaMate" from anywhere else. If you used a fork/app from elsewhere, rotate Tesla account password + any API tokens immediately.

> **Tesla API access change:** Since late 2023, Tesla requires **Fleet API** with developer registration + app approval for new owners. TeslaMate documents the process; it's more involved than it used to be.

Features:

- **High-precision drive recording** — time, distance, Wh/km, route, start/end addresses (reverse-geocoded)
- **Charge tracking** — location, start/end SoC, kWh added, $ cost, cost-per-kWh
- **Battery health** — projected capacity, degradation over time
- **No vampire drain** — allows car to sleep; resumes polling on wake events
- **Geo-fences** — label "Home" / "Work" / "Grandma's house"
- **Home Assistant integration** via MQTT (all car data as entities)
- **Multi-vehicle** — track several Teslas under one account
- **Imports** from TeslaFi, tesla-apiscraper
- **Dashboards** (Grafana): Battery Health, Charge Level, Drive Stats, Efficiency, Projected Range, Trip View, Locations, Supercharger Map, Timeline
- **Theme** — light/dark/system

- Upstream repo: <https://github.com/teslamate-org/teslamate>
- Docs: <https://docs.teslamate.org>
- Docker Hub: <https://hub.docker.com/r/teslamate/teslamate>
- Discord: <https://discord.gg/teslamate>

## Architecture in one minute

- **TeslaMate server** (Elixir) — talks to Tesla API, persists drives/charges to Postgres, publishes MQTT
- **Postgres** (with PostGIS extension) — geo-aware drive/charge storage
- **MQTT broker** (Mosquitto) — real-time data for Home Assistant, apps, webhooks
- **Grafana** — dashboards (pre-provisioned)
- All 4 run as Docker containers

## Compatible install methods

| Infra       | Runtime                                              | Notes                                                             |
| ----------- | ---------------------------------------------------- | ----------------------------------------------------------------- |
| Single VM   | **Docker Compose** (upstream-provided)                  | **The way** — 4-container stack                                        |
| Raspberry Pi | arm64 Docker                                                | Works on Pi 4+ (Pi 3 is tight)                                          |
| Synology/Unraid| Community apps                                                  | Common                                                                        |
| Kubernetes  | Community manifests / Helm                                         | Straightforward                                                                       |
| **SaaS**    | — (TeslaMate is self-host only; there is no hosted edition)                     |                                                                                             |

## Inputs to collect

| Input              | Example                         | Phase     | Notes                                                              |
| ------------------ | ------------------------------- | --------- | ------------------------------------------------------------------ |
| Domain             | `tesla.example.com`               | URL       | Reverse proxy with TLS; **must** be TLS for MFA auth                   |
| Postgres           | user/pass/db                           | DB        | Inside Docker                                                                        |
| MQTT broker        | bundled Mosquitto                        | MQTT      | Unless you have your own broker                                                              |
| Tesla API auth     | Fleet API app + refresh token                | Auth      | Follow upstream Tesla API guide; involves Tesla dev portal                                      |
| Virtual key (opt)  | signed command support (for commands)              | Advanced  | Required for "lock doors / honk horn" remote commands from TeslaMate                                 |
| Grafana admin pass | set via env                                             | UI        | Change default!                                                                                           |
| Geocode provider   | OSM Nominatim (default) / GraphHopper / HERE                | Geo       | Free tiers available                                                                                             |
| Timezone           | `America/Los_Angeles`                                           | Locale    | Affects dashboard timestamps                                                                                                |

## Install via Docker Compose

Upstream provides a canonical compose; the outline:

```yaml
services:
  teslamate:
    image: teslamate/teslamate:3.0.0                # pin specific version
    restart: unless-stopped
    depends_on: [db, mosquitto]
    environment:
      ENCRYPTION_KEY: <32-random-chars>
      DATABASE_USER: teslamate
      DATABASE_PASS: <strong>
      DATABASE_NAME: teslamate
      DATABASE_HOST: db
      MQTT_HOST: mosquitto
      VIRTUAL_HOST: tesla.example.com
      CHECK_ORIGIN: "true"
      TZ: America/Los_Angeles
    ports:
      - "4000:4000"
    volumes:
      - ./import:/opt/app/import

  db:
    image: postgres:16
    restart: unless-stopped
    environment:
      POSTGRES_USER: teslamate
      POSTGRES_PASSWORD: <strong>
      POSTGRES_DB: teslamate
    volumes:
      - teslamate-db:/var/lib/postgresql/data

  grafana:
    image: teslamate/grafana:3.0.0                   # custom image with dashboards pre-provisioned
    restart: unless-stopped
    depends_on: [db]
    environment:
      DATABASE_USER: teslamate
      DATABASE_PASS: <strong>
      DATABASE_NAME: teslamate
      DATABASE_HOST: db
    ports:
      - "3000:3000"
    volumes:
      - teslamate-grafana:/var/lib/grafana

  mosquitto:
    image: eclipse-mosquitto:2
    restart: unless-stopped
    command: mosquitto -c /mosquitto-no-auth.conf
    ports:
      - "1883:1883"
    volumes:
      - mosquitto-conf:/mosquitto/config
      - mosquitto-data:/mosquitto/data

volumes:
  teslamate-db:
  teslamate-grafana:
  mosquitto-conf:
  mosquitto-data:
```

Front with Caddy/Traefik + basic auth (TeslaMate itself has NO auth — see gotcha below).

## First boot

1. Browse `https://tesla.example.com` (behind your proxy + basic auth)
2. TeslaMate prompts for Tesla API refresh token. Follow the **Tesla API setup** guide in upstream docs to obtain one via Fleet API.
3. Tesla account logged in → select vehicle(s) → polling starts
4. Go to Grafana (`port 3000` or `/grafana/` behind proxy) → log in as `admin` → see live dashboards
5. Create **Geo-Fences**: Settings → Geo-Fences → add "Home" (your home address, 50 m radius)
6. Optional: set cost-per-kWh for Home charging → accurate cost tracking

## Data & config layout

- Postgres volume — all drives, charges, positions, addresses, geo-fences, vehicle metadata
- Grafana volume — customized/user-created dashboards
- Mosquitto volume — MQTT state (minimal)
- `import/` — CSV import staging

## Backup

```sh
# DB (CRITICAL — years of driving data)
docker exec teslamate-db pg_dump -U teslamate teslamate | gzip > teslamate-$(date +%F).sql.gz

# Grafana (dashboards)
docker cp teslamate-grafana:/var/lib/grafana ./grafana-$(date +%F)
```

## Upgrade

1. Releases: <https://github.com/teslamate-org/teslamate/releases>. Active; frequent.
2. **Back up DB first** — most releases include DB migrations.
3. Bump image tags → `docker compose pull && docker compose up -d`. Migrations run automatically on boot.
4. Grafana dashboards update with TeslaMate images (they ship together).
5. Read release notes for breaking env / auth changes (especially around Tesla API).

## Gotchas

- **Security warning (from upstream README): only use official releases.** Don't install TeslaMate via unknown app stores or forks — malicious forks have been reported that steal Tesla creds. If in doubt, rotate your Tesla account password.
- **TeslaMate has no built-in auth.** **You MUST put it behind a reverse proxy with authentication** (basic auth, OIDC, Authelia, Authentik, Tailscale). Exposing port 4000 to the public internet = anyone can see your car's live location + history.
- **Tesla Fleet API onboarding** (since late 2023): new owners must register a developer app with Tesla, go through Tesla's approval, and generate a Fleet API refresh token. Older token flows are deprecated. Follow upstream's current API guide — it changes.
- **Vampire drain**: TeslaMate is smart about sleep — it stops polling aggressively when the car is parked so the car's computer can sleep. If you notice extra drain after install, check upstream guidance on "sleep settings" + verify `suspend_min`/`suspend_after_idle_min`.
- **Reverse geocoding** uses public Nominatim (OSM) by default — rate-limited. For heavy use, self-host Nominatim or switch to GraphHopper / HERE (paid).
- **MQTT is not encrypted by default** in the provided compose. If exposing MQTT, configure TLS + auth. For local-only, fine.
- **Home Assistant integration** via MQTT — TeslaMate publishes topics; HA auto-discovery is supported. Don't run competing Tesla integrations at the same time (they fight over polling).
- **Multi-user Grafana**: by default Grafana admin is a single account. Add users in Grafana settings.
- **Virtual key** (signed commands): to send commands from TeslaMate → car (lock, honk, flash lights), enroll TeslaMate's public key in your car. Tesla's newer security model requires this.
- **Charge cost accuracy**: set per-location cost (home kWh rate, work rate 0, Supercharger market rate). TeslaMate can pull Supercharger rates but it's approximate — verify.
- **Battery health** dashboard: takes weeks of data to stabilize. Early readings can look alarming; don't panic.
- **Import from TeslaFi / tesla-apiscraper**: supported via CSV; follow docs.
- **Privacy: TeslaMate stores GPS breadcrumbs** for every drive. This is extremely sensitive data. Host it on your own network, TLS + auth, and think before sharing screenshots of maps.
- **Multi-vehicle**: same Tesla account can have multiple cars; TeslaMate polls all of them.
- **Shared car (spouse)**: if multiple people drive one car, TeslaMate doesn't distinguish drivers. You get "the car's drives," not "who drove."
- **Timezones**: DB stores UTC; Grafana displays per your setting; drift causes "off-by-hour" confusion. Set `TZ` env + Grafana browser tz consistently.
- **Internet required**: TeslaMate polls Tesla's API over the internet. No internet = no data (car continues driving; just no log).
- **License**: AGPL-3.0. Modifications that you host publicly must be released.
- **AI-slop PRs banned** (like many AGPL projects, upstream maintainers push back on low-quality AI-generated PRs).
- **Alternatives worth knowing:**
  - **TeslaFi** — commercial SaaS with similar dashboards, no self-host
  - **Tessie** — commercial SaaS with broader features, mobile-first
  - **tesla-apiscraper** — Grafana-based precursor; TeslaMate is the successor
  - **tesla-android** / **tesla-ios**: unofficial phone apps (not related to TeslaMate)
  - **Home Assistant + native Tesla integration** — simpler; no long-term history storage
  - **Choose TeslaMate if:** you own a Tesla and want exhaustive, private, Grafana-dashboarded data ownership.
  - **Choose TeslaFi if:** you don't want to self-host; willing to give a third party your Tesla access.
  - **Choose Home Assistant Tesla integration if:** you just want current-state HA automation, not long-term analytics.

## Links

- Repo: <https://github.com/teslamate-org/teslamate>
- Docs: <https://docs.teslamate.org>
- Install: <https://docs.teslamate.org/docs/installation/docker>
- Tesla API setup: <https://docs.teslamate.org/docs/configuration/tokens>
- Docker Hub: <https://hub.docker.com/r/teslamate/teslamate>
- Grafana image: <https://hub.docker.com/r/teslamate/grafana>
- Dashboards screenshots: <https://docs.teslamate.org/docs/screenshots>
- Releases: <https://github.com/teslamate-org/teslamate/releases>
- Discord: <https://discord.gg/teslamate>
- Home Assistant MQTT integration guide: <https://docs.teslamate.org/docs/integrations/MQTT>
- Virtual key / signed commands: <https://docs.teslamate.org/docs/configuration/commands>
- Project alternatives comparison: <https://docs.teslamate.org> (FAQ)
