---
name: converse.js
description: Converse.js recipe for open-forge. Browser-based XMPP chat client — embed in any website, full XMPP support, MUC rooms, direct messages, no app install needed. Node.js/static deploy. Upstream: https://github.com/conversejs/converse.js
---

# Converse.js

Modern, feature-rich, 100% client-side XMPP chat app that runs in a web browser. Use it as a standalone fullscreen chat app or embed it as a chat widget in any existing website. Connects to any standard XMPP server.

3,247 stars · MPL-2.0

Upstream: https://github.com/conversejs/converse.js
Website: https://conversejs.org
Docs: https://conversejs.org/docs/
Demo: https://conversejs.org/fullscreen.html
Docker Hub: https://hub.docker.com/r/conversejs/converse.js (community)

## What it is

Converse.js provides a full XMPP chat interface in the browser:

- **XMPP client** — Connects to any standard XMPP/Jabber server (Prosody, ejabberd, OpenFire, etc.)
- **Multi-user chat (MUC)** — Join and create group chat rooms
- **Direct messages** — One-to-one messaging with contacts
- **Roster management** — Add/remove contacts, presence indicators
- **File sharing** — File transfers via HTTP Upload (XEP-0363)
- **Voice/video calls** — WebRTC A/V via XMPP Jingle (XEP-0166/0167/0176)
- **Message history** — MAM (Message Archive Management) support
- **OMEMO encryption** — End-to-end encryption for private chats and MUCs
- **Stickers/emoji** — Full emoji picker
- **Inline images** — Auto-display linked images in chat
- **Three UI modes** — Fullscreen app, overlayed chat box, or embedded single-room
- **Internationalization** — 40+ languages supported
- **Mobile responsive** — Works on phone browsers
- **Desktop app** — Converse Desktop (Electron) and Converse Tauri available

Note: Converse.js is a client only — you still need an XMPP server (Prosody, ejabberd, etc.) to connect to.

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Static web server | Any (nginx, Apache, CDN) | Serve the built JS/HTML files |
| Node.js | npm serve | Development or simple deploy |
| Docker | nginx container | Serve static files |
| Embedded | Any website | Include JS snippet in your page |

## Inputs to collect

### Phase 1 — Pre-install
- XMPP server hostname (and BOSH/WebSocket endpoint URL)
- Authentication mode: login prompt, auto-login, anonymous, or prebind
- UI mode: fullscreen, overlay, or embedded
- Allowed domain(s) for MUC rooms

## Software-layer concerns

### No server-side component
Converse.js is entirely client-side. All you need is:
1. An XMPP server with BOSH or WebSocket support
2. A web server to serve the static files

### XMPP server requirements
Your XMPP server must expose either:
- BOSH endpoint (typically at /http-bind)
- WebSocket endpoint (typically at /xmpp-websocket)
- CORS headers allowing your domain to connect

### Build and serve
  git clone https://github.com/conversejs/converse.js.git
  cd converse.js
  npm install
  npm run build
  # Serve the dist/ directory with any web server
  npx serve dist/ -p 8008

### CDN embed (no build required)
  <link rel="stylesheet" type="text/css" media="screen" href="https://cdn.conversejs.org/12.0.0/dist/converse.min.css">
  <script src="https://cdn.conversejs.org/12.0.0/dist/converse.min.js" charset="utf-8"></script>
  <script>
    converse.initialize({
      bosh_service_url: 'https://xmpp.example.com/http-bind',
      view_mode: 'fullscreen'
    });
  </script>

### Key config options (passed to converse.initialize)
  bosh_service_url: 'https://xmpp.example.com/http-bind'  # or:
  websocket_url: 'wss://xmpp.example.com/xmpp-websocket'
  view_mode: 'fullscreen'           # fullscreen | overlayed | embedded
  auto_login: false                 # set true with credentials for kiosk/shared login
  authentication: 'login'           # login | anonymous | external | prebind
  allow_registration: false         # disable in-band registration
  muc_domain: 'conference.example.com'
  notify_all_room_messages: false

### Docker serve example
  version: '3'
  services:
    converse:
      image: nginx:alpine
      ports:
        - "8080:80"
      volumes:
        - ./dist:/usr/share/nginx/html:ro

## Upgrade procedure

1. Update version tag or pull latest: git pull
2. npm install (in case dependencies changed)
3. npm run build
4. Replace dist/ contents on web server
5. Test by connecting to XMPP server and verifying features

## Gotchas

- Requires XMPP server — Converse.js is a client only; you need a running XMPP server (Prosody, ejabberd, MongooseIM, etc.)
- CORS required — your XMPP server's BOSH/WebSocket endpoint must allow cross-origin requests from your Converse.js domain
- HTTPS required for OMEMO — end-to-end encryption requires a secure context
- BOSH vs WebSocket — WebSocket is preferred for lower latency; BOSH works everywhere but is slower
- Browser storage — OMEMO keys and message cache stored in browser IndexedDB/localStorage; users lose history if they clear browser data
- MAM needed for history — Message Archive Management must be enabled on the XMPP server for message history to work across sessions
- No push notifications — as a browser app, notifications only work when the browser tab is open
- MPL-2.0 license — modifications to Converse.js files must be shared under MPL-2.0; embedding in proprietary apps is allowed

## Links

- Upstream README: https://github.com/conversejs/converse.js/blob/master/README.md
- Documentation: https://conversejs.org/docs/
- Configuration reference: https://conversejs.org/docs/configuration
- Quickstart guide: https://conversejs.org/docs/quickstart/
- XMPP servers: https://xmpp.org/software/servers/
