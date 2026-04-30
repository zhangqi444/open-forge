---
name: Scrypted
description: "High-performance home video integration platform + NVR with smart detections. Low-latency, instant streaming to HomeKit Secure Video, Google Home, and Alexa. Optional object detection via Coral TPU / OpenVINO / CoreML. Active plugin ecosystem. Node.js/TS. Apache-2.0."
---

# Scrypted

Scrypted is **a modern home video integration platform** — bridges your IP cameras, doorbells, and smart home to HomeKit Secure Video (HKSV), Google Home, and Alexa with **instant, low-latency streaming**. Its killer feature: it makes **any** ONVIF/RTSP camera (Reolink, Amcrest, Dahua, Hikvision, Unifi, Eufy, Ring, Nest, Tapo, Wyze, etc.) behave like a **native HomeKit camera** including person/vehicle/animal detection feeding HomeKit's "rich notifications" and HKSV cloud recording.

Created by **Koushik Dutta** (koush — CyanogenMod fame); actively developed; thriving community on Discord + Reddit.

**Positioning vs alternatives:**
- **HomeKit Secure Video enabler** — its single most-cited use. Apple users with a pile of off-brand cameras buy Scrypted specifically to make them HKSV-compatible.
- **NVR features** — optional but capable (scrypted-nvr plugin, plus third-party Frigate integration)
- **Low latency** — marketed as sub-second for live streams; actual claim matches most users' experience when properly tuned

Features:

- **Cross-platform smart home bridge** — HomeKit + Google Home + Alexa
- **HKSV** — most critical feature for Apple users
- **Object detection** — via Coral TPU plugin, OpenVINO (Intel), CoreML (Apple Silicon), ONNX, or cloud
- **Plugin system** — extensively modular; each camera vendor has a plugin, each feature is a plugin
- **WebRTC** + HLS + RTSP streaming
- **NVR** — scrypted-nvr plugin for recording/timeline/playback
- **Two-way audio + sirens + PTZ** (where cameras support)
- **Snapshot/motion/person events** routed to HomeKit notifications
- **Web UI** for configuration + live viewing
- **Home Assistant integration** (bi-directional)
- **Cloud service** (optional, koush operates) for relay + remote access

- Upstream repo: <https://github.com/koush/scrypted>
- Docs: <https://docs.scrypted.app>
- Developer docs: <https://developer.scrypted.app>
- Discord: <https://discord.gg/DcFzmBHYGq>
- Reddit: <https://reddit.com/r/scrypted>
- Docker Hub: <https://hub.docker.com/r/koush/scrypted>

## Architecture in one minute

- **Node.js / TypeScript** server + web UI
- **Plugin architecture** — plugins run in sub-processes (or Python for ML); isolated failure domains
- **Python bridge** for ML plugins (Coral, OpenVINO, etc.)
- **Runs best on**: Linux host (Docker or native), macOS (native), Windows, or **Scrypted NVR appliance images** (prebuilt)
- **Optional hardware acceleration**: Coral USB TPU (cheap, effective), Intel iGPU (QSV), NVIDIA GPU, Apple Silicon
- **Resource**: 2 GB RAM minimum; 4-8 GB for a few cameras; NVR recording adds disk I/O + storage

## Compatible install methods

| Infra                    | Runtime                                                           | Notes                                                                          |
| ------------------------ | ----------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM/host           | **Docker (`koush/scrypted:latest`)**                                  | **Upstream-recommended primary path**                                              |
| macOS                    | Native app via Homebrew / app installer                                       | Popular for Apple users                                                                    |
| Linux host               | Native install (Node.js)                                                                  | Supported                                                                                              |
| Raspberry Pi 4/5         | Docker ARM64; OK for 1-2 cameras; add Coral TPU for detection                             | Works; tight                                                                                                       |
| Synology / UGREEN / QNAP | Docker package                                                                                          | Popular homelab path                                                                                                                   |
| Scrypted NVR appliance   | Prebuilt turnkey (e.g., on mini-PCs, official hardware)                                                                | Zero-setup option                                                                                                                                       |
| Kubernetes               | Not idiomatic (hardware passthrough + low-latency networking)                                                                                         |                                                                                                                                                                               |

