---
name: myfin-budget
description: MyFin Budget recipe for open-forge. Self-hosted personal finance platform with web UI, REST API, and Android app. Budget management, income/spending tracking, financial forecasting. Node.js + MySQL + React. Docker. GPL-3.0. Source: https://github.com/afaneca/myfin
---

# MyFin Budget

Self-hosted personal finance platform. Covers budgeting, income/expense tracking, financial forecasting, and account management. Ships as three components: a React web frontend, a Node.js REST API, and an Android mobile app. MySQL backend. Docker Compose based deployment. GPL-3.0 licensed.

Upstream: https://github.com/afaneca/myfin | API: https://github.com/aFaneca/myfin-api | Android: https://github.com/aFaneca/myfin-android

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker Compose | Official deployment method |
| Any | Manual (Node.js + MySQL) | See API repo README |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | VITE_MYFIN_BASE_API_URL | Public URL of the API, e.g. https://myfin.example.com:3001 |
| config | DB_NAME | MySQL database name (default: myfin) |
| config | DB_USER | MySQL user (default: myfin) |
| config | DB_PW | MySQL password |
| config | DB_HOST | Database hostname (default: db when using compose) |
| config | DB_PORT | Database port (default: 3306) |
| config (optional) | SMTP_HOST, SMTP_PORT, SMTP_SECURE | Email server for notifications |
| config (optional) | SMTP_USER, SMTP_PASSWORD, SMTP_FROM | Email credentials |
| config | ENABLE_USER_SIGNUP | Set true to allow new registrations (default: false) |
| config | BYPASS_SESSION_CHECK | Leave false in production |
| config | TRUST_PROXY | Set 1 if behind a reverse proxy (Traefik, Nginx) |

## Software-layer concerns

### Services

| Service | Port | Description |
|---|---|---|
| myfin-frontend | 8181 | React web UI |
| myfin-api | 3001 | Node.js REST API |
| db | 3306 | MySQL 8.4 |

### Key notes

- Frontend connects to API via VITE_MYFIN_BASE_API_URL -- must be set to the public API URL
- ENABLE_USER_SIGNUP defaults to false -- admin creates accounts manually
- TRUST_PROXY=1 needed when behind a reverse proxy (Express trust proxy)
- Database healthcheck in compose ensures API waits for MySQL to be ready

## Install -- Docker Compose

```yaml
services:
  db:
    image: mysql:8.4
    restart: always
    container_name: db
    environment:
      MYSQL_ROOT_PASSWORD: myfinrootpassword
      MYSQL_DATABASE: myfin
      MYSQL_USER: myfin
      MYSQL_PASSWORD: myfinpassword
    ports:
      - "3306:3306"
    volumes:
      - db_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "--silent"]

  myfin-api:
    image: ghcr.io/afaneca/myfin-api:latest
    container_name: myfin-api
    restart: unless-stopped
    ports:
      - "3001:3001"
    environment:
      - DB_NAME=myfin
      - DB_USER=myfin
      - DB_PW=myfinpassword
      - DB_PORT=3306
      - DB_HOST=db
      - SMTP_HOST=
      - SMTP_PORT=
      - SMTP_SECURE=
      - SMTP_USER=
      - SMTP_PASSWORD=
      - SMTP_FROM=
      - PORT=3001
      - LOGGING=false
      - BYPASS_SESSION_CHECK=false
      - ENABLE_USER_SIGNUP=false
      - TRUST_PROXY=1
    depends_on:
      db:
        condition: service_healthy

  myfin-frontend:
    image: ghcr.io/afaneca/myfin:latest
    container_name: myfin-frontend
    restart: unless-stopped
    ports:
      - "8181:80"
    environment:
      - VITE_MYFIN_BASE_API_URL=https://myfin.example.com:3001
    depends_on:
      myfin-api:
        condition: service_healthy

volumes:
  db_data:
```

```bash
docker compose up -d
# Web UI at http://yourserver:8181
# API at http://yourserver:3001
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
# API handles DB migrations on startup
```

## Gotchas

- VITE_MYFIN_BASE_API_URL must point to the publicly accessible API URL: if the frontend is accessed from outside your LAN, this must be a public URL (not localhost).
- ENABLE_USER_SIGNUP=false by default: the first user must be created via API or by enabling signup temporarily.
- Behind a reverse proxy: set TRUST_PROXY=1 on the API; configure your proxy to forward X-Forwarded-For headers correctly.
- MySQL root password: the MYSQL_ROOT_PASSWORD is required by the MySQL image even though the app uses a separate user -- keep it secure.
- Android app is a separate project (myfin-android) and connects to the same API endpoint.

## Links

- Source (frontend): https://github.com/afaneca/myfin
- Source (API): https://github.com/aFaneca/myfin-api
- Source (Android): https://github.com/aFaneca/myfin-android
- Docker images: https://github.com/afaneca/myfin/pkgs/container/myfin
