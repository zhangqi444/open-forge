# Starbase 80

**What it is:** Clean, minimal Docker homepage / service dashboard. Displays your self-hosted services as a grid of icon tiles organized by category. Configured via a single `config.json` file. No database, no accounts — just a static page served by a tiny container.

**Official site / Demo:** https://notclickable-jordan.github.io/starbase-80/  
**GitHub:** https://github.com/notclickable-jordan/starbase-80  
**Docker Hub:** `jordanroher/starbase-80`

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Single container; config via JSON file |
| Any Linux | Docker | Same |

---

## Inputs to Collect

### Phase: Deploy

| Item | Description |
|------|-------------|
| `config.json` | Service definitions — names, URLs, icons, categories |
| Icons directory | Custom icons referenced from `config.json` (paths relative to `/app/public`) |
| Host port | Default `4173` |

---

## Software-Layer Concerns

- **No database** — fully stateless; all configuration in `config.json`
- **Icons** — mount a local `./icons` directory to `/app/public/icons`; icon paths in `config.json` are relative to `/app/public`
- **Dark/light mode** — auto-detects system preference (`class="auto"` on html element)
- **Responsive layout** — grid adapts from 1 column (mobile) to 4 columns (xl screens)

---

## Example Docker Compose

```yaml
services:
  homepage:
    image: jordanroher/starbase-80
    container_name: starbase-80
    ports:
      - "4173:4173"
    volumes:
      - ./config.json:/app/src/config/config.json
      - ./icons:/app/public/icons
    restart: unless-stopped
```

---

## Config Structure (`config.json`)

Services are grouped into categories with icon tiles:

```json
{
  "categories": [
    {
      "name": "Services",
      "items": [
        {
          "title": "Nextcloud",
          "url": "https://nextcloud.example.com",
          "icon": "/icons/nextcloud.png",
          "target": "_blank"
        }
      ]
    }
  ]
}
```

---

## Upgrade Procedure

1. Pull new image: `docker compose pull`
2. Restart: `docker compose up -d`
3. `config.json` and icons persist via volume mounts

---

## Gotchas

- Icon paths in `config.json` are relative to `/app/public` inside the container — use `/icons/filename.png` for icons mounted at `/app/public/icons/`
- No built-in authentication — put behind a reverse proxy with auth if you don't want the dashboard publicly accessible
- No health checks or monitoring — purely a visual link page; it does not probe service availability

---

## Links

- Demo: https://notclickable-jordan.github.io/starbase-80/
- GitHub: https://github.com/notclickable-jordan/starbase-80
