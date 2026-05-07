---
name: Titra
description: Modern open-source project time tracking for freelancers and small teams. Fast entry, reporting, export, and integrations. MongoDB backend. MIT licensed.
website: https://titra.io/
source: https://github.com/titraio/titra
license: MIT
stars: 493
tags:
  - time-tracking
  - productivity
  - freelancer
  - project-management
platforms:
  - JavaScript
  - Docker
---

# Titra

Titra is an open-source time tracking application built for freelancers and small teams. The focus is speed — track time against a project in under 10 seconds. Features include reporting, CSV/PDF export, a REST API, Wekan integration for task-based tracking, and a dark mode. Available as a hosted service at app.titra.io or self-hosted via Docker.

Official site: https://titra.io/
Source: https://github.com/titraio/titra
Hosted version: https://app.titra.io
Wiki: https://wiki.titra.io
Docker Hub: https://hub.docker.com/r/titraio/titra

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Docker Compose + MongoDB | Recommended |
| Any Linux VM / VPS | Node.js + MongoDB | Native install |

## Inputs to Collect

**Phase: Planning**
- Root URL (`ROOT_URL`) — full public URL including protocol and port
- MongoDB connection string
- Port to expose (default: 3000)

## Software-Layer Concerns

**Docker Compose (quickstart):**

```bash
# One-liner to start (pulls official docker-compose.yml)
curl -L https://raw.githubusercontent.com/titraio/titra/refs/heads/master/docker-compose.yml \
  | ROOT_URL=http://localhost:3000 docker compose -f - up -d
```

**Docker Compose file:**

```yaml
version: '3'
services:
  titra:
    image: titraio/titra
    container_name: titra_app
    depends_on:
      - mongodb
    environment:
      - ROOT_URL=https://titra.example.com
      - MONGO_URL=mongodb://mongodb/titra?directConnection=true
      - PORT=3000
    ports:
      - "3000:3000"
    restart: always

  mongodb:
    image: mongo:7.0
    container_name: titra_db
    restart: always
    volumes:
      - titra_db_volume:/data/db

volumes:
  titra_db_volume:
```

**Key environment variables:**

| Variable | Description | Required |
|----------|-------------|----------|
| ROOT_URL | Full public URL (e.g. https://titra.example.com) | Yes |
| MONGO_URL | MongoDB connection string | Yes |
| PORT | HTTP port (default: 3000) | No |

**Nginx reverse proxy:**

```nginx
server {
    listen 443 ssl;
    server_name titra.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

**Data paths:**
- MongoDB data: Docker volume `titra_db_volume` (back this up)

**First login:**
- Register a new account via the web UI
- No default credentials — account creation is open on first run

## Upgrade Procedure

1. `docker pull titraio/titra`
2. `docker compose down && docker compose up -d`
3. Check releases: https://github.com/titraio/titra/releases

## Gotchas

- **ROOT_URL required**: Titra (Meteor-based) requires `ROOT_URL` to be set correctly — wrong value breaks authentication cookies and WebSocket connections
- **WebSockets**: Titra uses Meteor's real-time DDP over WebSockets — ensure proxy passes upgrade headers and does not time out long-lived connections
- **MongoDB 7.0**: Official compose uses mongo:7.0; earlier versions may work but are not tested
- **DigitalOcean Marketplace**: Available as a 1-click droplet if you want a quick cloud deployment
- **Wekan integration**: Titra integrates with Wekan (kanban) for task-based time tracking; see https://wiki.titra.io for setup
- **Export formats**: Supports CSV and PDF export for invoicing; configure in settings after login

## Links

- Upstream README: https://github.com/titraio/titra/blob/master/README.md
- Wiki / documentation: https://wiki.titra.io
- Hosted version: https://app.titra.io
- Docker Hub: https://hub.docker.com/r/titraio/titra
- Releases: https://github.com/titraio/titra/releases
