---
name: Gladys Assistant
description: "Privacy-first open-source smart home assistant. Node.js + SQLite, Docker-first, runs locally on Pi/NAS/mini-PC. Zigbee/Z-Wave/MQTT integrations. Apache-2.0 (verify). Active; large community + docs + paid cloud backup service."
---

# Gladys Assistant

Gladys Assistant is **"Home Assistant / OpenHAB — but simpler + privacy-focused"** — a smart-home-automation platform that runs on Raspberry Pi, NAS, or mini-PC. Local-first: your voice, device states, and automations never leave your house (unless you opt in to Gladys Plus, the optional paid cloud-relay + backup service). Integrates Zigbee, Z-Wave, MQTT, Ewelink, Nest, Netatmo, Philips Hue, TP-Link, Xiaomi, cameras, sensors. Voice-assistant via Gladys Voice with local speech processing.

Built + maintained by **Pierre-Gilles Leymarie (Pierre-Gilles on GitHub) + Gladys Assistant org + community**. License: Apache-2.0 (verify LICENSE file). Active; docs site + Discord + Plus paid SaaS tier + hardware-store + Raspberry Pi OS image.

Use cases: (a) **Home-Assistant-curious but finds HA too complex** — Gladys is simpler + more opinionated (b) **French-speaking users** — Gladys's origin is French; localization + docs are excellent in French (c) **privacy-first smart-home** — no Amazon/Google/Apple cloud for voice + automation (d) **Pi/NAS homelab** — single-container install (e) **voice-first smart-home** with local speech (f) **small-house automation** — lights + HVAC + security + presence-detection (g) **Ewelink / SONOFF ecosystem** — Gladys has first-class Ewelink support (h) **paying for cloud-relay without giving data to Big-Tech** — Gladys Plus is privacy-aligned.

Features (from upstream README + docs):

- **Privacy-first** — local-only except opt-in Plus service
- **Smart home integrations** — Zigbee, Z-Wave, MQTT, many brand-specific integrations
- **Voice assistant** — Gladys Voice with local speech
- **Automation engine** — scenes + rules + scheduling
- **Mobile apps** — iOS + Android
- **Multi-platform** — Pi / NAS / mini-PC / Docker
- **Plus subscription** (optional) — cloud relay + backups + remote access + weather + voice-to-text
- **OTA updates** for Zigbee + Z-Wave devices

- Upstream repo: <https://github.com/GladysAssistant/Gladys>
- Website: <https://gladysassistant.com>
- Docs: <https://gladysassistant.com/docs/>
- Plus service: <https://gladysassistant.com/plus/>
- Docker Compose guide: <https://gladysassistant.com/docs/installation/docker-compose/>

## Architecture in one minute

- **Node.js** backend + React frontend
- **SQLite** — DB
- **Docker** — primary (with `--network=host` + `--privileged` for USB/Zigbee/Z-Wave)
- **Resource**: moderate — 300-800MB RAM
- **Port 80 default** (container); expose via `SERVER_PORT` env

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker (host-network)** | **`gladysassistant/gladys:v4`**                         | **Primary**                                                                        |
| Docker Compose            | Upstream guide                                           | Alternative                                                                                   |
| Raspberry Pi OS image     | Gladys-preinstalled SD image                             | Easiest for Pi                                                                                   |
| Bare-metal Node           | Dev setup                                                                 | DIY                                                                                               |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Timezone             | `TZ=Europe/Paris`                                           | Config       | Critical for schedules                                                                                    |
| DB path              | `/var/lib/gladysassistant/gladys-production.db`             | Storage      | Mount to host                                                                                    |
| USB device access    | Zigbee/Z-Wave dongles (`/dev/ttyUSB0`, `/dev/ttyACM0`)      | Hardware     | `--privileged` + `/dev:/dev` mount                                                                                    |
| Docker socket mount  | For OTA + container management                                                                          | Optional     | Required for update-via-container feature                                                                                    |
| Admin creds          | First-boot signup                                                                                 | Bootstrap    | Strong                                                                                    |
| Integration creds    | Per-service (Nest API, Hue bridge key, MQTT broker, etc.)                                                                                 | Integration  | **Accumulates fast**                                                                                                            |

