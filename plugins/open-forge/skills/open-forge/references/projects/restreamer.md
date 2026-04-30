---
name: Restreamer
description: "Self-hosted live-streaming + restreaming solution — ingest RTMP/SRT/HLS, publish to YouTube/Twitch/Twitter/Vimeo simultaneously, plus your own website via built-in player. FFmpeg-powered. HW-accelerated (RPi/Cuda/VAAPI). Apache-2.0."
---

# Restreamer

Restreamer is **self-hosted "restream to many platforms" for live video** — built by **datarhei**. Ingest an RTMP/SRT feed (from OBS / hardware encoder / IP camera / phone), transcode with FFmpeg, and simultaneously publish to YouTube Live, Twitch, Twitter (X), Vimeo, your own Wowza/nginx-rtmp server, or embed directly on your website via built-in VideoJS player + HLS. Supports **hardware acceleration**: Raspberry Pi (MMAL/OMX), Nvidia Cuda, Intel VAAPI. Designed to run well on small hardware including Pi 4/5.

Positioning: self-hosted Restream.io / StreamYard competitor for streaming; **the only widely-used FOSS multi-restream solution**.

Features:

- **Ingest**: RTMP, RTMPS, SRT, HLS, RTSP, UDP, MPEG-TS; cameras + software encoders
- **Outputs**: RTMP push to YouTube/Twitch/Twitter/Vimeo/custom; HLS for your own site
- **Built-in VideoJS player** — embed on your website
- **Configurable publication page** — no-embed-required streaming
- **Audio muxing** — separate audio channel
- **Hardware acceleration** — MMAL/OMX (RPi), Cuda (NVIDIA), VAAPI (Intel)
- **USB/local devices** (with `--privileged`)
- **Let's Encrypt** automatic HTTPS
- **Viewer/bandwidth monitoring + limits**
- **REST API** (OpenAPI/Swagger documented)
- **Prometheus metrics** optional
- **GDPR compliant** — no third-party trackers, no audience-data persistence

- Upstream repo: <https://github.com/datarhei/restreamer>
- Docs: <https://docs.datarhei.com/restreamer/getting-started/quick-start>
- Demo: <https://demo.datarhei.com/ui> (admin/demo)
- Docker Hub: <https://hub.docker.com/r/datarhei/restreamer>

## Architecture in one minute

- **Go server** (`datarhei/core`) + **FFmpeg** for encoding/transcoding
- **Svelte/React** web UI for setup/monitoring
- **No database** — file-based config + transient streaming state
- **HLS segments** on local disk (tunable retention)
- **Resource**: DOMINATED by FFmpeg transcoding — plan CPU/GPU budget
  - Software x264 720p30 = ~1-2 cores
  - Hardware-accel (Cuda/VAAPI/Pi hardware) = near-idle CPU

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Docker `datarhei/restreamer:latest`**                            | **Upstream-flagship**                                                              |
| Raspberry Pi       | `datarhei/restreamer:rpi-latest` + `--privileged` for HW accel             | **Popular** — Pi 4 / Pi 5 run well                                                         |
| NVIDIA GPU         | `datarhei/restreamer:cuda-latest` + `--runtime=nvidia`                                 | **Best transcoding performance**                                                                       |
| Intel VAAPI        | `datarhei/restreamer:vaapi-latest` + `/dev/dri`                                                     | iGPU acceleration                                                                                              |
| Kubernetes         | Works with proper device-plugin configuration                                                                          | Advanced                                                                                                                    |
| NAS                | Depends on NAS CPU / codec availability                                                                                               | Synology DS-series often OK for low-res                                                                                                                                     |

## Inputs to collect

| Input                | Example                                          | Phase        | Notes                                                                    |
| -------------------- | ------------------------------------------------ | ------------ | ------------------------------------------------------------------------ |
| Input source         | OBS RTMP push to `rtmp://host:1935/live/main`        | Ingest       | Or RTSP/SRT/HLS                                                                  |
| Output destinations  | YouTube stream key, Twitch stream key, etc.                   | Restream     | **Treat stream keys as secrets**                                                             |
| HW acceleration      | `cuda` / `vaapi` / `rpi` / software                             | Perf         | Pick variant matching your hardware                                                                      |
| Domain + TLS         | `stream.home.lan` + Let's Encrypt                                 | URL          | Built-in LE support                                                                                       |
| Bandwidth budget     | Upload capacity for all restream destinations simultaneously                   | Network      | Each restream = full output bitrate                                                                                      |
| Admin                | `admin` / `datarhei` defaults for demo — **CHANGE IMMEDIATELY**                          | Bootstrap    | Default creds in first-run flow                                                                                                   |

## Install via Docker (typical AMD64)

```sh
docker run -d --restart=always --name restreamer \
   -v /opt/restreamer/config:/core/config \
   -v /opt/restreamer/data:/core/data \
   -p 8080:8080 -p 8181:8181 \
   -p 1935:1935 -p 1936:1936 \
   -p 6000:6000/udp \
   datarhei/restreamer:latest
```

Or with Compose. For HW accel, swap image tag + add `--runtime=nvidia` / `--device /dev/dri` / `--privileged`.

## First boot

