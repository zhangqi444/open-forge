---
name: Viseron
description: "Self-hosted local-only NVR + AI computer-vision software. Object + motion + face + licence-plate detection. Component-based architecture. Docker-first. License: MIT (verify). Active; sole-maintainer-with-sponsors; Discord via GitHub Discussions."
---

# Viseron

Viseron is **"Frigate / Blue Iris / Shinobi — but component-plugin-based"** — self-hosted, local-only Network Video Recorder with AI computer-vision capabilities. Runs on your hardware, uses your cameras, never sends video offsite. Features object detection, motion detection, face recognition, license-plate recognition (LPR), audio event detection. Configuration-driven via built-in web interface. Component architecture lets you mix + match detectors + recorders + sources.

Built + maintained by **Joakim "roflcoopter"** + community + sponsors. License: check repo. Active; Netlify docs; GitHub Sponsors + BuyMeACoffee funding; Component Explorer tool; component-per-capability design.

Use cases: (a) **home security** — camera feeds → motion/person detection → alerts (b) **package delivery detection** — "Amazon is at the door" (c) **license-plate-reading** — garage automation; allowlist cars; suspicious-vehicle flagging (d) **privacy-first NVR** — no cloud; all video stays on your server (e) **Frigate alternative** for those who want component-plugin-based architecture (f) **face recognition** for household members (with consent + legal-nuance) (g) **AI detection on GPU** — object-detection with YOLOv8/Coral TPU/OpenVINO (h) **Home Assistant integration** via MQTT events.

Features (per upstream README + docs):

- **Local-only** — zero cloud dependency
- **NVR functionality** — record 24/7 or event-triggered
- **Object detection** (YOLO-family via darknet/YOLOv5/YOLOv8)
- **Motion detection** (background subtraction + frame diff)
- **Face recognition**
- **Licence-plate recognition (LPR)**
- **Audio event detection**
- **Component architecture** — modular + extensible
- **Web UI** for configuration + viewing
- **Home Assistant** integration via MQTT
- **Multi-accelerator support**: CPU, GPU (CUDA), Coral TPU, OpenVINO (Intel), Jetson
- **Docker-first**

- Upstream repo: <https://github.com/roflcoopter/viseron>
- Docs: <https://viseron.netlify.app>
- Component Explorer: <https://viseron.netlify.app/components-explorer/>
- Issue tracker: <https://github.com/roflcoopter/viseron/issues>
- Discussions: <https://github.com/roflcoopter/viseron/discussions>
- GitHub Sponsors: <https://github.com/sponsors/roflcoopter>
- BuyMeACoffee: <https://www.buymeacoffee.com/roflcoopter>

## Architecture in one minute

- **Python** core + detector integrations
- **FFmpeg** — stream ingestion + encoding
- **Docker** — primary deployment
- **Hardware**: recommends GPU/TPU/Jetson for real-time multi-camera object-detection; CPU works for small setups
- **Resource**: HIGH — 2-8GB RAM depending on cameras + detectors; GPU memory matters
- **Port**: web UI (configurable)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`roflcoopter/viseron`** + accelerator-specific image variants | **Primary**                                                                        |
| Kubernetes         | Possible but not upstream-primary                                         | DIY                                                                                   |
| Bare-metal Python  | Not recommended; dependency-hell                                                         | Docker way simpler                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Cameras              | RTSP/ONVIF URLs + credentials                               | **CRITICAL** | **Per-camera stream URLs**                                                                                    |
| Accelerator          | CPU / CUDA / Coral TPU / OpenVINO / Jetson                  | **CRITICAL** | **Pick image variant**                                                                                    |
| Storage dir          | `/mnt/viseron/recordings/` — LARGE                          | Storage      | **Plan for TBs**                                                                                    |
| Config YAML          | Viseron's config schema                                                                           | **CRITICAL** | **All behavior here**                                                                                    |
| Home Assistant MQTT  | Broker URL + creds                                                                                 | Integration  | Optional                                                                                                            |
| Face/LPR models      | Pre-trained or bring-your-own                                                                                                      | Config       | For face+LPR features                                                                                                                            |