## Inputs to collect

| Input                    | Example                                                  | Phase       | Notes                                                                  |
| ------------------------ | -------------------------------------------------------- | ----------- | ---------------------------------------------------------------------- |
| Host network             | **Must use host networking** (HomeKit + mDNS discovery)          | Network     | Not bridge network — Bonjour + HAP won't work otherwise                        |
| Camera URLs/creds        | RTSP URLs + camera-app credentials                                     | Setup       | Per camera                                                                            |
| HomeKit PIN              | Shown during pairing                                                              | Auth        | Enter in iPhone Home app                                                                              |
| HW acceleration          | Coral TPU / iGPU / GPU / CoreML                                                              | Detection   | Dramatically reduces CPU for object detection                                                                                          |
| Storage (NVR)            | Path + size for recordings                                                                             | Storage     | If using NVR plugin; SSDs + RAID recommended                                                                                                                |
| Admin creds              | default `admin` / prompts at setup                                                                                   | Bootstrap   | Set strong password                                                                                                                                     |

## Install via Docker (Linux host networking)

Per upstream, host networking is effectively required. Typical:

```sh
docker run -d \
  --name scrypted \
  --network host \
  --restart unless-stopped \
  -v ./data:/server/volume \
  koush/scrypted:latest     # pin exact tag in prod
```

Or compose with `network_mode: host`. For Coral USB, add `--privileged` or device maps. Browse `https://<host>:10443/`.

## First boot

1. Browse `https://<host>:10443/` → accept self-signed cert → create admin
2. **Install plugins**: HomeKit, Google Home, or Alexa (whichever you use); camera-vendor plugin matching your hardware; object-detection plugin (Coral if you have the stick, else OpenVINO/CPU)
3. **Add cameras**: click Add Device → pick plugin → enter RTSP URL + credentials
4. **HomeKit pairing**: go to HomeKit plugin → see QR code; scan in iPhone Home app
5. **HKSV**: per camera, enable HKSV in HomeKit app; requires iCloud+ subscription for cloud storage
6. **Tune detection**: configure motion regions + classes (Person/Vehicle/Animal); adjust FPS; verify HomeKit notifications arrive
7. **NVR (optional)**: install scrypted-nvr plugin → assign storage → enable per-camera continuous or motion recording

## Data & config layout

- `/server/volume/` (container) — all state: plugin data, cameras, certs, recordings (if NVR stored here), detection cache
- Single-directory backup model (clean)

## Backup

```sh
# Whole Scrypted state
docker stop scrypted
sudo tar czf scrypted-$(date +%F).tgz data/
docker start scrypted

# If NVR recordings are huge: exclude NVR storage from backup; rely on retention + RAID for video.
```

**NVR recordings**: treat as replaceable; retention policy > offsite backup (same as ZoneMinder / Frigate pattern).

## Upgrade

1. Releases: <https://github.com/koush/scrypted/releases>. Extremely active — weekly to daily.
2. Docker: bump tag → restart. Plugins auto-update (unless pinned).
3. Breaking changes are rare but possible — read release notes.
4. **Back up `volume/` before major version jumps.**

## Gotchas

