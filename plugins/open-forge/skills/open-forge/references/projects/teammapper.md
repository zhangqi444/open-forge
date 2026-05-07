---
name: TeamMapper
description: Self-hosted collaborative mind mapping. Real-time multi-user sessions via WebSockets, image/color/link support, GDPR-friendly auto-deletion, import/export (JSON/SVG/PDF/PNG/Mermaid). PostgreSQL backend. MIT licensed.
website: https://github.com/b310-digital/teammapper
source: https://github.com/b310-digital/teammapper
license: MIT
stars: 454
tags:
  - mind-mapping
  - collaboration
  - real-time
  - brainstorming
platforms:
  - JavaScript
  - Docker
---

# TeamMapper

TeamMapper is a self-hosted, real-time collaborative mind mapping application. Share mind map sessions with your team and edit simultaneously via WebSockets. Features rich node customization (images, colors, fonts, links), multiple export formats (JSON, SVG, PDF, PNG, Mermaid), GDPR-friendly auto-deletion after a configurable number of days, and optional AI assistance. Live demo at https://teammapper.org.

Source: https://github.com/b310-digital/teammapper
Live demo: https://teammapper.org
Container: ghcr.io/b310-digital/teammapper

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Docker Compose + PostgreSQL | Recommended |
| Any Linux VM / VPS | Node.js + PostgreSQL | Native install |

## Inputs to Collect

**Phase: Planning**
- PostgreSQL password
- Port to expose (default: 80 → container port 3000)
- `DELETE_AFTER_DAYS` — days until unused maps are auto-deleted (default: 30)
- `JWT_SECRET` — random secret for session tokens
- Optional: AI LLM credentials (provider, URL, token, model) for AI-assisted mapping

## Software-Layer Concerns

**Docker Compose (production):**

```yaml
version: "3.8"

services:
  app:
    image: ghcr.io/b310-digital/teammapper:latest
    environment:
      MODE: PROD
      BINDING: "0.0.0.0"
      POSTGRES_DATABASE: teammapper-db
      POSTGRES_HOST: postgres
      POSTGRES_PASSWORD: CHANGE_ME
      POSTGRES_PORT: 5432
      POSTGRES_SSL: "false"
      POSTGRES_SSL_REJECT_UNAUTHORIZED: "false"
      POSTGRES_USER: teammapper-user
      POSTGRES_QUERY_TIMEOUT: "100000"
      POSTGRES_STATEMENT_TIMEOUT: "100000"
      DELETE_AFTER_DAYS: "30"
      JWT_SECRET: CHANGE_ME_RANDOM_SECRET
      YJS_ENABLED: "true"
      AI_ENABLED: "false"
    ports:
      - "80:3000"
    depends_on:
      - postgres

  postgres:
    image: postgres:12-alpine
    environment:
      POSTGRES_DB: teammapper-db
      POSTGRES_USER: teammapper-user
      POSTGRES_PASSWORD: CHANGE_ME
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

```bash
docker compose up -d
# Visit http://localhost
```

**Key environment variables:**

| Variable | Description | Default |
|----------|-------------|---------|
| MODE | PROD or DEV | DEV |
| POSTGRES_* | Database connection details | (required) |
| DELETE_AFTER_DAYS | Auto-delete maps after N days | 30 |
| JWT_SECRET | Secret for session JWT tokens | (required) |
| YJS_ENABLED | Enable real-time collaboration via Yjs | true |
| AI_ENABLED | Enable AI mind map assistance | false |
| AI_LLM_PROVIDER | LLM provider (if AI enabled) | — |
| AI_LLM_URL | LLM API URL | — |
| AI_LLM_TOKEN | LLM API token | — |
| AI_LLM_MODEL | Model name | — |

**Nginx reverse proxy:**

```nginx
server {
    listen 443 ssl;
    server_name mindmap.example.com;

    location / {
        proxy_pass http://127.0.0.1:80;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

WebSocket upgrade headers are required for real-time collaboration.

## Upgrade Procedure

1. `docker pull ghcr.io/b310-digital/teammapper:latest`
2. `docker compose down && docker compose up -d`
3. Database migrations run automatically on startup
4. Check releases: https://github.com/b310-digital/teammapper/releases

## Gotchas

- **WebSocket headers**: Real-time collaboration uses WebSockets — ensure your reverse proxy forwards `Upgrade` and `Connection` headers; without this, live collaboration breaks
- **JWT_SECRET**: Must be set and kept consistent across restarts — changing it invalidates all active sessions
- **Auto-deletion**: Maps are deleted after `DELETE_AFTER_DAYS` days of inactivity — warn users to export important maps or adjust the value
- **YJS_ENABLED**: Yjs powers the real-time sync; keep this enabled unless you only need single-user editing
- **AI feature**: Optional AI assistance requires an external LLM API (OpenAI-compatible); keep `AI_ENABLED=false` if not needed
- **No authentication by default**: TeamMapper has no built-in user auth — anyone with the URL can view/edit a map; protect with a reverse proxy if needed

## Links

- Upstream README: https://github.com/b310-digital/teammapper/blob/main/README.md
- Live demo: https://teammapper.org
- Container: ghcr.io/b310-digital/teammapper
- Releases: https://github.com/b310-digital/teammapper/releases