## Install via Docker (typical)

```yaml
services:
  viseron:
    image: roflcoopter/viseron:v3.5.3        # **pin + pick accelerator variant**
    container_name: viseron
    restart: unless-stopped
    ports:
      - "8888:8888"     # web UI
    volumes:
      - ./viseron-config:/config
      - ./viseron-recordings:/recordings
    devices:
      - /dev/dri:/dev/dri               # Intel QSV
      # - /dev/bus/usb:/dev/bus/usb     # Coral TPU USB
    environment:
      - TZ=UTC
      - PUID=1000
      - PGID=1000
```

## First boot

1. Start → browse `http://host:8888`
2. Edit config via web UI
3. Add cameras (RTSP URLs)
4. Configure detectors (object, motion, face, LPR)
5. Test with test-stream; verify detection works
6. Configure Home Assistant MQTT (optional)
7. Plan disk-usage + retention
8. Put behind TLS reverse proxy + auth
9. Back up config + optionally recordings

## Data & config layout

- `/config/` — YAML config + face models + LPR models
- `/recordings/` — ALL RECORDED VIDEO (can be TBs)
- Event logs + snapshots

## Backup

```sh
sudo tar czf viseron-config-$(date +%F).tgz viseron-config/
# Recordings: back up only if needed; typically ephemeral
```

## Upgrade

1. Releases: <https://github.com/roflcoopter/viseron/releases>. Active.
2. Docker: pull + restart; config auto-migrates.
3. Component-architecture means component-version-compat matters; read release notes.
4. Back up config BEFORE major upgrades.

## Gotchas

- **SURVEILLANCE VIDEO = HIGHLY-PERSONAL DATA + LEGAL LANDMINE**:
  - **Privacy laws** (GDPR in EU, CCPA in California, PIPL in China, etc.) regulate video-surveillance
  - **Recording people in public spaces** may require signage / consent
  - **Recording audio with video** often requires two-party consent (US state-by-state; some illegal)
  - **Recording visitors / delivery-people / neighbors** = fresh GDPR violation risk in EU
  - **Employer-employee surveillance** has additional worker-rights protections
  - **53rd tool in hub-of-credentials family — PHYSICAL-SECURITY-CROWN-JEWEL sub-family (NEW)** — distinct from HEALTHCARE-CROWN-JEWEL (SparkyFitness 94, Garmin-Grafana 98) and LIFELOG (Ryot 95)
  - **NEW: 5th regulatory-crown-jewel sub-family: "PHYSICAL-SECURITY-CROWN-JEWEL"** (surveillance + physical-access + home-security video)
  - **Family-doc at batch 100: regulatory-crown-jewel sub-families now 5** (financial, research, healthcare, LIFELOG, physical-security)
- **FACE RECOGNITION = PARTICULAR LEGAL RISK**:
  - **EU AI Act** (entered-into-force 2024): facial recognition in public has specific restrictions
  - **Illinois BIPA** (US): biometric-data-consent law — $1000-$5000 per violation
  - **Texas CUBI**: similar biometric law
  - **Face DB = biometric-identifier database** = regulated asset
  - **Recipe convention: "face-recognition-regulatory-callout"** for tools with FR capability
- **HOUSEHOLD MEMBER CONSENT**: face-recognition on household members (spouse, kids, roommates) requires CONSENT and TRANSPARENCY. Design:
  - Everyone in household informed
  - Able to opt out
  - Clear purpose (package-detection vs granular-people-counting)
- **NEIGHBORS' PRIVACY**: cameras pointed at sidewalk or neighbor's property = privacy-complaint risk. Angle appropriately; use privacy-zones (black-out non-yours areas).
- **RECORDING STORAGE UNBOUNDED**: video is huge. Retention policy + auto-cleanup:
  - Daily = GBs
  - Monthly = TBs
  - Multiple cameras multiply
  - **Plan retention carefully** — days-to-weeks typical for event-triggered; 24/7 is expensive
