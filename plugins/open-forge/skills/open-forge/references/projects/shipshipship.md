---
name: shipshipship
description: Recipe for ShipShipShip — self-hostable changelog and roadmap platform with emoji reactions, voting, kanban board, custom themes, and newsletter automation. Go + SQLite + SvelteKit, single Docker image.
---

# ShipShipShip

Self-hostable changelog and roadmap platform. Upstream: https://github.com/GauthierNelkinsky/ShipShipShip

Go (Gin) backend with SQLite + GORM, SvelteKit admin panel. Single Docker image (amd64 + arm64). No external database required. Features emoji reactions, feature voting, kanban board, custom themes, and SMTP newsletter automation.

## Compatible combos

| Runtime | Notes |
|---|---|
| Docker Compose | Recommended — single service, SQLite embedded |
| Docker run | Supported; compose preferred for volume management |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Admin username | Default: admin |
| preflight | Admin password | Change from default |
| preflight | JWT secret key | Long random string — used to sign sessions |
| preflight | Base URL | Full URL of your instance, e.g. https://changelog.yourdomain.com — used in email unsubscribe links |
| smtp (opt) | SMTP settings | Configured post-deploy in admin UI at /admin/newsletter/settings |

## Software-layer concerns

**Config:** Environment variables for core settings. SMTP and newsletter settings are configured post-deploy through the admin UI.

**Data:** SQLite database at /app/data/changelog.db inside the container. Mount a named volume or host path to persist across upgrades.

**Port:** Container on 8080.

**Admin panel:** /admin — complete setup here after first launch (themes, newsletter, status labels).

**Theme system:** Install custom themes via /admin/customization/theme. Without a theme, the root URL shows the admin interface.

**Newsletter:** Configure SMTP under /admin/newsletter/settings. Automation triggers on event status changes.

## Docker Compose

```yaml
services:
  shipshipship:
    image: nelkinsky/shipshipship:latest
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - ADMIN_USERNAME=admin
      - ADMIN_PASSWORD=changeme
      - JWT_SECRET=replace-with-long-random-string
      - BASE_URL=https://changelog.yourdomain.com
      - GIN_MODE=release
    volumes:
      - shipshipship_data:/app/data

volumes:
  shipshipship_data:
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

SQLite database is preserved in the named volume. Check the releases page for schema migration notes before upgrading major versions.

## Gotchas

- **JWT_SECRET must be set** — the default is insecure. Use a long random string (32+ chars).
- **BASE_URL matters for email** — incorrect BASE_URL breaks unsubscribe links in newsletter emails.
- **Themes required for public changelog** — without installing a theme, visiting the root URL shows the admin panel rather than a public-facing changelog.
- **GIN_MODE=release** recommended for production — debug mode logs are verbose.

## Links

- Upstream README + configuration reference: https://github.com/GauthierNelkinsky/ShipShipShip
- Docker Hub: https://hub.docker.com/r/nelkinsky/shipshipship
- Live demo: https://demo.shipshipship.io/admin (login: demo / demo)
