---
name: Obico
description: "Smart 3D printing platform with AI failure detection. OctoPrint/Klipper plugin + self-hosted server. Deep Learning model. TheSpaghettiDetective/obico-server (formerly Spaghetti Detective). Docker Compose. obico.io community."
---

# Obico

Obico is **"AI watching your 3D printer 24/7 — pause on failure detection"** — a community-built OSS smart 3D printing platform. **Deep-learning model** detects print failures (spaghetti, warping, layer issues) from webcam feeds. Plugins for OctoPrint + Klipper connect to your self-hosted Obico server.

Built + maintained by **TheSpaghettiDetective** → renamed to **Obico**. obico.io community. Docker Compose deploy. Formerly commercial-only, now self-hostable.

Use cases: (a) **AI failure-detection for 3D prints** — auto-pause (b) **remote-monitoring 3D printer farm** (c) **time-lapse with failure overlay** (d) **OctoPrint + Klipper fleet management** (e) **notification when print fails / completes** (f) **privacy-preserving AI** (not cloud) (g) **JusPrin integration** (separate project) (h) **GPU-accelerated detection** (optional Nvidia).

Features (per README):

- **Smart failure-detection** via Deep Learning
- **OctoPrint + Klipper plugins**
- **Nvidia GPU optional** (faster + more printers)
- **Docker Compose** deploy
- **Self-hosted** — data doesn't leave
- **Community-built** OSS

- Upstream repo: <https://github.com/TheSpaghettiDetective/obico-server>
- Website: <https://www.obico.io>
- Docs: <https://www.obico.io/docs/server-guides/>
- Hardware reqs: <https://www.obico.io/docs/server-guides/hardware-requirements/>

## Architecture in one minute

- Django backend + React frontend likely
- Celery workers for ML inference
- **Deep Learning model** (failure-classifier)
- Optional **Nvidia GPU**
- MySQL/Postgres + Redis
- **Resource**: **heavy** — ML inference; 10-year-old PC minimum; GPU recommended for >1-2 printers
- **Port**: HTTP + websockets

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | Upstream                                                                                                               | **Primary** — Docker Compose v2.0+                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `print.example.com`                                         | URL          | TLS for remote                                                                                    |
| Hardware             | Decent CPU + optional GPU                                   | Hardware     |                                                                                    |
| Docker Compose       | v2.0+                                                       | Runtime      |                                                                                    |
| Email SMTP           | Notifications                                               | Email        |                                                                                    |
| OctoPrint/Klipper    | With Obico plugin                                           | Clients      | Per-printer                                                                                    |
| Webcam feeds         | MJPEG stream per printer                                    | Hardware     |                                                                                    |

## Install via Docker Compose

See <https://www.obico.io/docs/server-guides/>. Repository contains `docker-compose.yml`:
```sh
git clone https://github.com/TheSpaghettiDetective/obico-server.git
cd obico-server
# Edit .env
docker compose up -d
```

## First boot

1. Deploy server
2. Create first admin account
3. Install Obico plugin on OctoPrint/Klipper
4. Link printer to server
5. Point webcam feed
6. Start print; watch AI classify frames
7. Verify failure-detection triggers
8. Put behind TLS for remote access
9. Back up DB + ML model

## Data & config layout

- DB — users, printers, jobs
- Model files — Deep Learning weights
- Media storage — webcam snapshots + time-lapses

## Backup

```sh
# Database dump + media
# Contains webcam-capture images of your home/workshop — **ENCRYPT**
```

## Upgrade

1. Releases + main-branch: <https://github.com/TheSpaghettiDetective/obico-server/releases>
2. Pull + `docker compose up -d`
3. Check release notes for schema migration

## Gotchas

- **180th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — AI-3D-PRINT-FARM + WEBCAM-IMAGES**:
  - Holds: webcam images from printer locations (home/shop!), printer credentials, OctoPrint API keys, user accounts
  - **Webcam images = physical-security-adjacent** (shows your home/workshop)
  - AI-model weights
  - **180-TOOL HUB-OF-CREDENTIALS MILESTONE at Obico**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "AI-ML-server + webcam-monitoring-aggregator"** (1st — Obico; physical-location-sensitivity)
  - **CROWN-JEWEL Tier 1: 63 tools / 56 sub-categories**
- **WEBCAM-IMAGES-PHYSICAL-SECURITY**:
  - Printer webcams often reveal your home/workshop
  - Backgrounds reveal personal info
  - **Recipe convention: "webcam-image-background-privacy-awareness callout"**
  - **NEW recipe convention** (Obico 1st formally)
- **GPU-OPTIONAL-SCALING**:
  - CPU works for 1-2 printers; GPU for more
  - **Hardware-dependent-tool: 6 tools** (+Obico) 🎯 **6-TOOL MILESTONE**
- **AI-MODEL-SERVING-TOOL**:
  - Deep Learning failure classifier
  - **AI-model-serving-tool: 5 tools** (+Obico) 🎯 **5-TOOL MILESTONE**
- **RENAMED-FROM-SPAGHETTI-DETECTIVE**:
  - Org + name change
  - Repo URL still has legacy name
  - **Recipe convention: "project-rebrand-legacy-repo-URL neutral-signal"**
  - **NEW neutral-signal convention** (Obico 1st formally)
- **COMMERCIAL-PARALLEL**:
  - Obico offers SaaS
  - **Commercial-parallel-with-OSS-core: 16 tools** (+Obico) 🎯 **16-TOOL MILESTONE**
- **JUSPRIN-SIBLING-PROJECT**:
  - Separate JusPrin project by same org
  - README links to it
  - **Recipe convention: "sibling-project-cross-linking neutral-signal"**
  - **NEW neutral-signal convention** (Obico 1st formally)
- **OCTOPRINT-KLIPPER-ECOSYSTEM**:
  - Plugins on both major 3D print stacks
  - **Recipe convention: "broad-3D-print-ecosystem-integration positive-signal"**
  - **NEW positive-signal convention** (Obico 1st formally)
- **COMMUNITY-BUILT-EXPLICIT**:
  - Explicit "community-built, open-source"
  - **Recipe convention: "community-built-explicit-positioning positive-signal"**
  - **NEW positive-signal convention** (Obico 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: TheSpaghettiDetective→Obico rebrand + website + docs-site + SaaS + OctoPrint+Klipper ecosystem + active. **166th tool — rebranded-commercial-parallel sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + docs + SaaS + plugin-ecosystem + Docker. **172nd tool in transparent-maintenance family.**
- **3D-PRINT-AI-CATEGORY:**
  - **Obico** — AI failure detection; OctoPrint+Klipper
  - **Mainsail/Fluidd** — Klipper UIs (no AI)
  - **OctoEverywhere** — different focus (remote access)
- **ALTERNATIVES WORTH KNOWING:**
  - **Mainsail/Fluidd** — if you just want Klipper UI
  - **Cloud AI services** — if you prefer SaaS
  - **Choose Obico if:** you want self-hosted + AI failure-detection + OctoPrint+Klipper.
- **PROJECT HEALTH**: active + community + docs + SaaS-parallel + plugin-ecosystem. Strong.

## Links

- Repo: <https://github.com/TheSpaghettiDetective/obico-server>
- Website: <https://www.obico.io>
- OctoPrint: <https://octoprint.org>
- Klipper: <https://www.klipper3d.org>
