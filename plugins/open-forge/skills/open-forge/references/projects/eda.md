# EDA (Edalitics)

**Open-source analytics and dashboarding platform** (formerly Enterprise Data Analytics). No-code dashboard creation for non-technical users, with advanced SQL mode for power users. Metadata-driven; connects to databases and creates shareable reports and KPI dashboards.

**Official site:** https://www.edalitics.com  
**Source:** https://github.com/jortilles/EDA  
**Demo:** https://free.edalitics.com  
**License:** AGPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | Docker (all-in-one) | Easiest path — includes MongoDB, API, frontend |
| Linux | Node.js + MongoDB (native) | Full control; more setup |

---

## System Requirements

- Docker (all-in-one image includes everything)
- Or: Node.js, TypeScript/Angular, MongoDB (for native install)

---

## Inputs to Collect

### Provision phase
| Input | Description | Default |
|-------|-------------|---------|
| `HTTP_PORT` | External port | `80` |
| `MONGODB_URI` | MongoDB connection string (external DB) | Embedded in all-in-one image |

### Configure phase (first run)
| Input | Description |
|-------|-------------|
| Data source connection | Database connection details (PostgreSQL, MySQL, MongoDB, etc.) |
| Admin email / password | Initial admin user |

---

## Software-layer Concerns

### Docker (all-in-one — quickest)
```bash
docker run -p 80:80 jortilles/eda:latest
```
Access at `http://localhost`.

### Docker Compose (with persistent MongoDB)
```yaml
services:
  eda:
    image: jortilles/eda:latest
    ports:
      - '80:80'
    environment:
      - MONGODB_URI=mongodb://mongo:27017/EDA
    depends_on:
      - mongo
    restart: unless-stopped

  mongo:
    image: mongo:6
    volumes:
      - eda_mongo:/data/db
    restart: unless-stopped

volumes:
  eda_mongo:
```

### MongoDB config (native install)
Edit `EDA/eda/eda_api/config/database.config.js`:
```js
module.exports = {
    url: "mongodb://127.0.0.1:27017/EDA"
};
```

### Build from source
```bash
git clone https://github.com/jortilles/EDA.git
cd EDA
# Build frontend (Angular)
cd eda/eda-app && npm install && npm run build
# Build/run API (Node.js)
cd ../eda_api && npm install && npm start
```

### Key features
- No-code drag-and-drop dashboard builder
- Advanced SQL query mode
- Tree mode for exploring data models
- KPI definitions with automatic email alerts
- Public shareable dashboard URLs
- Row Level Security (RLS) per data source
- Connects to: PostgreSQL, MySQL/MariaDB, MongoDB, Oracle, SQL Server, and more

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```
Back up MongoDB data before upgrading. Check release notes for migration steps.

---

## Gotchas

- **MongoDB is required** for EDA's metadata store (dashboards, data models, users). The all-in-one Docker image bundles MongoDB; for production use a separate persistent MongoDB container or managed service.
- **Oracle support** requires placing Oracle Instant Client at `/eda/oracle/instantclient` inside the container (path is configurable via `LD_LIBRARY_PATH`).
- **Email alerts require Chromium** — the Dockerfile installs Playwright/Chromium for PDF/screenshot report generation. The image is large (~1-2GB) as a result.
- **Active development.** With 270+ commits in April 2026, the API may have breaking changes between versions.
- **SaaS option available** at https://free.edalitics.com if you don't want to self-host.

---

## References

- Upstream README: https://github.com/jortilles/EDA#readme
- Docs / tutorials: https://www.edalitics.com
- Demo instance: https://free.edalitics.com