- **ANTI-BURGLARY-VALUE vs DELETE-BEFORE-POLICE-ARRIVE**:
  - Off-site backup of video = safer against burglary (thief can't destroy local recordings)
  - Local-only = privacy-win but vulnerable to physical-theft
  - **Pattern**: encrypted off-site sync for critical cameras (entrances); local-only for interior
- **WORKFLOW WITH HOME ASSISTANT**: Viseron + MQTT + HA = "person at door" → "lights on" → "notification sent". Common integration; requires MQTT broker (mosquitto) + HA.
- **GPU REQUIREMENT for REAL-TIME MULTI-CAMERA**: 1-2 cameras on CPU works; 5+ cameras needs GPU (CUDA) or TPU (Coral). **Hardware-accelerator is a first-class concern** (unlike many homelab tools).
- **COMPONENT ARCHITECTURE = EXTENSIBILITY**: Viseron's component model allows adding new detectors / recorders / sources. Positive signal; communities can contribute components.
- **HUB-OF-CREDENTIALS TIER 2 WITH PHYSICAL-SECURITY-CROWN-JEWEL ELEVATION**:
  - Camera RTSP/ONVIF credentials (compromise = attacker views all your cameras live)
  - Recorded video (entire history of home activity)
  - MQTT creds
  - **53rd tool hub-of-credentials — PHYSICAL-SECURITY-CROWN-JEWEL sub-family**
- **TRANSPARENT-MAINTENANCE**: active + docs site + Component Explorer + sponsors + BMC + Discussions + issue tracker. **45th tool in transparent-maintenance family.**
- **INSTITUTIONAL-STEWARDSHIP**: Joakim "roflcoopter" + community + visible-sponsor-support. **38th tool in institutional-stewardship — sole-maintainer-with-visible-sponsor-support (3rd tool in sub-tier)** (MediaManager 97 + AdventureLog 98 + **Viseron 99**). Sub-tier now solidified at 3 tools.
- **LICENSE CHECK**: verify LICENSE file (prior conventions).
- **AI-MODEL-SERVING TOOL CATEGORY overlap**: Viseron loads YOLO + face + LPR models → shares concerns with Speaches 96 "AI-model-serving-tool category": model-license-audit, GPU-requirement, model-cache-sizing.
- **ALTERNATIVES WORTH KNOWING:**
  - **Frigate** — Python; similar feature set; strong Home Assistant integration; larger community
  - **Shinobi** — Node.js; feature-rich NVR
  - **Blue Iris** — commercial Windows-only NVR; mature
  - **Zoneminder** — older; PHP; mature; still in use
  - **Agent DVR** — commercial; Windows-first
  - **Unifi Protect** — commercial + hardware-tied (Ubiquiti)
  - **Ring / Nest / Arlo** — commercial cloud NVR (opposite of Viseron's philosophy)
  - **DeepStack / CodeProject.AI** — AI inference servers (Viseron can use these)
  - **Choose Viseron if:** you want component-plugin-based + Python + local-only + GPU/TPU + modern.
  - **Choose Frigate if:** you want MORE-mature + larger community + similar design philosophy.
  - **Choose Shinobi if:** you want Node.js + richer UI.
  - **Choose Zoneminder if:** you want proven-and-stable.
- **PROJECT HEALTH**: active + docs + sponsor-backed + component architecture + Home Assistant integration + multi-accelerator support. Strong signals.

## Links

- Repo: <https://github.com/roflcoopter/viseron>
- Docs: <https://viseron.netlify.app>
- Component Explorer: <https://viseron.netlify.app/components-explorer/>
- GitHub Sponsors: <https://github.com/sponsors/roflcoopter>
- BMC: <https://www.buymeacoffee.com/roflcoopter>
- Frigate (alt): <https://frigate.video>
- Shinobi (alt): <https://shinobi.video>
- Zoneminder (alt): <https://zoneminder.com>
- CodeProject.AI: <https://www.codeproject.com/AI/Index.aspx>
- Home Assistant: <https://www.home-assistant.io>
- Illinois BIPA: <https://www.ilga.gov/legislation/ilcs/ilcs3.asp?ActID=3004>
- EU AI Act: <https://artificialintelligenceact.eu>
