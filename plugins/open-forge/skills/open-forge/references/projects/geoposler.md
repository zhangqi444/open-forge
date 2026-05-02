# Geoposler

**What it is:** A self-hosted email campaign management application. Create HTML email templates, manage contact lists, and send bulk campaigns via SMTP. Built with React + Node.js + MySQL; fully Dockerized.

> ⚠️ **Project archived.** The author has archived Geoposler in favor of [Listmonk](https://github.com/knadh/listmonk), which they recommend as a more mature and actively maintained alternative. Geoposler remains available for reference but receives no further updates.

**Official URL:** https://github.com/garanda21/geoposler
**Container:** `ghcr.io/garanda21/geoposler:latest`
**License:** MIT
**Stack:** React + Vite + Tailwind CSS (frontend) + Node.js (backend) + MySQL

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended; includes MySQL sidecar |

---

## Inputs to Collect

### Pre-deployment (required)
- `DB_HOST` — MySQL hostname (use service name in compose, e.g. `mysql`)
- `DB_USER` — MySQL username (e.g. `root`)
- `DB_PASSWORD` — MySQL password
- `DB_NAME` — MySQL database name
- SMTP credentials — configured in the web UI after first launch

---

## Software-Layer Concerns

**Docker Compose:**
```yaml
services:
  geoposler:
    image: ghcr.io/garanda21/geoposler:latest
    ports:
      - "3454:80"
    environment:
      - DB_HOST=mysql
      - DB_USER=root
      - DB_PASSWORD=mypassword
      - DB_NAME=mycooldb
    depends_on:
      mysql:
        condition: service_healthy
    restart: unless-stopped

  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: mypassword
      MYSQL_DATABASE: mycooldb
    volumes:
      - mysql_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 3

volumes:
  mysql_data:
```

**Default port:** `3454`

**Important:** MySQL must be healthy before Geoposler starts — always use the `depends_on` + `healthcheck` configuration shown above.

**SMTP configuration:** Done via the web UI after first launch — no environment variables needed for mail settings.

**Upgrade procedure:** Archived — no new versions. To update the container image: `docker compose pull && docker compose up -d`.

---

## Gotchas

- **Archived project** — no bug fixes, security patches, or new features; consider [Listmonk](https://github.com/knadh/listmonk) for a maintained alternative
- **MySQL must be healthy first** — starting without the healthcheck causes Geoposler to fail on startup; the compose example handles this correctly
- **No auth by default** — add a reverse proxy with authentication if internet-facing

---

## Links
- GitHub (archived): https://github.com/garanda21/geoposler
- Recommended alternative: https://github.com/knadh/listmonk
- Container: ghcr.io/garanda21/geoposler:latest
