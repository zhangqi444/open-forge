---
name: recipya
description: Recipya recipe for open-forge. Clean and simple family recipe manager. Import from web or paper scan, organize into cookbooks, nutritional info, unit conversion, migrate from Mealie/Tandoor/Nextcloud Cookbook. Go + Docker. Source: https://github.com/reaper47/recipya
---

# Recipya

Clean, simple recipe manager for families. Import recipes from any website URL, digitize paper recipes, organize into cookbooks, calculate nutrition automatically, convert units (metric/imperial), print recipes, 32 themes, and dark/light mode. Can migrate from Mealie, Tandoor, and Nextcloud Cookbook. Cross-platform binaries available. GPL-3.0. Built in Go.

> **Note:** The project is being rewritten in Rust (announced 2024). The Go version is still fully functional for self-hosting.

Upstream: <https://github.com/reaper47/recipya> | Docs: <https://recipya.musicavis.ca/docs/>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker (single container) | Recommended |
| Any | Docker Compose | Simple single-service compose |
| Linux/macOS/Windows | Binary release | Pre-built Go binaries available |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Port mapping | Default: 8085 |
| config | Data directory | Persistent storage for DB + uploaded images |
| config (optional) | SMTP settings | For email notifications / account confirmation |
| config (optional) | Azure AI credentials | For digitizing paper recipes via OCR |

## Software-layer concerns

### Architecture

- Single Go binary — serves web UI + API
- SQLite database — stored in data directory (no external DB needed)
- Optional: SMTP for email, Azure AI for OCR paper recipe digitization

### Data dirs

| Container path | Description |
|---|---|
| `/app/data` | SQLite database and uploaded recipe images |

### Key env vars / config

Recipya uses a `config.json` in its data directory. Key settings:

```json
{
  "server": {
    "port": 8085,
    "autologin": false,
    "isDemo": false,
    "isProduction": true,
    "url": "https://recipes.example.com"
  },
  "email": {
    "from": "noreply@example.com",
    "sendGridAPIKey": "",
    "host": "smtp.example.com",
    "port": 587,
    "username": "user",
    "password": "pass"
  },
  "integrations": {
    "azureComputerVisionAPIKey": "",
    "azureComputerVisionRegion": ""
  }
}
```

## Install — Docker

```bash
docker run -d \
  --name recipya \
  --restart unless-stopped \
  -p 8085:8085 \
  -v /path/to/recipya/data:/app/data \
  reaper47/recipya:latest
```

Access at http://localhost:8085. Create your account on first visit.

## Install — Docker Compose

```yaml
services:
  recipya:
    image: reaper47/recipya:latest
    container_name: recipya
    restart: unless-stopped
    ports:
      - "8085:8085"
    volumes:
      - recipya_data:/app/data

volumes:
  recipya_data:
```

```bash
docker compose up -d
```

## Install — Binary

```bash
# Download from https://github.com/reaper47/recipya/releases/latest
curl -LO https://github.com/reaper47/recipya/releases/latest/download/recipya-linux-amd64
chmod +x recipya-linux-amd64
./recipya-linux-amd64
```

## Upgrade procedure

Docker:
```bash
docker compose pull
docker compose up -d
```

Binary: download new release, replace the binary, restart.

Recipya notifies you in the UI when an update is available.

## Gotchas

- `/app/data` must be persisted as a volume — the SQLite database and all uploaded recipe images live here. Losing it means losing all recipes.
- `server.url` in config.json should be set to your public URL (with https://) so share links and email links resolve correctly.
- Recipe import from web relies on schema.org structured data — sites without it may not import cleanly.
- The Rust rewrite is underway but not yet ready for self-hosting — stick with the Go Docker image for production use until further notice.
- Paper recipe digitization (OCR) requires Azure Computer Vision credentials — optional, not needed for basic use.

## Links

- Source: https://github.com/reaper47/recipya
- Documentation: https://recipya.musicavis.ca/docs/
- Docker install guide: https://recipya.musicavis.ca/docs/installation/docker/
- Demo: https://recipya-app.musicavis.ca