- **Host networking required** on Linux — HomeKit's HAP protocol uses mDNS/Bonjour discovery that doesn't work across Docker bridge. Use `--network host`. This is THE #1 gotcha for new users.
- **HomeKit pairing flakiness**: if iPhone doesn't see the accessory, check: (1) same subnet as Scrypted host, (2) no mDNS filtering on router, (3) Scrypted's HomeKit plugin log for errors, (4) multi-VLAN setups need mDNS repeater.
- **HKSV requires iCloud+**: HomeKit Secure Video cloud recording requires an iCloud+ subscription + HomeKit-compatible "hub" (HomePod/Apple TV/iPad). Scrypted doesn't bypass this.
- **HKSV camera limit**: iCloud+ plans cap number of HKSV cameras (1, 5, unlimited per plan). Scrypted makes cameras compatible; doesn't unlock Apple's limits.
- **CPU for object detection**: software-only object detection burns CPU hard. **A $60 Coral USB TPU transforms the experience** — it's the upgrade nearly every user eventually makes. Or use iGPU (OpenVINO) or Apple Silicon CoreML.
- **Low-latency streaming**: works beautifully when camera + Scrypted + client are on same LAN. WAN streams via Scrypted Cloud or VPN.
- **Plugin quality**: most first-party plugins (HomeKit, Google, camera vendors) are well-maintained. Some community plugins less so; check last-commit dates.
- **Scrypted Cloud**: optional paid service for remote access without port-forwarding/VPN. Convenience + privacy trade-off (koush operates the relay); many users skip + use Tailscale instead.
- **NVR vs Frigate**: Scrypted-NVR is solid but younger than Frigate. For serious NVR + ML-detection workloads, some users pair Frigate (records + detects) + Scrypted (HomeKit bridge) — Scrypted integrates with Frigate well.
- **Rapid-release model**: koush ships fast; occasionally a release introduces regressions. Power users pin versions; most let it auto-update.
- **Backups should include plugin configs + credentials** — losing `volume/` = re-pair all cameras + HomeKit.
- **Apple Silicon Macs**: run Scrypted natively (not Docker); CoreML acceleration is excellent; very low power.
- **NUC / mini-PC + Coral**: the canonical Scrypted hardware platform. Small, cheap, quiet, headless.
- **Cameras that Scrypted handles exceptionally well**: Reolink (direct RTSP), Amcrest, Unifi Protect (via plugin), Ring (via community plugin with caveats), Eufy (local-mode via community plugin).
- **Cameras that struggle**: cloud-only cameras with no local stream (some Wyze/Nest without workarounds), heavily DRM-locked vendors.
- **Remote access security**: if exposing Scrypted web UI, use VPN or reverse-proxy + auth. Never port-forward :10443 directly.
- **License**: **Apache-2.0**.
- **Legal (recording)**: same CCTV/GDPR concerns as ZoneMinder. Signage + retention per jurisdiction.
- **Alternatives worth knowing:**
  - **Frigate** — NVR-first, ML-detection-first, MQTT+Home Assistant (separate recipe likely); different scope
  - **Home Assistant + Go2RTC** — Home-Assistant-centric camera streaming
  - **UniFi Protect** — first-party UniFi NVR; commercial hardware required
  - **Synology Surveillance Station** — Synology NAS users
  - **BlueIris** — Windows NVR; commercial
  - **HOOBS / Homebridge** — bridges non-HomeKit devices; Scrypted is the video specialist
  - **Agent DVR** — cross-platform; free tier
  - **Choose Scrypted if:** Apple household + HomeKit Secure Video + need to onboard many non-HomeKit cameras + want low-latency live viewing.
  - **Choose Frigate if:** NVR + ML-detection + Home-Assistant ecosystem.
  - **Choose UniFi Protect if:** UniFi ecosystem + turnkey.

## Links

- Repo: <https://github.com/koush/scrypted>
- Docs: <https://docs.scrypted.app>
- Developer docs: <https://developer.scrypted.app>
- Discord: <https://discord.gg/DcFzmBHYGq>
- Reddit: <https://reddit.com/r/scrypted>
- Docker Hub: <https://hub.docker.com/r/koush/scrypted>
- Releases: <https://github.com/koush/scrypted/releases>
- Coral TPU (recommended accelerator): <https://coral.ai>
- Frigate (alt, NVR-first): <https://github.com/blakeblackshear/frigate>
- Home Assistant: <https://www.home-assistant.io>
- UniFi Protect: <https://www.ui.com/camera-security>
