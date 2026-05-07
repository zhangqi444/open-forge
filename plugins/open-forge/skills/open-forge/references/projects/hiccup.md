# Hiccup

**Static personal start page / new tab dashboard** — a beautiful, fast static homepage for organizing links and services. Built-in search, drag-and-drop link editing, multiple profiles, PWA support, and localStorage caching. No server-side database required.

**Official site / demo:** https://designedbyashw.in/test/hiccup/  
**Source:** https://github.com/ashwin-pc/hiccup  
**License:** MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | Docker (nginx) | Easiest self-hosted path |
| Any | Static file host (S3, GitHub Pages, Netlify) | Just serve the build output |
| Any | Local browser | Open `index.html` directly |

---

## Inputs to Collect

| Input | Description | Default |
|-------|-------------|---------|
| `HTTP_PORT` | External port | `8899` |
| `config.json` | Your links and settings | Default config from repo |

---

## Software-layer Concerns

### Docker Compose
```yaml
services:
  hiccup:
    image: bleckbeard/hiccup:latest
    ports:
      - '8899:80'
    volumes:
      - ./config.json:/usr/share/nginx/html/configs/config.json
    restart: unless-stopped
```

Access at `http://localhost:8899`.

### Config file (`config.json`)
Mount your own `config.json` to customize links, categories, search providers, and profiles. The default config in the repo (`public/configs/config.json`) is the starting template.

Edit links directly in the UI (drag-and-drop) or via the JSON config manager in the app.

### Features
- Featured links with icons
- Categorized link groups
- Multiple profiles (switchable)
- Remote profile loading (from URL)
- Search with multiple providers + custom search
- Keyboard shortcuts and full keyboard navigation
- PWA (installable as app)
- Read-only mode
- localStorage caching for offline use
- Dark mode support

### Build from source
```bash
git clone https://github.com/ashwin-pc/hiccup
cd hiccup
npm install
npm run build
# Serve the build/ directory from any static web server
```

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```
Config file is mounted separately and unaffected by image updates.

---

## Gotchas

- **Config changes via UI are saved to localStorage**, not the mounted `config.json`. Export and save your config file if you want changes to persist across container restarts.
- **Static only** — no server-side processing, user accounts, or database.
- **Community Docker image** (`bleckbeard/hiccup`) — not the official maintainer's image. Check for freshness before deploying.
- **PWA install** works when served over HTTPS; HTTP deployments won't prompt for install.

---

## References

- Upstream README: https://github.com/ashwin-pc/hiccup#readme
- Live demo: https://designedbyashw.in/test/hiccup/
