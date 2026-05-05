---
name: SRS (Simple Realtime Server)
description: "High-efficiency open-source media streaming server supporting RTMP, WebRTC, HLS, HTTP-FLV, SRT, and MPEG-DASH. C++. MIT."
---

# SRS (Simple Realtime Server)

SRS is a simple, high-efficiency, real-time video streaming server that supports the full spectrum of live streaming protocols: RTMP, WebRTC, HLS, HTTP-FLV, SRT, MPEG-DASH, and GB28181. Written in C++, it runs as a single binary with Docker as the recommended deployment method.

Maintained by the ossrs.io team. Active development; v6 stable, v7 in development.

Use cases: (a) live streaming ingest + distribution (OBS → HLS/DASH/WebRTC) (b) WebRTC conferencing and SFU (c) low-latency live video for apps (d) RTMP → WebRTC conversion (e) DVR/recording of live streams (f) large-scale streaming infrastructure.

Features:

- **Protocol support** — RTMP, WebRTC, HLS, HTTP-FLV, SRT, MPEG-DASH, RTSP, GB28181
- **Codec support** — H.264, H.265, AV1, VP9, AAC, Opus, G.711
- **Architecture** — single-node and cluster modes
- **WebRTC** — publish/subscribe; RTMP↔WebRTC conversion; SFU mode
- **HLS** — generates HLS segments from RTMP ingest
- **DVR** — record live streams to MP4/FLV files
- **Transcoding** — FFmpeg-based transcoding pipelines
- **HTTP API** — full REST API for stream management, stats, and control
- **HTTP callbacks** — webhook notifications on stream publish/play/stop
- **Cluster/CDN** — edge/origin architecture for large-scale distribution
- **Stats and monitoring** — built-in HTTP stats endpoint
- **Platform** — Linux (X86_64, ARMv7, AARCH64, M1, RISC-V, LoongArch, MIPS)

- Upstream repo: https://github.com/ossrs/srs
- Homepage: https://ossrs.io/
- Docs (EN): https://ossrs.io/lts/en-us/docs/v6/doc/getting-started
- Docs (CN): https://ossrs.net/lts/zh-cn/docs/v6/doc/getting-started

## Architecture

- **Single C++ binary** — all protocols handled in-process
- **Coroutine-based** — SRS uses ST (State Threads) for high concurrency with low overhead
- **Docker recommended** — official `ossrs/srs` image
- **Configuration** — single `srs.conf` file
- **Ports**:
  - `1935` — RTMP
  - `1985` — HTTP API
  - `8080` — HTTP server (HLS, HTTP-FLV, stats page)
  - `8000/udp` — WebRTC
  - `10080/udp` — SRT

## Compatible install methods

| Infra       | Runtime              | Notes                                                           |
|-------------|----------------------|-----------------------------------------------------------------|
| Docker      | `ossrs/srs:6`        | Recommended; official image; single command start               |
| Docker      | docker compose       | Multi-container with FFmpeg, Prometheus, etc.                   |
| Bare-metal  | Binary               | Build from source or download release binary                    |
| Kubernetes  | Helm chart           | ossrs provides Helm charts for cluster deployments              |
| ARM         | Docker               | Multi-arch image; runs on Raspberry Pi                          |

## Inputs to collect

| Input           | Example                  | Phase   | Notes                                                            |
|-----------------|--------------------------|---------|------------------------------------------------------------------|
| RTMP ingest URL | `rtmp://host/live/key`   | Stream  | Configure in OBS/encoder as "Custom RTMP"                        |
| Playback URL    | `http://host:8080/live/key.m3u8` | Play | HLS playback                                             |
| API key (opt)   | HTTP basic auth          | Security| Secure the HTTP API; not enabled by default                      |
| DVR path (opt)  | `/data/recordings/`      | DVR     | Mount as Docker volume for persistence                           |

## Quick start (Docker)

```sh
docker run --rm -it \
  -p 1935:1935 \
  -p 1985:1985 \
  -p 8080:8080 \
  -p 8000:8000/udp \
  -p 10080:10080/udp \
  ossrs/srs:6

# Verify: open http://localhost:8080/
```

