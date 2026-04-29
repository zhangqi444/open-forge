---
name: frigate-project
description: Frigate recipe for open-forge. MIT-licensed (code; "Frigate" name is a trademark of Frigate, Inc.) complete local NVR with real-time AI object detection for IP cameras. Uses TensorFlow/OpenCV + hardware accelerators (Google Coral, Intel iGPU via OpenVINO, NVIDIA GPU via TensorRT, Apple Silicon, Hailo, AMD GPU via ROCm, Rockchip NPU) to do 100% local ML inference. Records 24/7, motion-gated object detection, MQTT events, tight Home Assistant integration, RTSP restreaming, WebRTC/MSE low-latency live view. Self-host is HEAVY (FFmpeg transcoding + neural inference + disk I/O) — real hardware matters. Covers standard Docker Compose deployment, HA add-on, hardware acceleration options, and the Birds' Eye View of config/storage layout.
---

# Frigate

MIT-licensed local NVR with realtime AI object detection. Upstream: <https://github.com/blakeblackshear/frigate>. Docs: <https://docs.frigate.video>. Home Assistant integration: <https://github.com/blakeblackshear/frigate-hass-integration>.

**"NVR"** = Network Video Recorder. Frigate connects to your IP cameras (RTSP), runs motion detection continuously, then runs AI object detection (person, car, dog, package, bird, etc.) on motion regions, records clips + snapshots when objects are detected, and notifies Home Assistant / MQTT / webhooks.

Unlike cloud NVRs (Ring / Nest / Eufy cloud), Frigate runs 100% locally — no footage leaves your LAN. Unlike generic NVRs, Frigate uses ML to dramatically reduce false-positive recordings (a swaying branch ≠ a burglar).

## What makes it distinctive