1. Browse `http://<host>:8080/ui` → setup wizard
2. Set admin creds (**do NOT use demo creds in production**)
3. Configure input (wizard walks through)
4. Add output destinations: YouTube Live / Twitch / custom RTMP (**paste stream keys carefully — treat like passwords**)
5. Start stream; verify each output has green "live" indicator
6. (Optional) Enable Let's Encrypt for your domain → `:8181` becomes HTTPS
7. Embed VideoJS player snippet on your website OR use Restreamer's built-in publication page
8. Configure bandwidth limits if public-facing

## Data & config layout

- `/core/config/` — config.json, certs, etc.
- `/core/data/` — HLS segments, recordings, thumbnails

## Backup

```sh
sudo tar czf restreamer-config-$(date +%F).tgz /opt/restreamer/config/
```

HLS segments are ephemeral; don't back up. If you want to save recordings, they live in `/core/data/` — large; back up selectively.

## Upgrade

1. Releases: <https://github.com/datarhei/restreamer/releases>. Active. Based on `datarhei/core`.
2. `docker pull datarhei/restreamer:<variant>-latest` → recreate.
3. **Back up `/core/config/` first.** Stream-key loss = reconfig all outputs.
4. Major version jumps: test on staging; config schema evolves.

## Gotchas

- **Bandwidth = your bottleneck, always.** Each restream output consumes full output bitrate (e.g., 5 Mbps × 3 platforms = 15 Mbps upload). Residential fiber upload often limits real-world restream count to 2-3. Measure your actual upload (fast.com / iperf) before promising clients anything.
- **Stream keys are credentials** — treat like passwords. Anyone with your YouTube stream key can publish to YOUR channel. Store in Restreamer's encrypted config; don't paste into chat/git/etc.
- **Default demo creds `admin` / `datarhei`** (per demo URL) — this is specifically for the demo instance; always set your own on first run. Reflex from batches 68+ patterns.
- **Hardware acceleration selection**: `cuda`, `vaapi`, `rpi` variants have different base images + device requirements. Pick the right variant; wrong one = software fallback + CPU-pegged.
  - NVIDIA: `nvidia-container-toolkit` installed + `--runtime=nvidia`
  - Intel: `/dev/dri` mount + user in `video` group
  - Raspberry Pi: use `rpi-latest` tag
- **`--privileged` with explicit justification**: only when using LOCAL USB cameras or hardware encoders that need deep device access. For remote RTMP/SRT sources, DON'T use privileged. Drop it.
- **`--security-opt seccomp=unconfined`** is a documented workaround for network-source issues but **weakens container isolation**. Use only if necessary + document why.
- **FFmpeg = the CPU/GPU sink.** Real performance tuning happens in FFmpeg flags. Expose them in Restreamer's advanced settings; dial in preset/bitrate/keyframe interval per platform.
- **Stream latency**: HLS output = 10-30 second latency (segment size). SRT input + RTMP output ~2-4 sec. For ultra-low-latency use WebRTC-based tools (not Restreamer's target).
- **Bandwidth monitoring**: built-in; use it. Set limits so runaway viewers don't blow your ISP cap.
- **GDPR-friendly**: no third-party trackers + no audience-data persistence (upstream claim). Good default for EU compliance.
- **Let's Encrypt port 80 reachability**: ACME HTTP-01 challenge needs port 80 publicly reachable. Alternative: terminate TLS at reverse proxy.
- **Multiple simultaneous ingests** — possible but CPU/bandwidth scales linearly.
- **Transcoding vs pass-through**: if all output platforms accept your input codec + bitrate, use pass-through (no re-encode) to save massive CPU. Only transcode if a platform demands different params.
- **Recording**: Restreamer can record streams locally. Big files — allocate disk + retention plan.
- **Commercial version / Core**: datarhei also offers `datarhei/core` (lower-level building block). Restreamer is the turnkey product. Paid support available.
- **License**: **Apache-2.0** (source).
- **Alternatives worth knowing:**
  - **nginx-rtmp-module** — ancient; solid; no UI; DIY restream
  - **MediaMTX (was rtsp-simple-server)** — Go; multi-protocol; more recent
  - **OvenMediaEngine** — enterprise-grade multi-protocol
  - **SRS (Simple Realtime Server)** — Chinese-origin; high-perf
  - **Ant Media Server** — commercial + community edition
  - **Restream.io / StreamYard / Castr** — commercial SaaS
  - **OBS + multi-stream plugin** — OBS-side restream; higher CPU cost on streaming machine
  - **Choose Restreamer if:** turnkey UI + multi-platform restream + homelab HW budget.
  - **Choose MediaMTX if:** protocol-layer tool + script-driven.
  - **Choose nginx-rtmp if:** minimal + just need RTMP relay.
  - **Choose commercial SaaS if:** don't want to manage upload bandwidth or hardware.

## Links

- Repo: <https://github.com/datarhei/restreamer>
- Docs: <https://docs.datarhei.com/restreamer/getting-started/quick-start>
- Demo: <https://demo.datarhei.com/ui>
- Docker Hub: <https://hub.docker.com/r/datarhei/restreamer>
- Releases: <https://github.com/datarhei/restreamer/releases>
- Core (lower-level): <https://github.com/datarhei/core>
- datarhei: <https://datarhei.com>
- MediaMTX (alt): <https://github.com/bluenviron/mediamtx>
- nginx-rtmp (alt): <https://github.com/arut/nginx-rtmp-module>
- SRS (alt): <https://github.com/ossrs/srs>
