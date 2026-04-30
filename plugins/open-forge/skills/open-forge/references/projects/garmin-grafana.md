---
name: Garmin Grafana
description: "Docker container to fetch Garmin health+fitness data and store in InfluxDB for Grafana visualization. Not-affiliated-with-Garmin disclaimer upfront. Unofficial API scraper. Active; sister project for Fitbit. GPL-3.0 license."
---

# Garmin Grafana

Garmin Grafana is **"take your Garmin watch data OUT of Garmin Connect and INTO your own InfluxDB + Grafana dashboard"** — a Docker-packaged tool that logs into Garmin Connect on your behalf, pulls activity + sleep + heart rate + HRV + body battery + stress + steps + calories + hydration + women's health + etc., stores it in a local InfluxDB time-series DB, and renders via a beautiful Grafana dashboard. Important: this is an **UNOFFICIAL** tool; not affiliated with Garmin; uses reverse-engineered Garmin Connect APIs via the `python-garminconnect` library.

Built + maintained by **Arpan Ghosh (arpanghosh8453)** + community. **License: GPL-3.0**. Active; Codeberg mirror; sister-project **fitbit-grafana** for Fitbit users. Docker + Kubernetes Helm chart + Synology guide.

Use cases: (a) **data-ownership** of your fitness history from a commercial platform (b) **advanced visualization** beyond what Garmin Connect offers (customize your own dashboard) (c) **Fitbit-parallel use case** if spouse uses Fitbit — sister project covers them (d) **longitudinal analysis** — compare months + years in one chart (e) **export-to-CSV** for AI insights + advanced stats analysis (f) **escape Garmin Connect's web UI slowness** (g) **monitor trends independently** from Garmin's mobile app notifications (h) **multi-user household** — spouse's watch data alongside yours.

Features (from upstream README):

