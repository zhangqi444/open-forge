---
name: MediaMTX
description: "Zero-dependency real-time media server and proxy — publish, read, record, and play back live video/audio streams; converts between SRT, WebRTC, RTSP, RTMP, HLS, MPEG-TS, and RTP protocols automatically. Single binary. Go. MIT."
---

# MediaMTX

MediaMTX (formerly **rtsp-simple-server**) is a **zero-dependency real-time media server and proxy** written in Go. It accepts live video/audio streams in one protocol and simultaneously serves them in other protocols — no FFmpeg required, no complex pipeline config, just one binary that speaks every major streaming protocol fluently.

Think of it as a **universal live-stream router**: your IP camera speaks RTSP; your browser wants WebRTC; your HLS player wants chunked HTTP segments; your recording system wants MPEG-TS files. MediaMTX handles all of it at once, auto-converting between protocols, with zero external dependencies.

Use cases: (a) re-streaming IP/CCTV cameras to web browsers via WebRTC/HLS (b) building a self-hosted RTMP ingest server (like a private Twitch ingest) (c) recording live streams to disk (d) feeding multiple consumers from one source stream (e) adding authentication and access control to camera feeds (f) Raspberry Pi / IoT camera streaming to browser (g) SRT transport for broadcast-grade low-latency delivery.

Features:

- **Protocol support**: SRT, WebRTC, RTSP/RTSPS, RTMP/RTMPS, HLS, MPEG-TS, RTP
- **Protocol auto-conversion** — publish in one protocol; read in any other; MediaMTX transcodes where needed
- **Recording** — write streams to disk as fMP4 or MPEG-TS; on-demand or continuous
- **Playback** — built-in HTTP server to play back recorded files
- **Authentication** — internal (username/password per path), HTTP callback (delegate to external API), or JWT
- **Control API** — REST API to list/add/remove paths and connections at runtime
- **Prometheus metrics** — `/metrics` endpoint; scrape with Prometheus + Grafana
- **Hot-reload config** — edit `mediamtx.yml`, send SIGHUP; no restart required
- **Single binary, no dependencies** — download and run; no runtime, no package manager, no Docker required (though Docker image available)

- Upstream repo: <https://github.com/bluenviron/mediamtx>
- Homepage: <https://mediamtx.org>
- Docs: <https://mediamtx.org/docs/kickoff/introduction>

## Architecture in one minute

- Single **Go binary** — cross-compiled for Linux/macOS/Windows/ARM
- **Path-based routing** — each stream lives at a path (`/cam1`, `/live/main`, etc.); publishers write to a path; readers subscribe to a path
- **Sources** — anything that publishes: cameras, OBS/encoders, FFmpeg, scripts, RTSP sources (MediaMTX can pull from external RTSP sources automatically)
- **Readers** — anything that subscribes: browsers (WebRTC/HLS), media players (VLC, ffplay), recording writers
- **Config file** (`mediamtx.yml`) — declarative; hot-reloadable
- **Resource**: extremely lean — 50–150 MB RAM for basic use; scales with concurrent streams + protocol conversion load

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Binary             | Download from GitHub releases, run directly                    | **Simplest path** — one file, no deps                                          |
| Docker             | `docker pull bluenviron/mediamtx`                              | Convenient for containerized stacks                                            |
| Docker Compose     | multi-service with reverse proxy                               | Recommended for production                                                     |
| systemd            | Install binary + write unit file                               | Persistent service on Linux                                                    |
| Raspberry Pi       | ARM binary available                                           | Popular for Pi camera streaming setups                                         |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Stream paths         | `/cam1`, `/live/studio`, `/events/main`                     | Config       | Logical names; publishers + readers use these                            |
| Auth method          | internal / HTTP / JWT                                       | Security     | Choose per path or globally                                              |
| Recording path       | `/data/recordings/`                                         | Storage      | Where recorded segments are written                                      |
| Port plan            | RTSP 8554, RTMP 1935, HLS 8888, WebRTC 8889, SRT 8890      | Networking   | Default ports; adjust per environment                                    |
| TLS certs            | cert.pem + key.pem                                          | Security     | For RTSPS/RTMPS/HTTPS delivery                                           |
| External source URLs | `rtsp://camera.local:554/stream`                            | Sources      | For pull-mode (MediaMTX polls source)                                    |

## Install (binary path)

