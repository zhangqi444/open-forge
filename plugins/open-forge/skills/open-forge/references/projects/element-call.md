---
name: element-call
description: Recipe for Element Call — open-source, self-hosted group video/audio calling built on Matrix/MatrixRTC.
---

# Element Call

Full-mesh group video and audio calls powered by Matrix, implementing the MatrixRTC spec. A static web app (React + LiveKit SFU optional) that connects to a Matrix homeserver for signaling. No proprietary server components — calls are federated over Matrix. Upstream: <https://github.com/element-hq/element-call>. Docs: <https://element-call.netlify.app>. Hosted demo: <https://call.element.io>. License: AGPL-3.0.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Build from source + static web server | <https://github.com/element-hq/element-call#host-it-yourself> | Yes | Recommended; output is plain static files served by Nginx/Caddy/Apache |
| Hosted service | <https://call.element.io> | Yes (managed) | No self-hosting needed; Element.io-run instance |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | Public domain/URL for Element Call? | HTTPS URL | All; required for CORS + homeserver config |
| software | Matrix homeserver URL? | HTTPS URL (default: same domain on port 8008) | Required |
| software | Allow guest/unregistered users to join calls? | Boolean | Requires open registration on the homeserver |
| software | Use LiveKit SFU for scalability? | Boolean | Optional; improves quality for larger calls |

## Software-layer concerns

### Build from source

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
- Registration enabled (without 3PID/token requirements) if you want guest/unregistered access
- MSC3401 / MatrixRTC support (Synapse 1.x supports this)
- It is recommended to use a **dedicated homeserver** with federation disabled — not an existing homeserver where users have joined normal Matrix rooms (Element Call may behave unreliably with standard room history)

### LiveKit SFU (optional, for scalability)

For calls with many participants, configure a LiveKit server to act as an SFU:
- Deploy LiveKit: <https://docs.livekit.io/realtime/self-hosting/deployment/>
- Add LiveKit URL and API keys to `config.json`

## Upgrade procedure

```bash
cd element-call
git pull
yarn install
yarn build
# Re-deploy dist/ to your web server
```

## Gotchas

- No prebuilt binaries: you must build from source. There is no official Docker image or tarball for self-hosters (as of early 2026 — check GitHub releases for updates).
- Dedicated homeserver strongly recommended: using an existing production Matrix server risks instability and unexpected behavior in Element Call.
- Federation: disable Matrix federation on the dedicated homeserver to prevent spam registrations and ensure isolation.
- CORS: the homeserver must be configured to allow CORS requests from your Element Call domain.
- Client-side routing: your web server must route all unknown paths back to `/index.html` — forgetting this breaks direct links and page refreshes.
- LiveKit is optional: without it, calls use full-mesh WebRTC (each participant connects to every other). This works well for small groups (2-5) but degrades for larger calls.

## Links

- GitHub: <https://github.com/element-hq/element-call>
- Self-hosting guide: <https://github.com/element-hq/element-call#host-it-yourself>
- Hosted instance: <https://call.element.io>
- Matrix spec (MatrixRTC): <https://github.com/matrix-org/matrix-spec-proposals/blob/matthew/group-voip/proposals/3401-group-voip.md>
- LiveKit self-hosting: <https://docs.livekit.io/realtime/self-hosting/deployment/>
- Matrix chat: <https://matrix.to/#/#webrtc:matrix.org>
