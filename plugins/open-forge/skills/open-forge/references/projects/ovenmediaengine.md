---
name: ovenmediaengine
description: OvenMediaEngine recipe for open-forge. Sub-second latency live streaming server — ingest via RTMP/SRT/WebRTC/WHIP, transcode ABR, deliver via LLHLS and WebRTC to large audiences. Docker install. Upstream: https://github.com/AirenSoft/OvenMediaEngine
---

# OvenMediaEngine

Sub-second latency live streaming server. Ingest streams over RTMP, SRT, WebRTC/WHIP, RTSP, or MPEG-TS; transcode with adaptive bitrate; deliver at scale via Low Latency HLS (LLHLS) and WebRTC to hundreds of thousands of viewers.

3,127 stars · AGPL-3.0

Upstream: https://github.com/AirenSoft/OvenMediaEngine
Website: https://airensoft.gitbook.io/ovenmediaengine/
Docs: https://airensoft.gitbook.io/ovenmediaengine/
Demo: https://space.ovenplayer.com/
Docker Hub: https://hub.docker.com/r/airensoft/ovenmediaengine

## What it is

OvenMediaEngine (OME) provides a complete live streaming pipeline:

- **Ingest protocols** — RTMP, SRT, WebRTC (WHIP/Simulcast), RTSP (pull), MPEG-2 TS/UDP, OVT
- **Adaptive Bitrate (ABR)** — Built-in live transcoder: VP8, H.264, H.265 (hardware), Opus, AAC, pass-through
- **LLHLS delivery** — Low Latency HLS with DVR (live rewind), VoD dump, DRM (Widevine/Fairplay), subtitles
- **WebRTC delivery** — Sub-second latency via embedded WebRTC signaling and TURN server
- **SRT output** — Secure Reliable Transport for low-latency contribution or delivery
- **Clustering** — Origin-edge topology for horizontal scale-out
- **Access control** — Admission Webhooks, Signed Policy
- **File recording** — Record streams to local files
- **Push publishing** — Re-stream to other endpoints (RTMP, SRT, MPEG-TS)
- **Thumbnails** — Auto-generate stream thumbnails
- **REST API** — Full management and monitoring API
- **Scheduled channels** — Pre-recorded content as live streams
- **Multiplex channels** — Duplicate streams / mux tracks

Companion tools: OvenPlayer (web player), OvenLiveKit (WebRTC publisher SDK).

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker | Single or origin+edge | Official airensoft/ovenmediaengine image |
| Docker Compose | origin + edge | For CDN-style origin-edge clustering |
| Bare metal | Ubuntu 18+, Rocky/Alma 8+, Fedora 28+ | Build from source or use binary releases |

## Inputs to collect

### Phase 1 — Pre-install
- Public host IP (OME_HOST_IP) — required for WebRTC ICE candidates
- Ports to open (see below — many UDP ports required)
- Ingest protocols to enable (RTMP, SRT, WebRTC, RTSP)
- Output protocols to enable (LLHLS, WebRTC)
- TLS certificate paths (optional, for HTTPS/WSS)

## Software-layer concerns

### Required open ports
  TCP 9000  — OVT (Origin-to-Edge)
  TCP 1935  — RTMP ingest
  UDP 9999  — SRT ingest
  TCP 3333  — WebRTC signaling + LLHLS (HTTP)
  TCP 3334  — WebRTC signaling + LLHLS (HTTPS/TLS, optional)
  TCP 3478  — WebRTC TURN relay
  UDP 10000-10009 — WebRTC media candidates (ICE)

All must be reachable from the internet for external publishers/viewers.

### Config file (Server.xml)
OME is configured via an XML file mounted into the container:
- /opt/ovenmediaengine/bin/origin_conf/Server.xml
Default config is embedded in the image; mount your own to customize.

### Key environment variables
  OME_HOST_IP=<your-public-ip>     # required for WebRTC ICE
  OME_ORIGIN_PORT=9000
  OME_RTMP_PROV_PORT=1935
  OME_SRT_PROV_PORT=9999
  OME_LLHLS_STREAM_PORT=3333
  OME_WEBRTC_SIGNALLING_PORT=3333
  OME_WEBRTC_TCP_RELAY_PORT=3478
  OME_WEBRTC_CANDIDATE_PORT=10000-10004/udp

Note: LLHLS and WebRTC signaling must use different ports if both are enabled simultaneously.

## Docker quick start

  docker run --name ome -d \
    -e OME_HOST_IP=<your-public-ip> \
    -p 1935:1935 \
    -p 9999:9999/udp \
    -p 9000:9000 \
    -p 3333:3333 \
    -p 3478:3478 \
    -p 10000-10009:10000-10009/udp \
    airensoft/ovenmediaengine:latest

## Docker Compose (origin + edge)

  version: '3.6'
  services:
    origin:
      image: airensoft/ovenmediaengine:latest
      restart: always
      ports:
        - "9000:9000/tcp"       # OVT
        - "1935:1935/tcp"       # RTMP
        - "9999:9999/udp"       # SRT
        - "3333:3333/tcp"       # WebRTC/LLHLS signaling
        - "3478:3478/tcp"       # TURN
        - "10000-10004:10000-10004/udp"  # WebRTC media
      environment:
        - OME_HOST_IP=<origin-public-ip>

    edge:
      image: airensoft/ovenmediaengine:latest
      restart: always
      ports:
        - "4333:3333/tcp"       # Edge WebRTC/LLHLS
        - "3479:3479/tcp"       # Edge TURN
        - "10005-10009:10005-10009/udp"

Custom config: uncomment volumes and mount ./origin_conf/Server.xml

## Upgrade procedure

1. docker pull airensoft/ovenmediaengine:latest
2. docker compose up -d --force-recreate
3. Verify stream ingest and playback via OvenPlayer demo or REST API

## Gotchas

- OME_HOST_IP is critical — WebRTC ICE candidates include this IP; if wrong, viewers can't connect; use public IP, not internal/Docker IP
- UDP port range — 10000-10009 UDP must be open end-to-end; cloud security groups often block UDP ranges by default
- LLHLS vs WebRTC port conflict — both use port 3333 by default but in different modes; set different ports if enabling both
- AGPL-3.0 — modifications must be open-sourced; embedding in proprietary closed products requires a commercial license from AirenSoft
- Server.xml for customization — default config is a starting point; production deployments need custom Server.xml for virtual hosts, TLS, auth, etc.
- Hardware transcoding — H.265 encoding requires hardware (NVIDIA/Intel QSV); CPU-only transcoding supports VP8, H.264, Opus, AAC
- OvenPlayer pairing — OvenMediaEngine pairs with OvenPlayer (https://github.com/AirenSoft/OvenPlayer) for the web player UI

## Links

- Upstream README: https://github.com/AirenSoft/OvenMediaEngine/blob/master/README.md
- Documentation: https://airensoft.gitbook.io/ovenmediaengine/
- Quick Start: https://airensoft.gitbook.io/ovenmediaengine/quick-start
- OvenPlayer: https://github.com/AirenSoft/OvenPlayer
- Docker Hub: https://hub.docker.com/r/airensoft/ovenmediaengine
