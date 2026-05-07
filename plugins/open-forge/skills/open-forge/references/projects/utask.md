---
name: µTask (uTask)
description: Lightweight automation engine that models and executes business processes declared in YAML. Built by OVH in Go. Requires only PostgreSQL. BSD-3-Clause licensed.
website: https://github.com/ovh/utask
source: https://github.com/ovh/utask
license: BSD-3-Clause
stars: 1374
tags:
  - automation
  - workflow
  - orchestration
  - devops
platforms:
  - Go
  - Docker
---

# µTask (uTask)

µTask is an automation engine for the cloud. It allows you to model business processes as declarative YAML templates — defining inputs, action graphs, and dependencies. µTask asynchronously executes each action, handles transient errors, and maintains an encrypted, auditable trace of all execution states.

Built by OVH, µTask is designed to be operationally simple (only requires PostgreSQL) while being highly extensible via custom Go plugins.

Source: https://github.com/ovh/utask  
Latest release: v1.34.0 (March 2026)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Docker + PostgreSQL | Recommended; official docker-compose provided |
| Kubernetes | Docker image + external PostgreSQL | Suitable for production deployments |
| Any Linux VM | Go binary + PostgreSQL | Build from source |

## Inputs to Collect

**Phase: Planning**
- PostgreSQL connection string (`CFG_DATABASE`)
- Admin username(s) for `admin_usernames` in `CFG_UTASK_CFG`
- Basic auth credentials (`CFG_BASIC_AUTH`) — JSON map of username → password
- Group auth assignments (`CFG_GROUPS_AUTH`) — admins and resolvers
- Encryption key (`CFG_ENCRYPTION_KEY`) — AES-GCM key for encrypting task data
- Callback base URL (`CFG_CALLBACK_CONFIG`) — used for human-in-the-loop steps
- Port to expose (default: `8081`)

**Phase: First Boot**
- Load task templates into `./templates/` directory
- Create any custom scripts in `./scripts/`

## Software-Layer Concerns

**Docker Compose:**
```yaml
version: "3"
services:
  utask:
    image: ovhcom/utask:stable
    command: ["/wait-for-it.sh", "db:5432", "--", "/app/utask"]
    environment:
      DEBUG: 'false'
      CONFIGURATION_FROM: 'env:CFG'
      CFG_DATABASE: 'postgres://user:CHANGE_ME@db/utask?sslmode=disable'
      CFG_UTASK_CFG: '{"admin_usernames":["admin"],"application_name":"µTask"}'
      CFG_CALLBACK_CONFIG: '{"base_url": "https://utask.example.com"}'
      CFG_BASIC_AUTH: '{"admin":"CHANGE_ME"}'
      CFG_GROUPS_AUTH: '{"admins":["admin"],"resolvers":["admin"]}'
      CFG_ENCRYPTION_KEY: '{"identifier":"storage","cipher":"aes-gcm","timestamp":1535627466,"key":"<generate-32-byte-hex-key>"}'
    ports:
      - 8081:8081
    volumes:
      - ./templates:/app/templates:ro
      - ./scripts:/app/scripts:ro
      - ./functions:/app/functions:ro
    depends_on:
      - db

  db:
    image: postgres:14-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: CHANGE_ME
      POSTGRES_DB: utask
    volumes:
      - utask_db:/var/lib/postgresql/data

volumes:
  utask_db:
```

**Quick start (from upstream):**
```bash
mkdir utask && cd utask
wget https://github.com/ovh/utask/releases/latest/download/install-utask.sh
sh install-utask.sh
docker-compose up
```

**Config paths (env-based):**
- All config via environment variables prefixed with `CFG_`
- Templates: `./templates/*.yaml` (mounted read-only)
- Scripts: `./scripts/` (mounted read-only)

**Ports:**
- `8081` → Web UI + API
- UI dashboard: `http://localhost:8081/ui/dashboard`
- API schema: `http://localhost:8081/unsecured/spec.json`

## Upgrade Procedure

1. Pull new image: `docker pull ovhcom/utask:stable`
2. `docker-compose down && docker-compose up -d`
3. µTask applies DB schema migrations automatically on startup
4. Review changelog: https://github.com/ovh/utask/releases

## Gotchas

- **Encryption key is critical**: Generate a strong AES-GCM key before first run; changing it later requires re-encrypting all stored task data
- **Low recent commit activity**: Repository shows sparse commits in 2025-2026 (1-3/month); project is stable but not rapidly evolving
- **Human-in-the-loop**: µTask supports forms for human approval steps; requires `CFG_CALLBACK_CONFIG` with a reachable public URL
- **Custom actions**: Extending with custom action types requires writing Go code and recompiling — not purely configuration-driven
- **Resolver/admin roles**: Task templates specify which groups can resolve (approve) them; configure `CFG_GROUPS_AUTH` carefully
- **PostgreSQL only**: No support for MySQL or SQLite — PostgreSQL is the only supported database

## Links

- Upstream README: https://github.com/ovh/utask/blob/master/README.md
- Task template authoring: https://github.com/ovh/utask/blob/master/docs/templates.md
- Plugin development: https://github.com/ovh/utask/blob/master/docs/plugins.md
- Releases: https://github.com/ovh/utask/releases
