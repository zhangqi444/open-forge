---
name: Superdesk
description: End-to-end open-source news creation, production, curation, distribution, and publishing platform for newsrooms. Developed by Sourcefabric. AGPL-3.0.
website: https://superdesk.org/
source: https://github.com/superdesk/superdesk
license: AGPL-3.0
stars: 731
tags:
  - newsroom
  - publishing
  - media
  - cms
  - journalism
platforms:
  - Python
  - JavaScript
  - Docker
---

# Superdesk

Superdesk is an open-source end-to-end newsroom platform covering the full editorial workflow: story creation, editing, wire ingest, curation, assignment, production, and multi-channel publishing. Built by Sourcefabric, it's used by news organizations of all sizes. The stack consists of a Python/Flask API server and an Angular-based web client.

Official site: https://superdesk.org/  
Source (server): https://github.com/superdesk/superdesk  
Source (client): https://github.com/superdesk/superdesk-client-core  
Docs: https://superdesk.readthedocs.io/  
Latest: check https://github.com/superdesk/superdesk/releases

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux VM / VPS (4GB+ RAM) | Docker Compose | Recommended; official compose file provided |
| Kubernetes | Docker images | Production deployments |
| Bare metal Linux | Python 3.8 + MongoDB + Elasticsearch + Redis | Manual install for advanced users |

## Inputs to Collect

**Phase: Planning**
- Server hostname/IP or domain
- MongoDB connection URI
- Elasticsearch URL (7.x required)
- Redis URL
- Secret key (for session signing)
- Timezone (e.g., `Europe/London`)
- Whether to load demo data (`DEMO_DATA=1`) or start clean

**Phase: First Boot**
- Admin username, password, email (via `manage.py users:create`)

## Software-Layer Concerns

**Docker Compose (quickstart):**
```yaml
# Use the official docker-compose.yml from the repo
# https://github.com/superdesk/superdesk/blob/develop/docker-compose.yml
```

```bash
git clone https://github.com/superdesk/superdesk
cd superdesk
docker compose up -d

# Initialize data
docker compose exec superdesk-server python manage.py app:initialize_data

# Create admin user
docker compose exec superdesk-server python manage.py users:create \
  -u admin -p CHANGE_ME -e admin@example.com --admin

# Access at http://localhost:8080
```

**Full docker-compose services:**
```yaml
services:
  mongodb:
    image: mongo:6
  redis:
    image: redis:8
  elastic:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.17.29
    environment:
      - discovery.type=single-node
  superdesk-server:
    image: sourcefabricoss/superdesk-server:latest
    environment:
      - SUPERDESK_URL=http://localhost:8080/api
      - SUPERDESK_CLIENT_URL=http://localhost:8080
      - MONGO_URI=mongodb://mongodb/superdesk
      - ELASTICSEARCH_URL=http://elastic:9200
      - CELERY_BROKER_URL=redis://redis:6379/1
      - REDIS_URL=redis://redis:6379/1
      - SECRET_KEY=CHANGE_ME_LONG_RANDOM_STRING
      - DEFAULT_TIMEZONE=UTC
    ports:
      - 5000:5000
  superdesk-client:
    image: sourcefabricoss/superdesk-client:latest
    ports:
      - 8080:80
```

**Environment variables (server):**
- `MONGO_URI` — MongoDB connection string
- `ELASTICSEARCH_URL` — Elasticsearch 7.x URL
- `REDIS_URL` / `CELERY_BROKER_URL` — Redis URL
- `SECRET_KEY` — Long random string for session security
- `DEFAULT_TIMEZONE` — Newsroom timezone
- `DEMO_DATA` — Set to `1` to load sample content, `0` for clean

**Ports:**
- `8080` → Web client (Angular UI)
- `5000` → API server

## Upgrade Procedure

1. `docker pull sourcefabricoss/superdesk-server:latest && docker pull sourcefabricoss/superdesk-client:latest`
2. `docker compose down && docker compose up -d`
3. Run migrations if prompted: `docker compose exec superdesk-server python manage.py app:initialize_data`
4. Check upgrade notes: https://superdesk.readthedocs.io/en/latest/changelog.html

## Gotchas

- **Heavy stack**: Requires MongoDB, Elasticsearch 7.x, and Redis — minimum 4GB RAM recommended; 8GB+ for production
- **Elasticsearch 7.x only**: Not compatible with Elasticsearch 8.x; pin to `7.17.x`
- **Two repos**: Server and client are separate repositories — both need to be in sync on versions
- **Newsroom-specific**: Superdesk is purpose-built for professional news workflows (wire ingest, desks, assignments, publishing channels) — not a general-purpose CMS
- **Celery workers**: Background tasks (ingest, publishing) require Celery workers running alongside the server
- **Python 3.8**: Server targets Python 3.8; test carefully before upgrading Python version
- **Configuration depth**: Highly configurable for newsroom workflows but requires significant setup to connect to wire services, output channels (WordPress, social, etc.)

## Links

- Upstream README: https://github.com/superdesk/superdesk/blob/develop/README.md
- Documentation: https://superdesk.readthedocs.io/
- Client repo: https://github.com/superdesk/superdesk-client-core
- Docker Hub (server): https://hub.docker.com/r/sourcefabricoss/superdesk-server
- Docker Hub (client): https://hub.docker.com/r/sourcefabricoss/superdesk-client
- Releases: https://github.com/superdesk/superdesk/releases
