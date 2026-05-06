---
name: fusio
description: Fusio recipe for open-forge. Open-source API management platform — build and expose REST APIs, developer portal, SDK generation, monetization, MCP/AI agent support. Docker Compose install. Upstream: https://github.com/apioo/fusio
---

# Fusio

Open-source API management platform. Turn your backend logic, databases, and microservices into professional REST APIs — complete with a developer portal, SDK generation, monetization, analytics, and AI/MCP agent support.

2,086 stars · AGPL-3.0

Upstream: https://github.com/apioo/fusio
Website: https://www.fusio-project.org/
Docs: https://docs.fusio-project.org/
Demo: https://fusio-project.org/demo
Docker Hub: https://hub.docker.com/r/fusio/fusio

## What it is

Fusio provides a complete API management and backend platform:

- **Database API Gateway** — Instantly expose MySQL, PostgreSQL, and other databases as REST APIs
- **Microservice Gateway** — Route and orchestrate traffic between distributed services
- **Custom API logic** — Build backend logic using reusable PHP or JavaScript actions
- **API developer portal** — Self-service portal for third-party developers with docs, testing tools, and API keys
- **SDK generation** — Auto-generate client SDKs for all major languages
- **API monetization** — Subscription plans, quotas, and automated billing
- **Analytics & monitoring** — Real-time API usage, performance metrics, and error logging
- **MCP integration** — Native Model Context Protocol support to expose APIs as tools for AI agents
- **AI-assisted development** — Generate backend logic from natural language prompts
- **OAuth2/JWT authentication** — Built-in auth layer for all APIs
- **Rate limiting** — Per-plan quota enforcement
- **OpenAPI / Swagger** — Auto-generated API documentation

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker Compose | fusio + mysql | Simplest deploy; official image |
| Docker Compose | fusio + postgres | PostgreSQL variant |
| Bare metal | PHP 8.1+ + MySQL/PostgreSQL | Manual install from release or git |

## Inputs to collect

### Phase 1 — Pre-install
- Database type (MySQL 8.0+ or PostgreSQL)
- Database credentials
- Backend admin username, email, and password
- FUSIO_PROJECT_KEY — 32-char random hex string
- Public URL for the API

### Phase 2 — Runtime config
  FUSIO_PROJECT_KEY=<32-char-random-hex>
  FUSIO_CONNECTION=pdo-mysql://user:pass@mysql-fusio/fusio
  FUSIO_BACKEND_USER=admin
  FUSIO_BACKEND_EMAIL=admin@example.com
  FUSIO_BACKEND_PW=<secure-password>

## Software-layer concerns

### Ports
- 8080 → 80 — HTTP (use reverse proxy for HTTPS)
- Admin backend at /apps/fusio
- API at /

### Config paths
- /var/www/html/.env — main configuration (inside container, mapped from environment vars)
- /var/www/html/config/ — additional config directory

### Supported databases
- pdo-mysql://user:pass@host/dbname
- pdo-pgsql://user:pass@host/dbname
- pdo-sqlite:///path/to/file.db

## Docker Compose install

  version: '3'
  services:
    fusio:
      image: fusio/fusio:latest
      restart: always
      ports:
        - "8080:80"
      environment:
        FUSIO_PROJECT_KEY: "42eec18ffdbffc9fda6110dcc705d6ce"
        FUSIO_CONNECTION: "pdo-mysql://fusio:secret@mysql-fusio/fusio"
        FUSIO_BACKEND_USER: "admin"
        FUSIO_BACKEND_EMAIL: "admin@example.com"
        FUSIO_BACKEND_PW: "changeme"
      depends_on:
        - mysql-fusio

    mysql-fusio:
      image: mysql:8.0
      restart: always
      environment:
        MYSQL_RANDOM_ROOT_PASSWORD: "1"
        MYSQL_USER: "fusio"
        MYSQL_PASSWORD: "secret"
        MYSQL_DATABASE: "fusio"
      volumes:
        - ./db:/var/lib/mysql

After startup:
- Backend: http://localhost:8080/apps/fusio
- Login with FUSIO_BACKEND_USER / FUSIO_BACKEND_PW credentials

## Upgrade procedure

1. Backup database: docker exec <mysql-container> mysqldump -u fusio -psecret fusio > backup.sql
2. Pull new image: docker pull fusio/fusio:latest
3. Stop and restart: docker compose up -d --force-recreate fusio
4. Fusio runs database migrations automatically on start
5. Verify backend access at /apps/fusio

## Gotchas

- FUSIO_PROJECT_KEY — must be set to a consistent random value; changing it invalidates all existing tokens
- AGPL-3.0 — modifications to Fusio source must be open-sourced; API products built on top are your own
- Admin portal path — backend UI is at /apps/fusio, not the root
- Getting started guide — after first login, follow https://docs.fusio-project.org/docs/bootstrap to set up your first API
- PHP memory — complex API actions may need higher PHP memory_limit; configure via container env or php.ini mount
- Monetization requires Stripe — billing/subscription features integrate with Stripe; configure API keys in backend
- MCP server — Fusio can act as an MCP server for AI agents; configure in backend under AI/MCP settings

## Links

- Upstream README: https://github.com/apioo/fusio/blob/master/README.md
- Documentation: https://docs.fusio-project.org/
- Getting started: https://docs.fusio-project.org/docs/bootstrap
- Demo: https://fusio-project.org/demo
- Docker Hub: https://hub.docker.com/r/fusio/fusio
