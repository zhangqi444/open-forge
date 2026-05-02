# YT-DLP Web Player

**What it is:** A self-hosted web video player powered by yt-dlp and ffmpeg. Paste any supported URL (YouTube, Vimeo, Twitch, and thousands more) and watch it directly in the browser — no downloads, real-time HLS transcoding, SponsorBlock support, and a browser extension to replace native players sitewide.

**Official URL:** https://github.com/Matszwe02/ytdlp_web_player
**Docker Hub:** `matszwe02/ytdlp_web_player`
**License:** MIT
**Stack:** Python (backend) + yt-dlp + ffmpeg + HLS + Video.js

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended |
| Homelab | Docker Compose | CPU-bound; needs decent hardware for real-time transcoding |

---

## Inputs to Collect

### Pre-deployment
- `.env` file (copy from `src/.env.example`) — configure optional features
- Optional: `src/cookies.txt` — mount for authenticated video access (e.g. age-restricted YouTube)
- Domain/hostname if enabling HTTPS (required for PWA and browser extension)

### Runtime
- Video URL or search query entered in the web UI
- Resolution selection (Direct / transcoded quality options)

---

## Software-Layer Concerns

**Config:** Via `src/.env` file. Most settings are off by default and opt-in.

**Default port:** `5000` (HTTP); optional HTTPS on `5001` via bundled nginx sidecar

**Docker Compose quick start:**
```bash
git clone https://github.com/Matszwe02/ytdlp_web_player.git
cd ytdlp_web_player
# Copy and edit .env
cp src/.env.example src/.env
docker compose up -d
```

Access at `http://localhost:5000`.

**Auto-updates:** Uncomment the Watchtower section in `compose.yml` to get daily yt-dlp updates automatically (recommended — keeps site support current).

**HTTPS setup:** Uncomment the nginx section in `compose.yml`; set `ALLOWED_DOMAINS` to your domain. HTTPS is required for PWA install and browser extension functionality.

**Cookies:** To play authenticated/restricted content, mount `./src/cookies.txt:/app/cookies.txt`. Export cookies from your browser using a cookie-export extension.

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`
3. Or use Watchtower for automatic daily updates

---

## Gotchas

- **CPU-intensive:** Real-time HLS transcoding requires a capable machine — Pi 3/4 may struggle with HD content
- **Transcoding latency:** "Direct" mode loads in ~4s; transcoded modes add 10s+ startup delay; full-download fallback for unsupported streams
- **Only yt-dlp-supported sites work** — check https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md
- **Cookies security warning:** Cookie files are essentially account credentials — only use throwaway accounts; the author explicitly warns these may not be fully secured from exposure through the player
- **HTTPS required for PWA/extension** — HTTP-only deployments can't install the PWA or use the browser extension
- **Livestream support is basic** — limited buffering, no DVR
- Active development — expect bugs; check issues before reporting

---

## Browser Extension

Adds `Open in YT-DLP Player` right-click context menu globally, and optionally replaces native video players on configured domains with the YT-DLP Player via iframe.

Install by loading the `/extension` directory as an unpacked browser extension, or inject `extension.js` via Tampermonkey.

---

## Links
- GitHub: https://github.com/Matszwe02/ytdlp_web_player
- Docker Hub: https://hub.docker.com/r/matszwe02/ytdlp_web_player
- Demo: https://ytdlp-web-player.vercel.app
- Supported sites: https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md
