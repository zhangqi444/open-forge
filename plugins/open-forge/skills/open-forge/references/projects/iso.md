# Iso

> Plug-and-play homelab dashboard. Configure all your self-hosted services in a single `config.json` file and get a clean, multi-language link page with search, icons, and themes. Extremely minimal — no database, no accounts (optional password), Docker-first.

**Official URL:** https://github.com/Coyenn/iso

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker | One-liner start; bind-mount config directory |
| Any Linux VPS/VM | Docker Compose | Recommended for persistence |
| Local machine | Bun | Dev mode; `bun dev` |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Default |
|-------|-------------|---------|
| `AUTH_SECRET` | Secret key for session signing | — (set any string) |
| `AUTH_PASSWORD` | Password to access the dashboard | — (leave unset for open access) |
| `APP_DATA_PATH` | Path to config directory inside container | `/config` |

> If `AUTH_PASSWORD` is not set, the dashboard is accessible to anyone who can reach it. Set it and `AUTH_SECRET` together to enable password protection.

---

## Software-Layer Concerns

### Config & Environment
- All service configuration lives in a single `config.json` file in the mounted `/config` directory
- No database — stateless; config file is the only persistent state
- On first run with an empty `/config`, Iso creates a default `config.json` you can then edit

### Data Directories
| Path (container) | Purpose |
|------------------|---------|
| `/config` | `config.json` — all dashboard settings and service links |

### Docker Compose
```yaml
services:
  iso:
    image: coyann/iso:latest
    container_name: iso
    ports:
      - "3000:3000"
    environment:
      - AUTH_SECRET=your-secret-here
      - AUTH_PASSWORD=your-password-here
    volumes:
      - ./config:/config
    restart: unless-stopped
```

### `config.json` Structure
```json
{
  "title": "My Dashboard",
  "locale": "en",
  "theme": "amethyst",
  "pageLoadAnimation": true,
  "search": {
    "enabled": true,
    "engine": "google",
    "placeholder": "Search ..."
  },
  "services": [
    {
      "order": 1,
      "icon": "tv",
      "label": "Plex",
      "href": "https://plex.example.com"
    }
  ],
  "greetings": []
}
```

### Locales
Supported: `en`, `es`, `fr`, `de`

### Themes
Built-in themes selectable via `"theme"` key (e.g., `"amethyst"`).

### Search Engines
Built-in: `google`, `bing`, `duckduckgo`, `startpage`, `qwant`, `searx`; or set `"engine": "custom"` and provide `"engineUrl"` with `[q]` placeholder.

### Ports
| Port | Service |
|------|---------|
| `3000` | Web UI |

---

## Upgrade Procedure

1. Pull latest image: `docker pull coyann/iso:latest`
2. `docker compose down && docker compose up -d`
3. No migration needed — config.json format is stable between minor versions (verify changelog for breaking changes)

---

## Gotchas

- **No auth = open dashboard** — if `AUTH_PASSWORD` is not set, anyone on the network can see your service links; always set a password when exposing to the internet
- **`AUTH_SECRET` must persist** — changing it invalidates existing sessions (users get logged out)
- **Icons are built-in strings** — icon names come from Iso's bundled icon set; check the repo for the list of available names; custom icons require a URL
- **Stateless** — there's no UI to edit the config; you must edit `config.json` directly and reload the page; changes take effect immediately
- **Single user** — the password auth is a single shared password; no per-user accounts

---

## Links
- GitHub: https://github.com/Coyenn/iso
- Docker Hub: https://hub.docker.com/r/coyann/iso
- Live demo: https://iso.tim.cv
- README: https://github.com/Coyenn/iso#readme
