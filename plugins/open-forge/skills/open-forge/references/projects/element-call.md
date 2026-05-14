---
name: element-call
description: Recipe for Element Call — open-source, self-hosted group video/audio calling built on Matrix/MatrixRTC.
---

# Element Call

Group video and audio calls powered by Matrix, implementing the MatrixRTC spec (MSC4143/MSC4195). A static web app that connects to a Matrix homeserver for signaling, with LiveKit SFU as the required MatrixRTC backend. No proprietary server components — calls are federated over Matrix. Upstream: <https://github.com/element-hq/element-call>. Docs: <https://element-call.netlify.app>. Hosted demo: <https://call.element.io>. License: AGPL-3.0.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Download pre-built tarball + static web server | <https://github.com/element-hq/element-call/releases> | Yes | **Recommended** — no build step needed; serve static files |
| Build from source + static web server | <https://github.com/element-hq/element-call#host-it-yourself> | Yes | For custom builds or latest dev |
| Hosted service | <https://call.element.io> | Yes (managed) | No self-hosting needed; Element.io-run instance |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | Public domain/URL for Element Call? | HTTPS URL | All; required for CORS + homeserver config |
| software | Matrix homeserver URL? | HTTPS URL (default: same domain on port 8008) | Required |
| software | Allow guest/unregistered users to join calls? | Boolean | Requires open registration on the homeserver |
| software | LiveKit SFU URL + lk-jwt-service? | URLs + credentials | Required for MatrixRTC; deploy alongside homeserver |

## Software-layer concerns

### Deploy from pre-built tarball (recommended)

Download the latest tarball from the releases page:

```bash
# Check https://github.com/element-hq/element-call/releases for latest version
wget https://github.com/element-hq/element-call/releases/download/v0.19.3/element-call-0.19.3.tar.gz
tar xzf element-call-0.19.3.tar.gz
# Serve the extracted files with Nginx/Caddy/Apache
```

### Build from source (alternative)

```bash
git clone https://github.com/element-hq/element-call.git
cd element-call
yarn
yarn build
# Output is in dist/ — serve these static files
```

### Configuration file

Place `config.json` in the `public/` directory before building (or serve it at `/config.json`):

```json
{
  "default_server_config": {
    "m.homeserver": {
      "base_url": "https://your-matrix-homeserver.example.com",
      "server_name": "your-matrix-homeserver.example.com"
    }
  },
  "features": {
    "feature_group_calls_without_video_and_audio": false
  }
}
```

Use `config/config.sample.json` as the starting point.

### Nginx serving static files

```nginx
server {
    listen 443 ssl;
    server_name call.example.com;

    root /var/www/element-call/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

The `try_files` directive is required because Element Call uses client-side routing — all non-file paths must fall back to `index.html`.

### Matrix homeserver requirements

Element Call requires a Matrix homeserver (e.g. Synapse or Conduit/conduwuit) with:
- MSC3266 (Room Summary API), MSC4140 (Delayed Events), and MSC4222 (state_after sync) enabled — required MSCs
- Registration enabled (without 3PID/token requirements) if you want guest/unregistered access
- Synapse: enable experimental features in homeserver.yaml: msc3266_enabled: true, msc4222_enabled: true, and max_event_delay_duration: 24h
- It is recommended to use a **dedicated homeserver** with federation disabled — not an existing homeserver where users have joined normal Matrix rooms (Element Call may behave unreliably with standard room history)

### LiveKit SFU (required MatrixRTC backend)

LiveKit is now required as the MatrixRTC backend for Element Call. Deploy a LiveKit SFU and the lk-jwt-service MatrixRTC authorization service:
- Deploy LiveKit: <https://docs.livekit.io/realtime/self-hosting/deployment/>
- Deploy lk-jwt-service (MatrixRTC Authorization Service): <https://github.com/element-hq/lk-jwt-service>
- Add LiveKit URL and API keys to `config.json`

## Upgrade procedure

```bash
# Option 1: Download pre-built tarball (recommended)
wget https://github.com/element-hq/element-call/releases/download/<ver>/element-call-<ver>.tar.gz
tar xzf element-call-<ver>.tar.gz
# Re-deploy extracted files to your web server

# Option 2: Build from source
cd element-call
git pull
yarn install
yarn build
# Re-deploy dist/ to your web server
```

## Gotchas

- Pre-built tarballs are now available: download `element-call-<ver>.tar.gz` from https://github.com/element-hq/element-call/releases — no need to build from source. Serve the extracted files with any static web server.
- Dedicated homeserver strongly recommended: using an existing production Matrix server risks instability and unexpected behavior in Element Call.
- Federation: disable Matrix federation on the dedicated homeserver to prevent spam registrations and ensure isolation.
- CORS: the homeserver must be configured to allow CORS requests from your Element Call domain.
- Client-side routing: your web server must route all unknown paths back to `/index.html` — forgetting this breaks direct links and page refreshes.
- LiveKit is now required: Element Call uses LiveKit as its MatrixRTC backend (MSC4195). Deploy a LiveKit SFU + the lk-jwt-service authorization service alongside your Matrix homeserver. The old full-mesh mode is available on the `full-mesh` branch but is no longer the default.
- Synapse experimental features: MSC3266, MSC4140, and MSC4222 must be explicitly enabled in homeserver.yaml for Element Call to work correctly.

## Links

- GitHub: <https://github.com/element-hq/element-call>
- Self-hosting guide: <https://github.com/element-hq/element-call/blob/main/docs/self_hosting.md>
- Hosted instance: <https://call.element.io>
- Matrix spec (MatrixRTC): <https://github.com/matrix-org/matrix-spec-proposals/blob/matthew/group-voip/proposals/3401-group-voip.md>
- LiveKit self-hosting: <https://docs.livekit.io/realtime/self-hosting/deployment/>
- lk-jwt-service: <https://github.com/element-hq/lk-jwt-service>
- Matrix chat: <https://matrix.to/#/#webrtc:matrix.org>
