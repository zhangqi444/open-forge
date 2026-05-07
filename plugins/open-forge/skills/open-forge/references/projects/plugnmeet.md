---
name: plugNmeet
description: Scalable, open-source web conferencing system built on LiveKit/WebRTC. HD video/audio, screen sharing, whiteboard, E2EE, AI transcription, MP4 recording, RTMP broadcasting. Go backend. AGPLv3 licensed.
website: https://www.plugnmeet.org/
source: https://github.com/mynaparrot/plugNmeet-server
license: AGPL-3.0
stars: 456
tags:
  - video-conferencing
  - webrtc
  - meeting
  - collaboration
  - livekit
platforms:
  - Go
  - Docker
---

# plugNmeet

plugNmeet is a scalable, feature-rich web conferencing platform built on top of LiveKit (WebRTC infrastructure). It provides HD audio/video, screen sharing, virtual backgrounds, collaborative whiteboard with office file support, polls, breakout rooms, end-to-end encryption, AI transcription and summaries, MP4 recording, and RTMP/RTMPS broadcasting. Ready-to-use plugins for WordPress, Moodle, and Joomla.

Official site: https://www.plugnmeet.org/
Source (server): https://github.com/mynaparrot/plugNmeet-server
Source (client): https://github.com/mynaparrot/plugNmeet-client
Docs: https://www.plugnmeet.org/docs/
Demo: https://demo.plugnmeet.com/landing.html
Docker Hub: https://hub.docker.com/r/mynaparrot/plugnmeet-server

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux VM / VPS (2GB+ RAM) | Docker Compose (install script) | Recommended |
| Linux VM / VPS | Manual Docker setup | For custom deployments |

## Inputs to Collect

**Phase: Planning**
- Domain/hostname (required for TLS — LiveKit needs HTTPS/WSS)
- Email for Let's Encrypt certificate
- API key and secret (you choose these — used to authenticate API calls)
- Whether to enable recording (requires plugnmeet-recorder component)
- TURN server (plugNmeet can configure Coturn automatically)

## Software-Layer Concerns

**Install via official script (recommended):**

```bash
# Follow the complete installation guide at:
# https://www.plugnmeet.org/docs/installation
# The install script sets up all components:
# - LiveKit server
# - plugNmeet server
# - plugNmeet client (nginx-served)
# - Etherpad (shared notepad)
# - Coturn (TURN server)
# - Certbot (TLS)
```

**Core components (all deployed together):**

| Component | Image | Purpose |
|-----------|-------|---------|
| plugnmeet-server | mynaparrot/plugnmeet-server | API backend (Go) |
| plugnmeet-client | mynaparrot/plugnmeet-client | React frontend |
| livekit | livekit/livekit-server | WebRTC media server |
| plugnmeet-etherpad | mynaparrot/plugnmeet-etherpad | Shared notepad |
| plugnmeet-recorder | mynaparrot/plugnmeet-recorder | MP4 recording + RTMP |
| coturn | coturn/coturn | TURN/STUN server |

**Key config file: `plugnmeet.toml`**

```toml
[client]
port = 8080
debug_mode = false

[livekit_info]
host = "http://livekit:7880"
api_key = "LIVEKIT_API_KEY"
api_secret = "LIVEKIT_API_SECRET"

[plugNmeet_info]
api_key = "YOUR_PLUGNMEET_API_KEY"
api_secret = "YOUR_PLUGNMEET_API_SECRET"

[database_info]
database_name = "plugnmeet"
username = "plugnmeet"
password = "CHANGE_ME"
```

**Create a meeting room via API:**

```bash
curl -X POST https://plugnmeet.example.com/auth/room/create \
  -H "Content-Type: application/json" \
  -d '{
    "room_id": "my-room",
    "metadata": {
      "room_title": "Team Meeting",
      "welcome_message": "Welcome!",
      "max_participants": 50
    }
  }' \
  --header "API-KEY: YOUR_API_KEY" \
  --header "HASH-SIGNATURE: <hmac_sha256_of_body>"
```

Use the official PHP or JavaScript SDK to handle HMAC signing:
- PHP SDK: https://github.com/mynaparrot/plugNmeet-sdk-php
- JS SDK: https://github.com/mynaparrot/plugNmeet-sdk-js

**CMS Integrations:**
- WordPress: https://github.com/mynaparrot/plugNmeet-wordpress
- Moodle: https://github.com/mynaparrot/moodle-mod_plugnmeet
- Joomla: https://github.com/mynaparrot/plugNmeet-joomla

## Upgrade Procedure

1. `docker compose pull`
2. `docker compose down && docker compose up -d`
3. Check release notes: https://github.com/mynaparrot/plugNmeet-server/releases

## Gotchas

- **TLS required**: LiveKit and plugNmeet require HTTPS/WSS — do not run without a valid TLS certificate
- **Ports**: LiveKit requires UDP port 7882 (or a configured range) open for WebRTC media — TCP alone is insufficient for good call quality
- **TURN server**: Required for participants behind strict NAT; Coturn is bundled in the install script
- **API authentication**: All API calls use HMAC-SHA256 signature — use the official SDKs to avoid manual signing errors
- **Recording component**: plugnmeet-recorder is a separate Go service — only needed if you want MP4 recording or RTMP broadcasting
- **AGPL license**: Modifications to plugNmeet must be shared under AGPL if deployed publicly
- **Resource requirements**: Recommend at least 2 vCPU and 4GB RAM for a small deployment; LiveKit is CPU-intensive for transcoding

## Links

- Upstream README: https://github.com/mynaparrot/plugNmeet-server/blob/main/README.md
- Installation guide: https://www.plugnmeet.org/docs/installation
- API docs: https://www.plugnmeet.org/docs/api/intro
- Demo: https://demo.plugnmeet.com/landing.html
- Client repo: https://github.com/mynaparrot/plugNmeet-client
- Recorder repo: https://github.com/mynaparrot/plugNmeet-recorder