- **Fetch activity + sleep + HR + HRV + body battery + stress + steps + calories + hydration + women's health + ...** from Garmin Connect
- **InfluxDB** local storage
- **Grafana dashboard** with beautiful preset
- **Historical bulk import**
- **Garmin Connect export-file import** (from Garmin's official data-export tool)
- **Multi-user** (spouse setup)
- **Kubernetes Helm chart**
- **Synology** install guide
- **Automated install script**
- **CSV export** for AI analysis
- **Desktop app** (companion project)
- Codeberg mirror for redundancy

- Upstream repo: <https://github.com/arpanghosh8453/garmin-grafana>
- Codeberg mirror: <https://codeberg.org/arpanghosh8453/garmin-grafana>
- K8s Helm: <https://github.com/arpanghosh8453/garmin-grafana/tree/main/k8s>
- Sister project (Fitbit): <https://github.com/arpanghosh8453/fitbit-grafana>
- python-garminconnect library: <https://github.com/cyberjunky/python-garminconnect>
- Synology guide: <https://github.com/arpanghosh8453/garmin-grafana/discussions/107#discussion-8326104>

## Architecture in one minute

- **Python** — scraper + ingestor
- **python-garminconnect** (third-party lib reverse-engineering Garmin APIs)
- **InfluxDB** — time-series storage
- **Grafana** — visualization
- **Docker compose** — full stack
- **Resource**: moderate — 500MB-1GB RAM (mainly InfluxDB + Grafana)
- **Ports**: Grafana 3000, InfluxDB 8086 (both internal typically)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker compose** | **Upstream-provided; 3 services (scraper + InfluxDB + Grafana)** | **Primary**                                                                   |
| **Automated script** | Beginner-friendly bash installer                                         | For less-technical users                                                                                   |
| Kubernetes Helm    | Upstream-provided chart                                                                                   | For k8s homelab                                                                                               |
| Synology           | Guide for Synology Docker                                                                                               | Popular NAS                                                                                                 |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Garmin Connect email + password | Your Garmin Connect account                      | **CRITICAL** | **THIS IS YOUR GARMIN ACCOUNT**                                                                                    |
| InfluxDB creds       | Set in docker-compose.yml                                   | DB           | Pin strong                                                                                    |
| Grafana admin creds  | Initial admin/admin change-on-first-login                   | Auth         | Change immediately                                                                                    |
| TZ                   | Your timezone for accurate day-rollover                                                                           | Config       | CRITICAL for sleep/activity day-boundaries                                                                                    |
| Historical bulk range | How many days back to fetch                                                                                  | Config       | Affects initial-load time (hours for years of data)                                                                                                            |

## Install via Docker compose (typical)

See upstream README for full compose. Typical services:

```yaml
services:
  garmin-fetch-data:
    image: ghcr.io/arpanghosh8453/garmin-grafana:latest    # **pin version**
    container_name: garmin-fetch-data
    restart: unless-stopped
    environment:
      - INFLUXDB_HOST=influxdb
      - INFLUXDB_USERNAME=...
      - INFLUXDB_PASSWORD=${INFLUXDB_PASSWORD}
      - GARMINCONNECT_EMAIL=${GARMIN_EMAIL}
      - GARMINCONNECT_PASSWORD=${GARMIN_PASSWORD}
      - TZ=UTC
    volumes:
      - ./garmin-tokens:/garmin-fetch-data/.garminconnect

  influxdb:
    image: influxdb:1.8
    volumes: [./influxdb-data:/var/lib/influxdb]

  grafana:
    image: grafana/grafana:latest
    ports: ["3000:3000"]
    volumes: [./grafana-data:/var/lib/grafana]
```

## First boot

1. Edit `.env` with Garmin credentials
2. `docker compose up -d`
3. Monitor logs: first run triggers MFA challenge if Garmin 2FA enabled
4. Wait for initial backfill (can take hours for years of data)
5. Browse Grafana at `:3000`; change default admin password
6. Verify data visible; explore panels
7. (Optional) run historical bulk-fetch
8. Put behind TLS reverse proxy + auth (don't expose InfluxDB publicly)
9. Back up InfluxDB + Grafana DB + Garmin token cache

## Data & config layout

- `garmin-tokens/` — cached Garmin Connect session tokens (**sensitive!**)
- InfluxDB volume — all scraped data
- Grafana volume — dashboard config + SQLite DB + users

## Backup

```sh
# InfluxDB 1.x:
docker compose exec influxdb influxd backup -portable /tmp/backup
# Grafana:
sudo tar czf grafana-$(date +%F).tgz grafana-data/
# Garmin tokens
sudo tar czf garmin-tokens-$(date +%F).tgz garmin-tokens/
```

## Upgrade

1. Releases: <https://github.com/arpanghosh8453/garmin-grafana/releases>. Active.
2. Docker: pull + restart.
3. InfluxDB major upgrades need migration (1.x → 2.x → 3.x).
4. **Garmin API changes can BREAK the tool overnight** — watch for emergency updates.

## Gotchas

- **UNOFFICIAL GARMIN API SCRAPER = FRAGILE**:
  - Uses reverse-engineered Garmin Connect APIs via `python-garminconnect` library
  - **Garmin can change APIs anytime** → breaks scraping
  - **Garmin has rate-limits + may throttle/ban accounts doing "robot-like" scraping**
  - **Historical concern**: Garmin has sent C&D to similar scrapers (rare but happens)
  - **Legal gray area** — Garmin ToS may prohibit automated scraping; "personal use" argument vs ToS
  - **21st tool in network-service-legal-risk family — API-TOS-platform-enforcement** joining Mixpost 97 (commercial-social-platform-API-dependency). **Distinct sub-family "commercial-platform-unofficial-API-scraper-risk"** — 12th sub-family. Applicable to: Garmin-Grafana, fitbit-grafana, any-social-media-scraper, home-assistant-integrations-that-scrape, etc.
- **UPSTREAM'S EXPLICIT "NOT-AFFILIATED" DISCLAIMER** at top of README: positive signal (transparent about status); also legal-protection for maintainer. Recipe convention: highlight this disclaimer for end users so they understand they're using a neutral tool, not an official Garmin integration.
- **2FA / MFA COMPLICATION**:
  - If Garmin account has 2FA enabled (recommended), first run requires interactive MFA code entry
  - Subsequent runs use cached session tokens
  - Lost tokens = re-auth required
- **HUB-OF-CREDENTIALS TIER 2 - HEALTHCARE-CROWN-JEWEL overlap**:
  - **Garmin Connect email + password (or token)** — grants full access to account history + ability to impersonate
  - **InfluxDB creds**
  - **Grafana admin creds**
  - **ALL your health data**: HRV, sleep patterns, menstrual cycle tracking (women's health), location (activity GPX), heart rate, weight, etc.
  - **55th tool in hub-of-credentials family — HEALTHCARE-CROWN-JEWEL sub-family (2nd tool)** joining SparkyFitness 94
  - Reinforces **post-Dobbs reproductive-data risk** (menstrual tracking) — legal-adversary threat model
  - Reinforces **DV-threat-model** — partner access to fitness + location data = safety concern
- **REGULATORY-CROWN-JEWEL HEALTHCARE sub-family now 2 tools**: SparkyFitness 94 + Garmin-Grafana 98. Family-doc at batch 100: note that health-data tools face specific regulatory scrutiny (HIPAA-US, GDPR-Art-9-EU special-category).
- **LOCATION DATA + GPX EXPORTS**: activity data includes GPX (every run/ride/walk with precise coordinates). **Location-history-sensitivity**: stalking risk, habit-profiling, home-address-revelation (start-point of morning runs = your house). Treat with care; minimize exposed instances.
- **GARMIN-CONNECT-PASSWORD-IN-ENV**: credentials stored in `.env` file. Secure the file perms (0600); don't commit to git; use Docker secrets in production.
- **INFLUXDB 1.x vs 2.x vs 3.x**: Garmin-Grafana typically uses InfluxDB 1.x (mature, well-documented). InfluxDB 3.x is a complete rewrite. Upgrades non-trivial. **Recipe convention: flag when a tool pins to a specific DB major version that's been superseded** — because upgrading the underlying DB requires coordination with the wrapper tool.
- **32nd tool in immutability-of-secrets family** — InfluxDB admin password + Grafana admin creds typical immutability zones.
- **MULTI-USER**: each user = separate scraper container + separate Garmin credentials. Doesn't share DB write path risky — follow upstream multi-user guide.
- **SISTER PROJECT (FITBIT)** — arpanghosh8453/fitbit-grafana applies same architecture to Fitbit. For mixed-household (Garmin + Fitbit), run both. **Pattern: "personal-data-from-commercial-wearable-to-self-host" category** — emerging. Applicable to: Garmin, Fitbit, Oura (oura-api-to-grafana patterns), Apple Watch (harder, HealthKit-export-based).
- **CODEBERG MIRROR** = supply-chain backup; smart for a scraper whose hosted location matters for availability.
- **TRANSPARENT-MAINTENANCE**: GPL-3 + active + Codeberg-mirror + sister-project + docs + automated installer + multi-user guide + K8s chart + Synology guide + CSV export + explicit disclaimer. **37th tool in transparent-maintenance family.** Strong multi-dimensional transparency.
- **INSTITUTIONAL-STEWARDSHIP**: Arpan Ghosh + contributors + dependency on python-garminconnect (maintained by cyberjunky). **30th tool in institutional-stewardship — sole-maintainer-with-community-and-critical-dependency sub-tier** (the tool is effectively TWO tools: Arpan's wrapper + cyberjunky's Garmin library). If either stops, the whole thing breaks. **NEW sub-tier: "dependent-on-key-third-party-library"** worth naming.
- **SOLE-MAINTAINER with 2-person core-dependency**: Arpan + cyberjunky's python-garminconnect. If Garmin changes API + cyberjunky doesn't update → Arpan can fork python-garminconnect (GPL would allow) but it's non-trivial. Pattern-worthy.
- **GPL-3.0**: source disclosure; fine for self-host; not for commercial-SaaS-redistribution.
- **ALTERNATIVES WORTH KNOWING:**
  - **Home Assistant Garmin integration** — some community integrations exist
  - **Strava** — commercial-SaaS alternative that imports-from-Garmin (less privacy)
  - **Apple Health export + Grafana** — manual / iOS-side workflow
  - **WellYou** — self-host fitness-dashboard
  - **Fittrackee** — self-host fitness-tracking (user submits activities)
  - **SparkyFitness 94** — self-host fitness-tracking (broader)
  - **Ryot 95** — self-host life-tracking (even broader; includes fitness)
  - **Choose Garmin-Grafana if:** you have Garmin + want automatic sync + Grafana visualization + multi-user household.
  - **Choose Ryot if:** you want manual-logging multi-domain lifelog.
  - **Choose Strava if:** you accept commercial + want athlete community.
- **PROJECT HEALTH**: active + GPL-3 + sister-project + K8s + multi-install-paths + Codeberg-mirror + explicit-disclaimer. Strong signals for a fragile-API-dependent tool.

## Links

- Repo: <https://github.com/arpanghosh8453/garmin-grafana>
- Codeberg: <https://codeberg.org/arpanghosh8453/garmin-grafana>
- K8s: <https://github.com/arpanghosh8453/garmin-grafana/tree/main/k8s>
- Fitbit sister: <https://github.com/arpanghosh8453/fitbit-grafana>
- python-garminconnect: <https://github.com/cyberjunky/python-garminconnect>
- Grafana: <https://grafana.com>
- InfluxDB: <https://www.influxdata.com>
- Garmin Connect: <https://connect.garmin.com>
- SparkyFitness (broader alt): <https://github.com/CodeWithCJ/SparkyFitness>
- Ryot (broader alt): <https://github.com/IgnisDa/ryot>
