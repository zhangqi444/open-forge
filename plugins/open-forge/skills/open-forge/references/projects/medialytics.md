# Medialytics

**What it is:** A free, client-side analytics tool for Plex media server content. Unlike activity trackers (Tautulli), Medialytics focuses on the nature of your media library itself — top studios, genres, codecs, resolutions, file sizes, bitrates, actors, directors. Helps diagnose content issues (large files, codec mismatches) and visualize library composition via charts and treemaps.

**Official URL:** https://github.com/Drewpeifer/medialytics
**License:** MIT
**Stack:** Vue 2 + Axios + D3 + Plotly.js; static HTML/JS — no server required

> ⚠️ **Security warning:** Medialytics uses your Plex server token directly in browser API requests. Never host it on a publicly accessible URL — use locally or behind strong authentication only.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Local machine | Open HTML in browser | Simplest — drag `index.html` into browser |
| Local network only | Any static file server | nginx, Caddy, Python `http.server` — LAN access only |
| VPS (advanced) | Static server with auth | Only if protected behind strong auth (basic auth, VPN, etc.) |

---

## Inputs to Collect

### At runtime (entered in the browser UI)
- **Plex server URL** — e.g. `http://192.168.1.100:32400`
- **Plex token** — your server's `X-Plex-Token`

**Finding your Plex token:**
1. Open Plex Web in a browser
2. Open DevTools → Network tab → reload
3. Find any request to your Plex server URL
4. Look for `X-Plex-Token` in the query string or request headers

---

## Software-Layer Concerns

**Quickest start (no install needed):**
```bash
git clone https://github.com/Drewpeifer/medialytics.git
cd medialytics
# Open index.html in your browser directly
```

**Simple local server (optional):**
```bash
cd medialytics
python3 -m http.server 8080
# Visit http://localhost:8080
```

Or with nginx/Caddy for LAN access — serve the static directory.

**Usage:**
1. Enter your Plex server URL and token in the UI
2. Select a library (Movies or TV — other types not supported)
3. Charts and stats generate client-side from the Plex XML API

**Supported library types:** Movies and TV shows. Audio, image, and other library types are excluded by default (customizable in source).

**Upgrade procedure:**
```bash
git pull
```
Refresh browser — it's static assets only.

---

## Gotchas

- **Token security** — the Plex token is an admin-level credential; it appears in browser requests; never expose Medialytics to the public internet
- **Client-side only** — all processing is in the browser; large libraries (10,000+ items) may take time to load and process
- **Movies and TV only** — audio and image libraries are excluded; modify the source to add them
- **No CORS workaround built-in** — if your Plex server blocks cross-origin requests, you may need to configure Plex to allow the Medialytics origin or run them on the same host
- **Last updated 2025** — check GitHub for current status before deploying

---

## Links
- GitHub: https://github.com/Drewpeifer/medialytics
