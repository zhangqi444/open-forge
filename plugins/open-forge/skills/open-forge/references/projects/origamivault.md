---
name: origamivault
description: Recipe for OrigamiVault — offline web app for encrypting/splitting secrets and printing them as QR codes and OCR-friendly recovery snippets. Static files served via busybox httpd; no backend, no data stored.
---

# OrigamiVault

Encrypted paper storage for secrets — master passwords, crypto keys, 2FA seeds, recovery phrases. Upstream: https://github.com/origamivault/origamivault

Pure client-side HTML/CSS/JavaScript app. Nothing is uploaded or stored online — all crypto (AES via Web Crypto API, Shamir's Secret Sharing) runs in the browser. Outputs printable QR codes + OCR-friendly JS decryption snippets. MIT licensed.

Live hosted version (no install needed): https://origamivault.github.io/origamivault/

## Compatible combos

| Method | Notes |
|---|---|
| GitHub Pages (hosted) | Live at origamivault.github.io/origamivault — no install needed |
| Docker (self-hosted) | Single busybox httpd container serving static files — no backend |
| Static file host | Download ZIP and serve from any web server, nginx, Caddy, S3, USB drive |
| Local file | Open index.html directly in browser — fully offline |

## Inputs to collect

None required for Docker/static deployment — the app is fully static. No environment variables, no database, no volumes.

For Docker:
| Phase | Prompt | Notes |
|---|---|---|
| preflight | Port to expose | Default: 8080 |

## Software-layer concerns

**No backend:** The container runs busybox httpd serving static HTML/CSS/JS files. No server-side processing, no database, no logs, no outbound connections.

**No persistent data:** Nothing to persist — the app stores nothing. No volume needed.

**Port:** Container on 8080.

**Fully offline:** Once loaded, the app works without internet. Ideal for air-gapped use — download the repo ZIP and open index.html directly.

**Security model:** All secrets stay in the browser. The app never phones home. Verify this by reviewing the source or running offline.

**Docker image:** Built from `busybox:musl` — extremely minimal footprint.

## Docker Compose

```yaml
services:
  origamivault:
    image: ghcr.io/origamivault/origamivault:latest
    restart: unless-stopped
    ports:
      - "8080:8080"
```

Or build from source:

```yaml
services:
  origamivault:
    build: .
    restart: unless-stopped
    ports:
      - "8080:8080"
```

## Upgrade procedure

```bash
docker compose pull origamivault
docker compose up -d origamivault
```

No state to migrate — stateless static app.

## Gotchas

- **No official Docker Hub image published in README** — the repo has a Dockerfile using `busybox httpd`; build locally or check the GitHub Container Registry for published images.
- **Offline-first design** — for maximum security, use the local file or self-hosted version rather than the public GitHub Pages instance, especially for highly sensitive secrets.
- **Paper is the point** — the output is meant to be printed and physically secured, not stored digitally.
- **Shamir's Secret Sharing** — splitting into N shares requires M shares to reconstruct; losing shares permanently locks out recovery.

## Links

- Upstream repository: https://github.com/origamivault/origamivault
- Live app (no install): https://origamivault.github.io/origamivault/
- Video demo: https://www.youtube.com/watch?v=zzQkq5Qjri8
- GitLab mirror: https://gitlab.com/origamivault/origamivault