- **Motion-gated object detection.** Runs cheap motion detection always, runs expensive NN inference ONLY when motion detected. Dramatically reduces CPU/GPU/TPU load vs always-on inference.
- **Broad hardware acceleration.** Google Coral USB/PCIe (TPUs, ~7W, fast), Intel iGPU via OpenVINO, NVIDIA via TensorRT, Apple Silicon, Hailo, AMD ROCm, Rockchip NPU (Radxa boards), CPU fallback.
- **Zone/mask editor** in the web UI — draw polygons to ignore ("ignore my own street", "only alert on driveway").
- **Review workflow** — groups of events into reviewable "alerts" with preview loops.
- **WebRTC + MSE** for sub-second live view (vs HLS's 5-10s lag).
- **Genius HA integration** — person detected → automate lights, notifications, door locks.
- **Face/LPR (license plate recognition)** are available in 0.14+ via extension models.
- **Multi-camera** — dozens of cameras on one capable host.

## ⚠️ Hardware requirements are non-trivial

A small setup (2-3 cameras, person detection only):

- **CPU**: decent x86_64 (Celeron J4125+ OK) OR Pi 5 OR similar
- **RAM**: 4 GB minimum, 8 GB comfortable
- **Disk**: SSD strongly recommended for recordings (writes are constant). USB 3.0 HDD ok; avoid SD cards.
- **AI accelerator**: **highly recommended.** Google Coral USB ($60-80, if you can find one), or modern Intel iGPU (N100, N95, etc.) for OpenVINO, or NVIDIA GPU (GTX 1050 or better).

For 10+ cameras or 4K cameras, scale up commensurately — Frigate can saturate multi-core Xeons.

**Without an accelerator, CPU detection is possible but eats an entire core per camera at 5 fps, which doesn't scale.**

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker image (`ghcr.io/blakeblackshear/frigate`) | ✅ Recommended | Most self-hosters. |
| Home Assistant Add-on (Supervised / HAOS) | <https://github.com/blakeblackshear/frigatehass-addons> | ✅ | Running on Home Assistant OS. |
| Docker image with hardware-specific tag | `stable-tensorrt` / `stable-rocm` / etc. | ✅ | Match to your accelerator. |
| Proxmox LXC | Community | ⚠️ | Works but hardware pass-through is fiddly. |
| Kubernetes | No first-party Helm chart | ⚠️ | Community charts exist; not recommended. |
| Frigate+ subscription | <https://frigate.video/plus> | ✅ (paid) | Upload events to train a custom model specific to your cameras — improves accuracy. Optional paid service. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-compose` / `ha-addon` | Drives section. |
| hardware | "Hardware accelerator?" | `AskUserQuestion`: `coral-usb` / `coral-pcie` / `openvino-intel-igpu` / `tensorrt-nvidia` / `rocm-amd` / `hailo` / `rockchip-npu` / `apple-silicon` / `cpu-only` | Determines image tag + device mounts. |
| hardware | "hwaccel for FFmpeg decoding?" | `AskUserQuestion` | Separate from AI inference. Intel QSV / NVIDIA NVDEC / VAAPI / CUDA. Can be the same chip as AI accel, or different. |
| cameras | "How many cameras?" | Number | Sanity check vs hardware. |
| cameras | "For each camera: RTSP URL?" | Free-text | Typical: `rtsp://user:pass@10.0.0.10:554/stream1`. Use `sub_stream` (low-res) for detect + `main_stream` (hi-res) for record. |
| storage | "Recordings disk path?" | Free-text, default `/media/frigate` | Bind-mounted into container. Plan for 100-500 GB per camera per month depending on FPS/resolution/retention. |
| storage | "Retention in days?" | Number, default `10` | Per-camera + per-mode (continuous / motion / alerts). |
| mqtt | "MQTT broker for events?" | `AskUserQuestion`: `frigate-bundled-mosquitto` / `external` / `none` | HA users usually have an MQTT broker already. |
| admin | "Admin user + password?" | Free-text (sensitive) | Set via `users` in `config.yml` (new in 0.14+). |
| dns | "Public hostname?" | Free-text, optional | Frigate is LAN-only for most; if exposing externally, put behind reverse proxy + auth. |

## Install — Docker Compose

```yaml
# compose.yaml
services:
  frigate:
    container_name: frigate
    privileged: true                             # required for hardware accel in many configs
    restart: unless-stopped
    image: ghcr.io/blakeblackshear/frigate:stable
    shm_size: "128mb"                            # increase for many/hi-res cameras — see docs
    devices:
      - /dev/bus/usb:/dev/bus/usb                # Coral USB
      # - /dev/apex_0:/dev/apex_0                # Coral PCIe
      - /dev/dri/renderD128:/dev/dri/renderD128  # Intel iGPU (OpenVINO / QSV)
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./config:/config
      - /srv/frigate:/media/frigate
      - type: tmpfs                              # 1 GB tmpfs for temporary clip cache
        target: /tmp/cache
        tmpfs:
          size: 1000000000
    ports:
      - "8971:8971"   # auth-protected web UI (0.14+)
      - "5000:5000"   # internal unauthenticated, usually skip
      - "8554:8554"   # RTSP restreams
      - "8555:8555/tcp"
      - "8555:8555/udp"   # WebRTC
    environment:
      FRIGATE_RTSP_PASSWORD: "your-camera-password"
```

### Hardware-specific image tags

Pick the image for your accelerator:

- `:stable` — CPU / Coral / OpenVINO baseline (~2 GB image)
- `:stable-tensorrt` — adds NVIDIA TensorRT support (~4 GB)
- `:stable-rocm` — AMD GPU via ROCm
- Both `:stable` and `:stable-tensorrt` run on the same architectures via Docker buildx.

### Minimum config.yml

```yaml
# config/config.yml
mqtt:
  enabled: true
  host: mqtt.lan        # or 127.0.0.1 if using the bundled broker via HA
  user: frigate
  password: "{FRIGATE_MQTT_PASSWORD}"

detectors:
  coral:
    type: edgetpu
    device: usb
  # For Intel iGPU OpenVINO instead:
  # openvino:
  #   type: openvino
  #   device: GPU

cameras:
  front_door:
    ffmpeg:
      inputs:
        - path: rtsp://user:{FRIGATE_RTSP_PASSWORD}@10.0.0.10:554/cam/realmonitor?channel=1&subtype=1
          roles: [detect]
        - path: rtsp://user:{FRIGATE_RTSP_PASSWORD}@10.0.0.10:554/cam/realmonitor?channel=1&subtype=0
          roles: [record, rtmp]
    detect:
      width: 640
      height: 480
      fps: 5
    objects:
      track: [person, car, dog, package]
    motion:
      mask:                                    # ignore the sky / your own porch light
        - "0,0,640,0,640,100,0,100"
    record:
      enabled: true
      retain:
        days: 10
        mode: motion
      alerts:
        retain:
          days: 30
          mode: motion

users:                                          # 0.14+
  admin:
    password: <bcrypt-hashed-password>

auth:
  enabled: true                                 # auth is REQUIRED in 0.14+ unless explicitly disabled
```

Open `https://<host>:8971/` → log in with admin creds.

## Install — Home Assistant Add-on

If you run Home Assistant OS or Supervised:

1. Settings → Add-ons → Add-on Store → Repositories → add `https://github.com/blakeblackshear/frigatehass-addons`.
2. Install "Frigate NVR" (or "Frigate NVR Full Access" for dev builds / bleeding edge).
3. Configure in the add-on's config YAML (uses the same schema as `config.yml`).
4. Start the add-on.

The HA add-on handles camera hardware passthrough via Supervisor — less tinkering than raw Docker.

## Home Assistant integration

Install the "Frigate" custom integration via HACS (<https://github.com/blakeblackshear/frigate-hass-integration>). It creates per-camera + per-object entities (e.g. `binary_sensor.front_door_person_detected`, `image.front_door_last_person`, `camera.front_door`), enabling automations.

## Data layout

| Path | Content |
|---|---|
| `./config/config.yml` | Main config |
| `./config/frigate.db` | SQLite DB: events, review items, recording metadata |
| `/media/frigate/recordings/<camera>/<date>/<hour>/<min>.<sec>.mp4` | Segmented recordings (default 10-second chunks) |
| `/media/frigate/clips/` | Legacy clips dir (deprecated in 0.13+, recordings are the system) |
| `/tmp/cache/` | Pre-record buffer for event clips. Size per `shm_size`. |

**Backup**:

- Config: `config/` dir is tiny. Back up religiously.
- Events DB: `config/frigate.db`. Small (MB).
- Recordings: large. Usually not backed up — local-only by design. If needed, rsync `/media/frigate/recordings/` offsite.

## Upgrade procedure

```bash
# 1. BACK UP CONFIG FIRST (so you can downgrade if needed)
cp -r config config-backup-$(date +%F)

# 2. Read release notes for breaking changes:
# https://github.com/blakeblackshear/frigate/releases

# 3. Bump tag + pull
docker compose pull
docker compose up -d
docker compose logs -f frigate
```

Major version jumps (0.12 → 0.13, 0.13 → 0.14) have introduced config-schema changes. The web UI will flag config errors on startup — read them carefully. **Downgrade is supported** (change tag back, restart) as long as the events DB hasn't been migrated to a newer schema (Frigate prints a warning before running schema migrations).

## Gotchas

- **Without hardware acceleration, CPU inference scales terribly.** A modern 8-core desktop CPU handles ~5 cameras at 5 fps detect with model latency of 50-100ms per frame — acceptable, but you've just burned the whole CPU. A Coral USB does the same inference in <10ms per frame using 5W. Budget for an accelerator.
- **Google Coral TPU is often out of stock.** Coral USB accelerators have been supply-constrained for years. Alternatives: Coral M.2 / PCIe (often available from specialty retailers); Intel iGPU via OpenVINO (any recent Intel CPU with iGPU); NVIDIA GPU via TensorRT (overkill but works).
- **`shm_size` MUST be increased for multiple cameras.** Default Docker shm is 64MB; Frigate needs roughly 20MB × camera-count × 2 for hi-res streams. Symptoms of too-small: cryptic "out of memory" errors, blank frames in web UI. Set to 256MB-1GB per the docs.
- **`sub_stream` for detection, `main_stream` for recording.** RTSP cameras typically expose a low-res sub-stream (640x480-ish) and a hi-res main stream (4K). Configure Frigate to DETECT on sub-stream (cheap) and RECORD on main stream (quality). Otherwise you're decoding 4K for every frame just to find motion.
- **FFmpeg HW decode ≠ AI accelerator.** Two separate hardware paths. Intel iGPU can do BOTH with the right config; NVIDIA GPU can do both too; Coral can only do AI inference — FFmpeg still uses CPU for decoding.
- **Recordings directory fills fast.** 10 cameras × 24/7 × H.264 4 Mbps main stream × 30 days = ~10 TB. Plan storage. Frigate automatically prunes based on retention config, but bad config can leave it unbounded.
- **SD cards die.** Continuous writes to an SD card (e.g. Pi with OS on SD + recordings on SD) kill the card in months. Always use SSD / USB-3 SSD / NVMe for recordings.
- **RTSP is fragile.** Cameras drop connections; Frigate reconnects. But misformed RTSP URLs (wrong subtype, wrong codec) fail silently. Test each camera's URL with `ffprobe` before adding to Frigate.
- **`privileged: true`** or specific device access is required in most Docker setups for hardware accelerators. Reduces container isolation. Unavoidable with current Docker device-passthrough model.
- **Port 8971 vs 5000.** In 0.14+, `:8971` is the AUTHENTICATED web UI and `:5000` is internal un-authenticated (meant for reverse proxies doing their own auth). Expose `:8971` on LAN; never expose `:5000` directly.
- **Auth is mandatory in 0.14+** unless you explicitly `auth.enabled: false`. Missing `users` config = admin account is auto-created on first boot with a password printed to logs (grep docker logs for "admin password").
- **Detection FPS vs recording FPS are separate.** `detect.fps: 5` sets detection rate; recording FPS is whatever the camera sends (usually 15-30). Tuning down detect FPS = less inference load = more cameras supported.
- **Zones vs masks:** a MASK excludes a region from motion detection; a ZONE is a named region for attention ("when a person enters the driveway zone"). Easy to confuse.
- **License plate recognition (LPR) in 0.14+** requires a dedicated LPR model + sufficient hardware. Accuracy depends heavily on camera angle, resolution, lighting. Not a perfect system — expect misreads.
- **Frigate+ is optional paid** ($50/year as of writing). It lets you upload snapshots of false positives + confirmed detections, which retrain a custom model for your cameras. Often improves accuracy dramatically. Not required; stock models are good.
- **Coral USB slow on some USB 2.0 ports.** Use USB 3.0 port + short cable for full bandwidth.
- **Home Assistant discovery assumes an HA instance is on the same MQTT broker.** The Frigate HA integration works over MQTT; both sides must point at the same broker.
- **Backup config before every upgrade.** Config schema changes in major releases can require manual updates. Downgrade fails gracefully but can leave events-DB in a mixed state.

## Links

- Upstream repo: <https://github.com/blakeblackshear/frigate>
- Docs: <https://docs.frigate.video>
- Getting started: <https://docs.frigate.video/frigate/installation>
- Hardware guide: <https://docs.frigate.video/frigate/hardware>
- Object detectors: <https://docs.frigate.video/configuration/object_detectors/>
- Home Assistant integration: <https://github.com/blakeblackshear/frigate-hass-integration>
- HA add-ons repo: <https://github.com/blakeblackshear/frigatehass-addons>
- Releases: <https://github.com/blakeblackshear/frigate/releases>
- Docker image: <https://github.com/blakeblackshear/frigate/pkgs/container/frigate>
- Frigate+ (paid): <https://frigate.video/plus>
- Reddit: <https://reddit.com/r/frigate_nvr>
- Discord: linked from docs