Stream from OBS:
- Service: Custom
- Server: `rtmp://localhost/live`
- Stream Key: `livestream`

Play HLS: `http://localhost:8080/live/livestream.m3u8`
Play HTTP-FLV: `http://localhost:8080/live/livestream.flv`

## Custom config (docker compose)

```yaml
services:
  srs:
    image: ossrs/srs:6
    ports:
      - "1935:1935"
      - "1985:1985"
      - "8080:8080"
      - "8000:8000/udp"
      - "10080:10080/udp"
    volumes:
      - ./srs.conf:/usr/local/srs/conf/srs.conf
      - ./recordings:/data/recordings
    restart: unless-stopped
```

`srs.conf` example with HLS + DVR:

```
listen              1935;
max_connections     1000;
http_server { enabled on; listen 8080; dir ./objs/nginx/html; }
http_api    { enabled on; listen 1985; }
vhost __defaultVhost__ {
  hls { enabled on; hls_path /data/recordings; hls_fragment 3; }
  dvr { enabled on; dvr_path /data/recordings/[app]/[stream].[timestamp].mp4; dvr_plan session; }
}
```

## Key HTTP API endpoints

```
GET http://localhost:1985/api/v1/streams    # list active streams
GET http://localhost:1985/api/v1/clients    # list connected clients
GET http://localhost:1985/api/v1/summaries  # server stats
POST http://localhost:1985/api/v1/clients/<id>  # kick client
```

## Data & config layout

- **`srs.conf`** — all configuration; one file
- **`objs/`** — HLS segments, logs (inside container; mount as volume for persistence)
- **DVR recordings** — wherever `dvr_path` points; mount as volume

## Upgrade

```sh
docker pull ossrs/srs:6
docker compose up -d
```

Check https://github.com/ossrs/srs/blob/develop/trunk/doc/Features.md for version changes.

## Gotchas

- **UDP ports are critical for WebRTC and SRT** — `8000/udp` and `10080/udp` must be open on firewall/security groups. TCP-only firewall rules miss these and WebRTC/SRT will silently fail.
- **RTMP → WebRTC conversion requires explicit config** — bridge between protocols needs to be enabled in `srs.conf`. It doesn't work automatically; see the WebRTC docs.
- **HLS latency is inherently high** — HLS segments are typically 3–10 seconds, total latency 15–30s. For low-latency streaming, use HTTP-FLV (2–5s) or WebRTC (<1s). HLS is best for compatibility/CDN distribution.
- **SRT and GB28181 protocols** — SRT is well-supported in v6 and ideal for contribution links (broadcast-grade). GB28181 is a Chinese surveillance camera protocol; only relevant for IP camera integration in that ecosystem.
- **Cluster configuration is complex** — for multi-node CDN-style distribution, SRS uses edge/origin architecture. This requires careful network config; start single-node before attempting cluster.
- **Documentation is bilingual but incomplete in English** — some advanced topics have better coverage in Chinese docs (ossrs.net). Use browser translation if needed.
- **H.265/HEVC support** — supported for ingestion and HLS output in v6, but browser WebRTC support for H.265 is limited. Most browser players require H.264.
- **Alternatives:** Nginx-RTMP (simpler, RTMP/HLS only), MediaMTX (Go-based, excellent SRT/RTSP support), Oven Media Engine (WebRTC-focused, free tier), Ant Media Server (WebRTC SFU, free community edition), Wowza (commercial).

## Links

- Repo: https://github.com/ossrs/srs
- Homepage: https://ossrs.io/
- Getting started (EN): https://ossrs.io/lts/en-us/docs/v6/doc/getting-started
- Docker Hub: https://hub.docker.com/r/ossrs/srs
- Features list: https://github.com/ossrs/srs/blob/develop/trunk/doc/Features.md
- Changelog: https://github.com/ossrs/srs/blob/develop/CHANGELOG.md
- Discord: https://discord.gg/yZ4BnPmHAd
