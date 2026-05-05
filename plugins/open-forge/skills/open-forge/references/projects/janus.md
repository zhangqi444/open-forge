---
name: Janus WebRTC Server
description: "Open-source general-purpose WebRTC server — plugin-based gateway supporting video conferencing, streaming, recording, SIP bridging, and data channels. C. GPL-3.0."
---

# Janus WebRTC Server

Janus is a lightweight, general-purpose, open-source WebRTC server developed by Meetecho. It acts as a WebRTC gateway with a plugin architecture — each plugin handles a specific use case (video room conferencing, SFU streaming, audio bridge, SIP integration, recording, etc.). Janus handles the WebRTC signaling and media transport; plugins handle the application logic.

Widely used as the WebRTC infrastructure layer for video conferencing apps, live streaming platforms, and communication products.

Use cases: (a) multi-party video conferencing (VideoRoom plugin) (b) live WebRTC streaming to many viewers (Streaming plugin) (c) audio-only conferencing/bridge (AudioBridge plugin) (d) WebRTC↔SIP gateway (SIP plugin) (e) WebRTC recording (Record&Play plugin) (f) building custom WebRTC applications on a flexible base.

Features:

- **Plugin architecture** — each use case is a plugin; mix and match what you need
- **VideoRoom plugin** — SFU-based multi-party video conferencing
- **Streaming plugin** — ingest RTSP/RTP/multicast → distribute via WebRTC
- **AudioBridge plugin** — multi-party audio mixing
- **SIP plugin** — WebRTC↔SIP gateway
- **Record & Play plugin** — record WebRTC sessions; replay
- **Data channels** — WebRTC data channel support
- **Transport protocols** — REST HTTP, WebSockets, RabbitMQ, MQTT, Nanomsg for Janus API
- **DTLS/SRTP, ICE** — full WebRTC security stack
- **Clustering** — multiple Janus instances for scale
- **Demo applications** — reference HTML/JS demos for all plugins

- Upstream repo: https://github.com/meetecho/janus-gateway
- Homepage: https://janus.conf.meetecho.com/
- Docs: https://janus.conf.meetecho.com/docs/
- Demos: https://janus.conf.meetecho.com/demos/

## Architecture

- **C** — single Janus binary + loadable plugins (.so)
- **ICE/STUN/TURN** — uses libnice for ICE negotiation; needs STUN/TURN for NAT traversal
- **Signaling** — REST (via libmicrohttpd) or WebSockets (via libwebsockets); your app connects to Janus API
- **Media** — SRTP/DTLS for media encryption; RTP for media streams
- **Plugins** — loaded dynamically at startup; configured in `janus.plugin.*.cfg`

Janus does **not** include a TURN server. For production behind NAT, deploy a TURN server (coturn is the standard choice) separately.

## Compatible install methods

| Infra       | Runtime               | Notes                                                        |
|-------------|-----------------------|--------------------------------------------------------------|
| Linux       | Build from source     | Standard path; many dependencies via package manager         |
| Docker      | `canyan/janus-gateway` or build own | No official image; community images available  |
| Debian/Ubuntu | PPA packages        | Meetecho PPA available; easier than building from source     |
| macOS       | Build from source     | Works; not for production                                    |

## Dependencies (Ubuntu/Debian)

```sh
sudo apt install libmicrohttpd-dev libjansson-dev \
  libssl-dev libsrtp2-dev libsofia-sip-ua-dev libglib2.0-dev \
  libopus-dev libogg-dev libcurl4-openssl-dev pkg-config \
  libconfig-dev libtool automake git cmake

# libnice (ICE library) - needs version >= 0.1.16
sudo apt install libnice-dev

# libwebsockets (for WebSocket transport)
sudo apt install libwebsockets-dev
```

## Build from source

```sh
git clone https://github.com/meetecho/janus-gateway.git
cd janus-gateway
sh autogen.sh
./configure --prefix=/opt/janus
make
make install
make configs  # copies sample configs to /opt/janus/etc/janus/
```