## Install via Docker

```sh
sudo docker run -d \
  --log-driver json-file --log-opt max-size=10m \
  --cgroupns=host --restart=always --privileged --network=host \
  --name gladys \
  -e NODE_ENV=production -e SERVER_PORT=80 -e TZ=Europe/Paris \
  -e SQLITE_FILE_PATH=/var/lib/gladysassistant/gladys-production.db \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/gladysassistant:/var/lib/gladysassistant \
  -v /dev:/dev \
  -v /run/udev:/run/udev:ro \
  gladysassistant/gladys:v4        # **pin to specific version tag in prod, not `v4`**
```

## First boot

1. Start → browse `http://host/` (port 80)
2. Register admin account (first-boot)
3. Add a house + rooms
4. Add first integration (e.g., MQTT broker, Philips Hue bridge, Zigbee dongle)
5. Discover devices + bind to rooms
6. Create first scene / automation
7. Install mobile app; pair with server
8. (Optional) Subscribe to Gladys Plus for remote access
9. Back up the SQLite DB
10. Plan update strategy

## Data & config layout

- `/var/lib/gladysassistant/gladys-production.db` — SQLite; all state
- Docker socket mount — for self-update features
- `/dev` mount — USB Zigbee/Z-Wave dongles

## Backup

```sh
sudo cp /var/lib/gladysassistant/gladys-production.db "gladys-$(date +%F).db"
# Or use Gladys Plus backup (paid cloud feature)
```

## Upgrade

1. Releases: <https://github.com/GladysAssistant/Gladys/releases>. Active; frequent releases.
2. Docker: pull + restart — migrations auto-run
3. **Back up DB before major version bumps** (v3→v4 was breaking)
4. Gladys Plus users get additional backup-based rollback

## Gotchas

