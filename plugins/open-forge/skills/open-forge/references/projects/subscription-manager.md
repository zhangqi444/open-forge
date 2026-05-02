# Subscription Manager

**What it is:** Single-page web app to track and manage personal subscriptions with calendar view, cost summaries per payment account, and optional NTFY push notifications for upcoming renewals.

**Official URL:** https://github.com/dh1011/subscription-manager

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Recommended path |
| Any Linux host | Docker run | Single container |
| Any | Node.js (manual) | For development only |

---

## Inputs to Collect

| Phase | Input | Notes |
|-------|-------|-------|
| Deploy | Host port | Default `3000` |
| Deploy | Data directory path | Mounted at `/app/data` (SQLite lives here) |
| Optional | NTFY topic | For subscription renewal notifications (configured in app UI Settings) |

---

## Software-Layer Concerns

### Docker image
```
dh1011/subscription-manager:stable
```

### docker-compose.yml
```yaml
version: "3.9"
services:
  app:
    image: dh1011/subscription-manager:stable
    ports:
      - "3000:3000"
    volumes:
      - ./data:/app/data
    restart: unless-stopped
```

### Data directory
- All data stored in a single SQLite file under `./data/`
- Create the directory before first start: `mkdir data`

### Configuration
- No environment variables required for basic operation
- NTFY integration configured via in-app Settings UI (enter NTFY topic)

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

The SQLite database persists in the mounted volume; no migration step needed.

---

## Gotchas

- **Data directory must exist** before `docker compose up -d` or the container will fail to start
- **NTFY is optional** — notifications are configured per-subscription in the UI, not at container startup
- **Currency support** is multi-currency; set your preferred currency in Settings on first run
- **Icons** use Iconify icon names — browse https://icon-sets.iconify.design/ to find icon strings for each subscription

---

## Links

- GitHub: https://github.com/dh1011/subscription-manager
- Docker Hub: https://hub.docker.com/r/dh1011/subscription-manager
