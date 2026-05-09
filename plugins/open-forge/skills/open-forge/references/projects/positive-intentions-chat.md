# Positive Intentions Chat

Decentralized, browser-based peer-to-peer chat application. All communication happens directly between browsers using WebRTC — no central server required for message storage or relay. Features end-to-end encryption, file sharing, voice/video calls, and an optional mixed-reality/VR space. Can be self-hosted as a static site or Docker container. Data is stored in browser local storage (no server-side persistence).

> **Note:** Upstream marks this project as experimental / proof-of-concept and not production-ready.

**Official site:** https://positive-intentions.com  
**Source:** https://github.com/positive-intentions/chat  
**Live demo:** https://chat.positive-intentions.com  
**Upstream docs:** https://positive-intentions.com

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any web server | Static site (built files) | Serve the `docs/` directory from the `staging` branch |
| Any Linux host | Docker | Build and run the Docker image |
| GitHub Pages | GitHub Actions | Fork + enable Pages from `staging` branch `docs/` folder |
| Any device | Browser (no install) | Use the hosted demo at https://chat.positive-intentions.com |

---

## Inputs to Collect

### Docker deployment
| Variable | Description | Example |
|----------|-------------|---------|
| `HOST_PORT` | Port to expose the app on | `8080` |

### GitHub Pages deployment
| Field | Description |
|-------|-------------|
| Fork visibility | Must be **public** for free GitHub Pages |
| Pages source branch | `staging` |
| Pages source folder | `/docs` |

---

## Software-Layer Concerns

### Docker

```bash
# Build
docker build -t chat -f docker/Chat.Dockerfile . --no-cache

# Run
docker run --name chat-container -p 8080:80 chat
```

Or use the npm scripts:

```bash
npm run docker:build
npm run docker:run
```

### npm (development / local)

```bash
npm install
npm start
```

### GitHub Pages (free hosting)

1. Fork the repository (must be public).
2. Go to Settings → Pages.
3. Set Source: "Deploy from a branch", Branch: `staging`, Folder: `/docs`.
4. Click Save.

The app will be available at `https://<your-username>.github.io/chat/`.

### Data model

- All chat data is stored in **browser local storage** — no server-side database.
- Two tabs of the app on the same device will share and conflict on the same store. Use different browsers or devices to test peer-to-peer.
- Clearing browser site data resets all local state.

---

## Upgrade Procedure

```bash
# Docker: rebuild from latest source
git pull
docker build -t chat -f docker/Chat.Dockerfile . --no-cache
docker stop chat-container && docker rm chat-container
docker run --name chat-container -p 8080:80 chat
```

For GitHub Pages: sync your fork with upstream, then Pages redeploys automatically.

---

## Gotchas

- **Not production-ready** — the upstream project is explicitly experimental with known bugs and incomplete features.
- WebRTC peer connectivity may fail behind strict NAT or firewalls (no built-in TURN server).
- Do not open multiple tabs of the app in the same browser — they share the same local storage and cause conflicts.
- No server-side message history — messages are lost if browser storage is cleared.
- Mobile builds (iOS/Android via Capacitor) and desktop builds (via Tauri) require the respective native build tools and are not distributed in binary form.
- The app is published to https://store.app as a web app; native app store listings do not exist.

---

**Upstream README:** https://github.com/positive-intentions/chat#readme  
**Docs:** https://positive-intentions.com