- **HUB-OF-CREDENTIALS TIER 2 + HOME-CONTROL-RISK**:
  - Integration credentials for every connected service (Nest, Hue, Netatmo, TP-Link, Ewelink, MQTT, etc.)
  - Home-presence data (who's home, when)
  - Camera access (if integrated)
  - HVAC + lock + alarm control (potentially)
  - **54th tool in hub-of-credentials family — Tier 2 + "home-control-risk" sub-category**
  - **Compromise impact**: attacker can turn off alarm, unlock doors (if smart-lock integrated), see when home is empty, control HVAC (cold-attack-freeze-pipes / hot-attack-fire-risk)
  - **Compare to Viseron 99 PHYSICAL-SECURITY-CROWN-JEWEL**: Gladys is adjacent but differs — Viseron is passive surveillance; Gladys is active-control + sometimes surveillance
  - **Recipe convention: "home-control-risk sub-category"** of hub-of-credentials — distinguishable from PHYSICAL-SECURITY-CROWN-JEWEL. Applicable to Home Assistant, OpenHAB, Domoticz, Gladys. **1st tool in home-control-risk sub-category.**
- **DOCKER SOCKET MOUNT = FULL HOST ACCESS**:
  - `/var/run/docker.sock` → container can start/stop/create/delete any container on host, including privileged ones
  - **Equivalent to root on the host**
  - Gladys needs this for OTA self-update feature; alternatively disable the feature + remove the socket mount
  - **Recipe convention: "docker-socket-mount = host-root" callout** — applicable to all tools that mount `/var/run/docker.sock` (Portainer, Watchtower, Dokku-style tools). **Flag explicitly as privilege-escalation-vector.**
  - **NEW family: "docker-socket-mount-privilege-escalation"** — 1st tool named (Gladys); retroactively: Portainer, Watchtower, Traefik-with-docker-provider, Dokku-install-on-host, many more.
- **--privileged + --network=host = BIG SECURITY SACRIFICES for HW integration**:
  - `--privileged` = container has nearly-full kernel capability
  - `--network=host` = container shares host network stack
  - **Both are necessary for USB-device access + mDNS discovery** but weaken isolation
  - Only run trusted image; pin version; don't mix with other services on same Docker host
- **PLUS (PAID CLOUD) TIER = COMMERCIAL-TIER**:
  - Gladys Plus (~$10-12/mo) provides remote-access-relay + backups + voice-to-text + weather
  - Opt-in — local-only works without Plus
  - **Commercial-tier-taxonomy: "companion-paid-SaaS for privacy-respecting features"** — aligned with maintainer's ethics; funds development
  - **NEW sub-category of commercial-tier**: "aligned-optional-paid-SaaS-for-convenience" (as opposed to "feature-gating-OSS-to-sell-Enterprise-tier" pattern seen elsewhere)
- **INTEGRATION CREDENTIALS = DIVERSITY-OF-TRUST-STACKS**:
  - Each smart-home integration has its own cloud API (Nest = Google, Hue = Philips, Xiaomi, TP-Link, etc.)
  - Each has its own auth scheme + revocation flow
  - Compromise of integration credentials = compromise of that brand's cloud account (potentially more valuable than just Gladys)
- **VOICE DATA = POTENTIALLY PRIVATE CONVERSATIONS**: Gladys Voice with local processing keeps voice data local; Plus cloud-voice-to-text = data leaves house. Users should understand the distinction.
- **LOCAL-FIRST = RESILIENT TO INTERNET OUTAGES**: automation continues working; home doesn't "brick" during outage — significant reliability advantage over pure-cloud smart-home platforms (e.g., Amazon Alexa routines broke Dec 2023 outage).
- **UPDATE STRATEGY**: `gladysassistant/gladys:v4` is a floating tag. Prefer pinning to specific version for reliability; use Gladys's in-app update flow once you're confident.
- **FRENCH-ORIGIN + BILINGUAL COMMUNITY**: docs excellent in French + good-but-varying in English. French-speaking users get best experience.
- **TRANSPARENT-MAINTENANCE**: active + docs + Plus SaaS + hardware-store + Discord + commit-frequency + localization. **46th tool in transparent-maintenance family.**
- **INSTITUTIONAL-STEWARDSHIP**: Pierre-Gilles Leymarie + Gladys Assistant org + Plus commercial tier funding development + community. **39th tool in institutional-stewardship — founder-with-commercial-tier-funded-development sub-tier** (joins: Umami, Cal.com, Ghost, Chatwoot, etc.) — (**NEW: 8th+ sub-tier?**). Actually, founder-with-commercial-tier is well-represented — count as existing sub-tier.
- **LICENSE CHECK**: README links to LICENSE; should be Apache-2.0 (common for JS projects of this shape; verify).
- **SMART-HOME CATEGORY (crowded):**
  - **Home Assistant** — largest community; Python; more complex but more-integrations
  - **OpenHAB** — Java; enterprise-ish
  - **Domoticz** — C++; mature; lower-resource
  - **ioBroker** — Node.js; similar shape to Gladys
  - **Gladys** — Node.js; simpler; French-origin; Plus paid tier
  - **SmartThings / Hubitat** — commercial hubs (Samsung/Hubitat)
  - **Alexa / Google Home / Apple HomeKit** — commercial cloud (vs Gladys's local-first philosophy)
- **ALTERNATIVES WORTH KNOWING:**
  - **Home Assistant** — if you want max-integrations + large community + can handle complexity
  - **OpenHAB** — if you want Java enterprise shape
  - **ioBroker** — if you want Node.js similar-to-Gladys but different community
  - **Domoticz** — if you want lowest-resource C++
  - **Choose Gladys if:** you want SIMPLICITY + privacy + local-first + French-friendly + Plus-paid-tier-aligned-ethics.
  - **Choose Home Assistant if:** you want MAXIMUM integrations + HA ecosystem (HACS addons, etc.).
- **PROJECT HEALTH**: active + docs + Plus commercial funding + hardware-store + community + localization + mobile apps. Strong signals.

## Links

- Repo: <https://github.com/GladysAssistant/Gladys>
- Website: <https://gladysassistant.com>
- Docs: <https://gladysassistant.com/docs/>
- Plus service: <https://gladysassistant.com/plus/>
- Docker Compose guide: <https://gladysassistant.com/docs/installation/docker-compose/>
- Home Assistant (alt): <https://www.home-assistant.io>
- OpenHAB (alt): <https://www.openhab.org>
- Domoticz (alt): <https://www.domoticz.com>
- ioBroker (alt): <https://www.iobroker.net>