```sh
# Download latest release (Linux amd64 example)
wget https://github.com/bluenviron/mediamtx/releases/latest/download/mediamtx_v1.18.1_linux_amd64.tar.gz
tar xzf mediamtx_*.tar.gz
# Runs immediately with default config
./mediamtx

# Or specify a config file
./mediamtx /path/to/mediamtx.yml
```

```yaml
# docker-compose.yml
version: "3.8"
services:
  mediamtx:
    image: bluenviron/mediamtx:latest
    network_mode: host          # required for WebRTC ICE (or configure iceHostNATs)
    volumes:
      - ./mediamtx.yml:/mediamtx.yml
      - ./recordings:/recordings
    restart: unless-stopped
```

Note: `network_mode: host` is recommended for WebRTC (ICE candidate discovery). If you cannot use host networking, configure `webrtcAdditionalHosts` in the config to specify your server's public IP.

## Key configuration (mediamtx.yml)

```yaml
# mediamtx.yml — annotated minimal config

# Logging
logLevel: info
logDestinations: [stdout]

# Protocols to enable/disable
rtspAddress: :8554
rtmpAddress: :1935
hlsAddress: :8888
webrtcAddress: :8889
srtAddress: :8890

# HLS settings
hlsAlwaysRemux: false    # set true to serve HLS even without active publisher
hlsSegmentDuration: 1s
hlsPartDuration: 200ms   # for low-latency HLS (LL-HLS)

# Recording
record: false            # set true globally, or per-path
recordPath: ./recordings/%path/%Y-%m-%d_%H-%M-%S-%f
recordFormat: fmp4       # or mpegts
recordSegmentDuration: 1h

# Auth — internal method
authMethod: internal
authInternalUsers:
  - user: publisher
    pass: secret123
    permissions:
      - action: publish
        path: live/studio
  - user: viewer
    pass: viewsecret
    permissions:
      - action: read
        path: live/studio

# Per-path configuration
paths:
  # Static pull source — MediaMTX fetches from IP camera
  cam1:
    source: rtsp://admin:pass@192.168.1.100:554/stream
    sourceOnDemand: true    # only connect when a reader is present
    record: true

  # Dynamic path — anyone can publish here
  live/~:
    publishUser: encoder
    publishPass: encoderpass

  # Redirect path
  all_others:
    # catchall path
```

## First boot

1. Run `./mediamtx` — listens on all protocol ports immediately
2. Test RTSP: `ffmpeg -re -i test.mp4 -c copy -f rtsp rtsp://localhost:8554/test`
3. Read back: `ffplay rtsp://localhost:8554/test`
4. Test HLS: `curl http://localhost:8888/test/index.m3u8`
5. Test WebRTC: Browse to `http://localhost:8889/test` for the built-in WebRTC player
6. Configure paths + auth in `mediamtx.yml`, send `SIGHUP` to reload: `kill -HUP $(pgrep mediamtx)`

## Control API

```sh
# List active paths
curl http://localhost:9997/v3/paths/list

# List active readers on a path
curl http://localhost:9997/v3/rtspconns/list

# Kick a session
curl -X DELETE http://localhost:9997/v3/rtspconns/kick/<id>

# Add a path at runtime
curl -X POST http://localhost:9997/v3/config/paths/add/newpath \
  -H "Content-Type: application/json" \
  -d '{"source": "rtsp://camera.local/stream"}'
```

## Recording and playback

```yaml
# Enable recording globally or per path
paths:
  cam1:
    record: true
    recordPath: /recordings/%path/%Y/%m/%d/%H-%M-%S
    recordFormat: fmp4
    recordSegmentDuration: 30m
    recordDeleteAfter: 720h   # auto-delete after 30 days
```

Playback via the built-in HTTP server:
```
http://localhost:8888/cam1/index.m3u8          # HLS (live)
http://localhost:8888/recordings/cam1/...mp4   # recorded file
```

## Prometheus metrics

```yaml
metrics: yes
metricsAddress: :9998
```

```
# scrape in prometheus.yml
- job_name: mediamtx
  static_configs:
    - targets: ['localhost:9998']
```

Key metrics: `mediamtx_paths`, `mediamtx_rtsp_connections`, `mediamtx_hls_muxers`, `mediamtx_webrtc_sessions`.

## Backup

MediaMTX itself is stateless (stream-through, not a database). Back up:
- `mediamtx.yml` — config file
- `./recordings/` directory — recorded stream files (if using recording)

No database to back up; restart resumes from config file state.

## Upgrade

