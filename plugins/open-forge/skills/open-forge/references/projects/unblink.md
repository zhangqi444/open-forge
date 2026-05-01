---
name: Unblink
description: "AI-powered camera monitoring with relay-node architecture. Go + SolidJS + PostgreSQL. zapdos-labs/unblink. VLM frame analysis, natural language video search, chat with camera feeds, RTSP/MJPEG."
---

# Unblink

**AI-powered camera monitoring application with relay-node architecture.** Connect RTSP or MJPEG cameras through local nodes; the server provides a web UI with natural language interaction — ask questions about what's happening in camera feeds, search recorded frames using natural language, and get AI-generated summaries. Vision Language Model (VLM) powered by Qwen3-VL. Self-hostable.

Built + maintained by the **Zapdos Labs team**.

- Upstream repo: <https://github.com/zapdos-labs/unblink>
- Deploy: Render one-click deploy button in README

## Architecture in one minute

- **Go** backend server (publicly reachable) + **SolidJS** frontend
- **Local node** (`unblink-node`, Go binary) — runs in your private network, connects outward to the server, proxies camera streams
- **PostgreSQL** database
- **go2rtc** — handles RTSP/WebRTC stream translation
- **VLM**: Qwen3-VL for frame analysis and summarization (AI inference; requires access to model API)
- **Three components**: Server + Node + Web frontend (all in monorepo)
- Resource: **medium** — Go server + Postgres + VLM inference (inference can be heavy depending on model endpoint)

## Compatible install methods

| Infra             | Runtime               | Notes                                                                          |
| ----------------- | --------------------- | ------------------------------------------------------------------------------ |
| **Node binary**   | `unblink-node`        | **Primary for camera side** — prebuilt binary; run on any machine with cameras |
| **Render**        | one-click deploy      | "Deploy to Render" button in README; for the server component                  |
| **Source**        | Go + make             | Full dev environment via `make dev` (requires tmux)                            |

## Install the node (camera proxy)

The node runs on your local network, connects outward to the server:

**Without Go toolchain (prebuilt binary):**

```bash
# Download for your platform from GitHub Releases:
# linux_amd64: unblink-node_linux_amd64.tar.gz
# linux_arm64: unblink-node_linux_arm64.tar.gz
# windows_amd64: unblink-node_windows_amd64.zip

tar xzf unblink-node_linux_amd64.tar.gz
./unblink-node
# First run: opens a browser URL for authorization
```

**With Go toolchain:**

```bash
go install github.com/zapdos-labs/unblink/cmd/unblink-node@main
unblink-node
```

On first run, the node displays an authorization URL — open it in your browser to register the node with the server.

## Deploy the server

Use the Render one-click deploy (button in README) for the easiest server setup. Render handles Postgres, environment, and public URL.

Or build from source for custom deployment:

1. Clone repo → `make install`
2. Copy `.env.example` → `.env`; configure `DATABASE_URL`, VLM API endpoint, auth settings.
3. `make dev` (development, requires tmux) or build/run the server binary directly.

## First boot

1. Deploy server (Render or self-hosted).
2. Start `unblink-node` on the machine(s) with cameras → authorize in browser.
3. In the web UI, add camera streams (RTSP URLs, MJPEG URLs) to the node.
4. Streams are proxied through the node → server → web UI.
5. Use the **chat interface** to ask questions about camera feeds ("Is anyone in the kitchen?", "When did the last motion occur?").
6. Use **video search** to find frames matching a description ("person with red jacket").

## Architecture: server + node separation

The relay-node architecture means:

- **Node**: runs in your LAN; can reach cameras on local IP addresses; connects _outward_ to server (no inbound firewall rules needed on home network)
- **Server**: publicly reachable (Render / VPS); receives proxied streams; serves web UI; stores frame data in Postgres
- **Security**: cameras are never directly exposed to the internet; all traffic routes through the local node

## Environment variables (server)

Copy `.env.example` from the repo and configure:

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string |
| VLM endpoint | Qwen3-VL API URL + credentials |
| Auth settings | Server authentication config |

## Gotchas

- **VLM API required for AI features.** Qwen3-VL powers the frame analysis, chat, and search features. You need access to a Qwen3-VL inference endpoint (e.g. hosted Alibaba Cloud, or a local instance via Ollama/vLLM). Without it, streams display but AI features don't work.
- **Node first-run authorization is interactive.** The first time you run `unblink-node`, it opens a browser authorization URL. This is a one-time setup — subsequent runs connect automatically.
- **Render for the server.** The README's primary deployment path for the server is Render's one-click deploy. For self-hosted non-Render deployments, you'll need to build + configure manually from source (`.env.example` is your guide).
- **go2rtc handles RTSP/WebRTC.** go2rtc is the video streaming backbone; it translates RTSP camera streams to WebRTC for browser delivery. It's bundled with the node binary.
- **PostgreSQL required.** No SQLite option — Postgres is the only supported DB backend.
- **Early-stage project.** The README is minimal; architecture is novel (relay-node + VLM + video search is a cutting-edge combination). Expect rough edges and rapid evolution.
- **Windows node supported.** Run `.\unblink-node.exe` on Windows; same authorization flow.

## Project health

Active Go + SolidJS development, multi-platform prebuilt binaries, Render deploy template, Protobuf-based node↔server communication. Maintained by Zapdos Labs.

## AI-camera-monitoring-family comparison

- **Unblink** — Go + SolidJS, VLM (Qwen3-VL), relay-node, NL search + chat, RTSP/MJPEG, self-hosted
- **Frigate** — Python + Go, local NV inference (Coral/GPU), object detection events, most popular self-hosted AI camera
- **Agent DVR** — .NET, full NVR + AI features, freemium
- **Scrypted** — Node.js, HomeKit/Google Home bridge + AI plugins, rich integrations
- **Home Assistant + Frigate** — the most common self-hosted smart camera stack

**Choose Unblink if:** you want a self-hosted AI camera monitor where you can ask natural language questions about your camera feeds and search recorded frames semantically — and can provide a Qwen3-VL inference endpoint.

## Links

- Repo: <https://github.com/zapdos-labs/unblink>
- Node releases: <https://github.com/zapdos-labs/unblink/releases>
- Frigate (event-detection alt): <https://frigate.video>
