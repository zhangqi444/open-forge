---
name: cubiks-2048
description: Cubiks-2048 recipe for open-forge. A 3D browser-based clone of the 2048 puzzle game. JavaScript, static files only. Source: https://github.com/Kshitij-Banerjee/Cubiks-2048
---

# Cubiks-2048

A 3D clone of the classic 2048 puzzle game, playable in the browser. Entirely static JavaScript/HTML/CSS — no server-side logic required. CC-BY-NC-4.0 licensed. Upstream: <https://github.com/Kshitij-Banerjee/Cubiks-2048>. Live demo: <https://kshitij-banerjee.github.io/Cubiks-2048/>

> ℹ️ **Note**: This project has had no commits since 2014. It is functionally complete but unmaintained.

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any webserver | Static file serving | nginx, Apache, Caddy, or any static host |
| Any CDN / static host | Static files | GitHub Pages, Netlify, Vercel, S3, etc. |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain or path to serve from?" | URL / path | e.g. games.example.com or /games/cubiks-2048 |

## Software-Layer Concerns

- **Static only**: No database, no backend, no Node.js process. Just HTML/CSS/JavaScript files.
- **Self-contained**: All assets included in the repo. No CDN dependencies.
- **No config**: No environment variables or config files needed.
- **License**: CC-BY-NC-4.0 — free for personal/non-commercial use. Commercial use requires permission.

## Deployment

### NGINX (static files)

```bash
git clone https://github.com/Kshitij-Banerjee/Cubiks-2048.git /var/www/cubiks-2048
```

```nginx
server {
    listen 80;
    server_name games.example.com;
    root /var/www/cubiks-2048;
    index index.html;
    try_files $uri $uri/ =404;
}
```

### Docker (minimal nginx)

```yaml
services:
  cubiks-2048:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./Cubiks-2048:/usr/share/nginx/html:ro
    restart: unless-stopped
```

Clone the repo first: `git clone https://github.com/Kshitij-Banerjee/Cubiks-2048.git`

### Direct browser access

Simply open `index.html` in a browser — works without any webserver for local play.

## Upgrade Procedure

No upstream development since 2014 — no upgrades expected. If you've forked it, apply patches to your fork directly.

## Gotchas

- **Unmaintained since 2014**: No security patches, no dependency updates. Fine for a game, but be aware it won't receive fixes.
- **CC-BY-NC-4.0 license**: Non-commercial use only. Do not embed in a commercial product without permission.
- **Older JavaScript**: Uses older JS patterns (no modules, no build step). Works fine in modern browsers but the codebase is dated.
- **No mobile touch support**: Designed for desktop keyboard/mouse play. Touch events may not work on mobile browsers.

## Links

- Source: https://github.com/Kshitij-Banerjee/Cubiks-2048
- Live demo: https://kshitij-banerjee.github.io/Cubiks-2048/