See https://janus.conf.meetecho.com/docs/index.html for full dependency and build instructions.

## Configuration

Janus uses multiple config files under `/opt/janus/etc/janus/`:

- **`janus.jcfg`** — main server config (ports, STUN/TURN, security)
- **`janus.transport.http.jcfg`** — REST API transport
- **`janus.transport.websockets.jcfg`** — WebSocket transport
- **`janus.plugin.videoroom.jcfg`** — VideoRoom plugin config
- **`janus.plugin.streaming.jcfg`** — Streaming plugin config
- *(one file per plugin)*

## Key config (janus.jcfg)

```
general: {
    configs_folder = "/opt/janus/etc/janus"
    plugins_folder = "/opt/janus/lib/janus/plugins"
    transports_folder = "/opt/janus/lib/janus/transports"
    log_to_file = "/opt/janus/var/log/janus/janus.log"
}

nat: {
    stun_server = "stun.l.google.com"
    stun_port = 19302
    # For production with TURN:
    turn_server = "your-coturn-server.example.com"
    turn_port = 3478
    turn_user = "janus"
    turn_pwd = "yourpassword"
}

media: {
    rtp_port_range = "10000-10200"
}
```

## Run

```sh
/opt/janus/bin/janus --configs-folder=/opt/janus/etc/janus
# REST API at http://localhost:8088/janus
# WebSocket at ws://localhost:8188/
```

## Ports to open

| Port       | Protocol | Purpose                              |
|------------|----------|--------------------------------------|
| 8088       | TCP      | HTTP REST API                        |
| 8188       | TCP      | WebSocket                            |
| 8989       | TCP      | HTTPS REST API (if TLS configured)   |
| 8989       | TCP      | WSS WebSocket (if TLS configured)    |
| 10000-10200| UDP      | RTP media (configure range in config)|
| 3478       | UDP/TCP  | TURN server (coturn, separate)       |

## Gotchas

- **TURN server required for production** — WebRTC direct peer connection often fails behind symmetric NAT (corporate firewalls, mobile networks). Deploy coturn alongside Janus and configure Janus to use it as a TURN server. Without TURN, many users won't be able to connect.
- **Build complexity** — Janus has many optional dependencies. The build process works but requires patience; missing a dependency disables a feature silently. Check `./configure` output carefully.
- **No built-in signaling UI** — Janus provides WebRTC infrastructure; you build the signaling layer (web app, mobile app) on top. The demo HTML pages are examples, not production UIs.
- **VideoRoom is SFU, not MCU** — VideoRoom uses Selective Forwarding Unit (SFU) architecture. Each viewer receives individual streams from each publisher (good for scalability); there's no server-side mixing (MCU). For mixed audio with a single stream, use AudioBridge.
- **Plugin API stability** — the Janus JavaScript API is the stable interface; internal C APIs can change between versions. Updating Janus may require re-testing your client app.
- **RTP port range must be open** — the UDP port range for media (default: auto-selected, configure `rtp_port_range`) must be accessible from the internet for WebRTC media to flow. In cloud environments, open this range in security groups.
- **No native recording storage** — the Record&Play plugin records to local disk only. For S3/cloud storage, you need to implement a post-recording upload step.
- **Alternatives:** Mediasoup (Node.js SFU; easier API for developers), LiveKit (Go SFU; excellent developer experience, TURN included), Jitsi Meet (full video conferencing stack built on Janus + more), Kurento (Java/C++ SFU), Daily.co (SaaS).

## Links

- Repo: https://github.com/meetecho/janus-gateway
- Homepage: https://janus.conf.meetecho.com/
- Documentation: https://janus.conf.meetecho.com/docs/
- Demos: https://janus.conf.meetecho.com/demos/
- Community forum: https://janus.discourse.group/
- JavaScript API: https://janus.conf.meetecho.com/docs/JS.html
