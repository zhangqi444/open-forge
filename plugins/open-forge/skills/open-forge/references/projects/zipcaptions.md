# ZipCaptions

**What it is:** A free, privacy-first browser-based speech-to-text captioning tool. Generates live captions from any audio source (microphone, system audio) entirely in your browser — no data ever leaves your device. Built with Angular and the Web Speech API; no AI service, no subscription, no tracking. Useful for accessibility, live presentations, and transcription.

**Official URL:** https://github.com/jptrsn/zip-captions
**Live instance:** https://zipcaptions.app
**License:** AGPL-3.0
**Stack:** Angular SPA; optional MongoDB sidecar (for server features); Docker

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Public hosted | Browser | Use https://zipcaptions.app — no setup needed |
| Any Linux VPS | Docker | Self-host the SPA; `educoder/zip-captions:develop` |
| Any Linux VPS | Docker Compose | Full stack with optional MongoDB |
| Local machine | Node.js (dev) | `nx serve client` → localhost:4200 |

---

## Inputs to Collect

### Pre-deployment (self-hosted)
- External port — default `4200` mapped to container `80`
- MongoDB credentials (only if using server-side features like room sharing)

---

## Software-Layer Concerns

**Simplest self-host (client-only, no MongoDB):**
```yaml
services:
  zipcaptions:
    container_name: zip-captions
    image: educoder/zip-captions:develop
    ports:
      - 4200:80
```

**Full stack with MongoDB (for server features):**
```yaml
services:
  mongodb:
    container_name: mongodb
    image: mongodb/mongodb-community-server
    ports:
      - 27017:27017
    environment:
      - MONGO_INITDB_ROOT_USERNAME=db_user
      - MONGO_INITDB_ROOT_PASSWORD=changeme

  zipcaptions:
    image: educoder/zip-captions:develop
    ports:
      - 4200:80
    depends_on:
      - mongodb
```

**Default port:** `4200`

**Build from source:**
```bash
git clone https://github.com/jptrsn/zip-captions.git
cd zip-captions
npm install
docker compose build ./
docker compose up
```

**Dev server:**
```bash
npm install -g nx
nx serve client  # → http://localhost:4200
```

**Browser requirements:** Modern browser with Web Speech API support (Chrome/Edge work best; Firefox support varies by platform). Microphone permission required.

**Multi-language:** Navigate to Settings to select from multiple supported languages.

**How it works:** All speech recognition is done via the browser's built-in Web Speech API — no audio is sent to any server in the basic client-only mode.

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`

---

## Gotchas

- **AGPL-3.0** — modifications must be open-sourced if deployed publicly
- **Chrome/Edge recommended** — Web Speech API support is most reliable in Chromium-based browsers; Firefox may not support it on all platforms
- **HTTPS required for microphone access** — browsers block microphone access on non-HTTPS origins except `localhost`; self-hosted instances need a valid TLS certificate
- **`develop` tag** — the published Docker image tracks the develop branch; for stability, pin to a specific release tag when available
- **No iOS/Android apps** — mobile browser access works via the web app

---

## Links
- GitHub: https://github.com/jptrsn/zip-captions
- Live instance: https://zipcaptions.app
- Discord: https://discord.gg/Swe2JeHnPc
- Patreon: https://patreon.com/zipcaptions
