# Bicimon

**Bike speedometer as a Progressive Web App** — static client-side JavaScript PWA that uses the browser Geolocation API to display real-time cycling speed. No tracking, no data storage, no server-side component. Self-host by serving the static files.

**Official site:** https://github.com/knrdl/bicimon
**Source:** https://github.com/knrdl/bicimon
**License:** MIT
**Demo:** https://knrdl.github.io/bicimon/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | Any static file server (Nginx, Caddy, Apache) | No backend needed |
| GitHub Pages / Netlify / S3 | Static hosting | Can be hosted anywhere |

---

## Inputs to Collect

### Phase 1 — Planning
- Where to serve the static files (any web server or static host)
- HTTPS required (browsers only allow Geolocation API over HTTPS)

---

## Software-Layer Concerns

- **Purely static:** HTML + JavaScript only; no server-side processing, no database, no backend
- **Geolocation API:** Uses browser's built-in GPS/location API — HTTPS is mandatory for Geolocation to work in modern browsers
- **PWA:** Can be installed to the home screen on mobile devices for full-screen use while cycling
- **No data stored:** Speed readings exist only in the browser; nothing is saved or transmitted

---

## Deployment

```bash
git clone https://github.com/knrdl/bicimon
# Serve the contents with any static web server
# Example with Nginx:
# Point document root at the cloned directory
# Ensure HTTPS is configured (required for Geolocation API)
```

Or simply host on GitHub Pages, Netlify, Vercel, or any static CDN.

---

## Upgrade Procedure

```bash
git pull
# No rebuild needed — static files only
```

---

## Gotchas

- **HTTPS is required** — Geolocation API is blocked on HTTP in all modern browsers; must serve over HTTPS
- **GPS accuracy depends on device** — speed accuracy varies by phone/device GPS hardware
- **No install dependencies** — no npm, no build step; just static files

---

## Links

- Upstream README: https://github.com/knrdl/bicimon#readme
- Live demo: https://knrdl.github.io/bicimon/
