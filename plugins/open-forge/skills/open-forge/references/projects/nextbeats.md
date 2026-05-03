# NextBeats

> Modern, customizable lofi music player with a retro TV-style interface. Streams lofi music from YouTube, mixes ambient sound effects, supports custom channels, and persists all settings in localStorage. No server-side state — pure static web app.

**Official URL:** https://github.com/btahir/next-beats

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker | Recommended; single container, exposes port 3000 |
| Any host | Static hosting (Vercel, Netlify, etc.) | Built with Next.js; `npm run build` + serve `out/` |
| Local machine | Node.js / Bun | Dev mode only; not recommended for production |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Notes |
|-------|-------------|-------|
| `PORT` | External port to bind | Default `3000` |

> NextBeats has no server-side auth, database, or secrets. All user preferences (channels, sound effects, volume) are stored in browser localStorage.

---

## Software-Layer Concerns

### Config & Environment
- No `.env` file required for basic deployment
- All state is client-side (localStorage) — no database, no user accounts
- YouTube embeds require internet access from the end user's browser; firewall-restricted LAN deployments may break playback

### Data Directories
None — stateless. No volumes or mounts required.

### Docker Deployment
```bash
# Build
docker build -t next-beats .

# Run
docker run -d \
  --name nextbeats \
  -p 3000:3000 \
  --restart unless-stopped \
  next-beats
```

Or with Docker Compose:
```yaml
services:
  nextbeats:
    build: .
    container_name: nextbeats
    ports:
      - "3000:3000"
    restart: unless-stopped
```

### Ports
| Port | Service |
|------|---------|
| `3000` | Web UI |

---

## Upgrade Procedure

1. Pull the latest code: `git pull`
2. Rebuild the image: `docker build -t next-beats .`
3. Stop and replace the container: `docker rm -f nextbeats && docker run -d ...`
4. No data migration needed (stateless)

---

## Gotchas

- **YouTube dependency** — video playback requires outbound internet access to YouTube; no offline mode
- **Mobile volume control** — iOS/Android browsers block programmatic volume control; users must use hardware volume buttons
- **localStorage only** — custom channels and sound effects are per-browser; clearing browser data resets everything; no server-side sync
- **No authentication** — anyone who can reach the UI can use it; if exposed publicly, consider putting it behind a reverse proxy with basic auth
- **No official Docker image** — must build from source; watch for upstream `Dockerfile` changes on updates

---

## Links
- GitHub: https://github.com/btahir/next-beats
- Live demo: https://nextbeats.vercel.app/
- README: https://github.com/btahir/next-beats#readme