1. Download new binary from <https://github.com/bluenviron/mediamtx/releases>
2. Stop current process (`systemctl stop mediamtx` or `docker stop mediamtx`)
3. Replace binary (or pull new Docker image)
4. Review changelog for config file format changes (rare but possible between major versions)
5. Start

## Gotchas

- **WebRTC + NAT/Docker**: WebRTC ICE requires the server to know its external IP for candidate advertisement. When running in Docker without host networking, or behind NAT, set `webrtcAdditionalHosts: [YOUR_PUBLIC_IP]` in config. Forgetting this causes WebRTC streams to fail for external viewers while working locally.
- **`network_mode: host` in Docker**: Required for reliable WebRTC. If you must use bridge networking, open the WebRTC port AND configure `webrtcAdditionalHosts`. SRT also benefits from host networking due to UDP handling.
- **SRT requires UDP**: Many firewalls block UDP. SRT listens on port 8890/UDP by default. Ensure your firewall/security group opens the SRT port if used.
- **Protocol conversion consumes CPU**: Converting RTSP → WebRTC involves decoding/re-encoding where codecs differ. If source codec (e.g., H.264) is already supported by WebRTC natively, passthrough is used and CPU stays low. Forcing transcoding (e.g., H.265 source → WebRTC which needs H.264) burns CPU proportional to stream count + resolution.
- **HLS latency**: Standard HLS latency is 6–30 seconds. Use Low-Latency HLS (LL-HLS) settings (`hlsPartDuration: 200ms`) for ~1–2 second latency. WebRTC is sub-second if latency is critical.
- **Segment duration vs latency trade-off**: Shorter HLS segments = lower latency but more HTTP requests and higher CDN cost. WebRTC is better for truly real-time use cases.
- **Recording disk space**: Continuous recording fills disk fast. Set `recordDeleteAfter` to auto-prune, and/or monitor disk usage. 1080p H.264 fMP4 runs ~1–3 GB/hour depending on bitrate.
- **Authentication is per-path and per-action**: A user can have `publish` permission on one path and `read` on another. Design your permission matrix before deployment; retrofitting auth is harder.
- **HTTP auth callback security**: If using HTTP auth callbacks, the callback endpoint must be available to MediaMTX at all times. A misconfigured or unavailable auth server blocks all stream access. Test failure modes.
- **RTMP vs RTMP Enhanced**: OBS supports "RTMP Enhanced" (supports H.265, AV1). Standard RTMP only supports H.264/AAC. If using modern OBS output profiles, ensure your MediaMTX version supports RTMP Enhanced.
- **Port conflicts**: RTMP 1935 may conflict with other media servers. RTSP 8554 is non-standard but rarely conflicts. Document your port plan before deploying alongside other services.
- **No UI for stream management**: MediaMTX has a control REST API but no built-in web dashboard. Use the API or build your own. Third-party dashboards exist (community-built).
- **Formerly rtsp-simple-server**: Documentation and community content using the old name still applies; the config format evolved with the rename but is largely backward-compatible.
- **Alternatives worth knowing:**
  - **Nginx-RTMP** — mature RTMP ingest + HLS; no WebRTC; more complex config; requires Nginx compilation
  - **Oven Media Engine (OME)** — WebRTC-first; great for sub-second delivery; more complex setup
  - **Ant Media Server** — full-featured; commercial editions; Java-based; heavier
  - **SRS (Simple Realtime Server)** — C++; RTMP + HLS + WebRTC; popular in China; good docs
  - **Janus** — WebRTC gateway; flexible but complex configuration
  - **Wowza** — commercial; enterprise feature set; expensive
  - **Choose MediaMTX if:** you want simplicity + zero deps + broad protocol support in one binary; IP camera re-streaming; self-hosted DVR/recording; small-to-medium scale.
  - **Choose SRS or OME if:** you need WebRTC-first with higher scale + more ecosystem.
  - **Choose Nginx-RTMP if:** you already run Nginx and want RTMP ingest without a separate binary.

## Links

- Repo: <https://github.com/bluenviron/mediamtx>
- Homepage: <https://mediamtx.org>
- Docs: <https://mediamtx.org/docs/kickoff/introduction>
- Docker Hub: <https://hub.docker.com/r/bluenviron/mediamtx>
- Releases: <https://github.com/bluenviron/mediamtx/releases>
- GitHub Discussions: <https://github.com/bluenviron/mediamtx/discussions>
