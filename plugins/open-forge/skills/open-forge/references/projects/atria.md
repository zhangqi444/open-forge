# Atria

> Open-source event management and professional networking platform — manage conferences, fundraisers, and community events with multi-day scheduling, speaker management, real-time chat, attendee networking, sponsor tiers, and hybrid (virtual + in-person) support. Flask backend + React/Vite frontend + PostgreSQL.

**Official URL:** https://atria.gg  
**Docs:** https://docs.atria.gg  
**Source:** https://github.com/thesubtleties/atria

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended; all services included |
| Any Linux VPS/VM | Manual (Python + Node.js) | For development; production needs Docker |

**Requires:** PostgreSQL 15+, MinIO or S3-compatible storage (for file uploads), Redis (optional but recommended)

---

## Inputs to Collect

### Phase: Pre-Deploy
Two `.env` files are needed:

**`.env`** (Docker Compose / PostgreSQL):
| Input | Description | Example |
|-------|-------------|---------|
| `POSTGRES_USER` | DB username | `atria` |
| `POSTGRES_PASSWORD` | DB password | strong password |
| `POSTGRES_DB` | DB name | `atria` |

**`.env.development`** (Flask backend — full config):
| Input | Description | Example |
|-------|-------------|---------|
| `SECRET_KEY` | Flask secret key | `python -c "import secrets; print(secrets.token_hex(32))"` |
| `JWT_SECRET_KEY` | JWT signing secret | random 32+ char string |
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://atria:pass@db/atria` |
| `MINIO_ENDPOINT` / S3 config | Object storage for uploads | `minio:9000` or AWS S3 |
| `MINIO_ACCESS_KEY` / `MINIO_SECRET_KEY` | Storage credentials | see MinIO setup |
| `REDIS_URL` | Redis connection (optional) | `redis://redis:6379` |
| `MAIL_*` | SMTP settings for invitations (optional) | host, port, user, password |

---

## Software-Layer Concerns

### Quick Start (Docker Compose)
```bash
git clone https://github.com/thesubtleties/atria
cd atria

# Copy both env files
cp .env.example .env
cp .env.development.example .env.development

# Edit both .env files — set secrets + DB passwords at minimum
# (defaults work for local dev; change for production)

# Interactive chooser (recommended):
./dev-environment-chooser.sh
# Select option 1 (Standard Local Development)
# Say yes (y) to database seeding for sample data

# Or direct compose:
docker compose -f docker-compose.dev-vite.yml up
```

Access:
- Frontend: http://localhost:5173
- Backend API: http://localhost:5000
- API docs (Swagger): http://localhost:5000/new-swagger
- Health check: http://localhost:5000/api/health

### MinIO Setup
Atria requires object storage for uploaded images (event covers, sponsor logos, profile photos):
- Self-hosted option: [MinIO](https://github.com/minio/minio) — add to your compose stack
- Cloud option: AWS S3, DigitalOcean Spaces, or any S3-compatible service

### Redis
Optional but recommended for:
- Session/presence caching
- Socket.IO clustering (required for multi-worker deployments)
- App degrades gracefully without Redis (reduced real-time features)

### Data Directories
| Service | Purpose |
|---------|---------|
| PostgreSQL volume | All event, user, session, and networking data |
| MinIO/S3 bucket | Uploaded images and files |

### Stack
| Component | Technology |
|-----------|-----------|
| Backend | Python 3.13, Flask, SQLAlchemy |
| Frontend | React, Vite, Socket.IO client |
| Database | PostgreSQL 15 |
| Cache/RT | Redis 7 |
| Storage | MinIO / S3 |

---

## Upgrade Procedure

1. Pull latest: `git pull && docker compose pull`
2. Stop: `docker compose down`
3. Start: `docker compose up -d`
4. Database migrations run via SQLAlchemy on startup
5. Check docs for manual migration steps on major versions

---

## Gotchas

- **Two `.env` files required** — `.env` configures Docker Compose/PostgreSQL; `.env.development` configures the Flask app; both must exist before starting
- **MinIO/S3 is required** — file uploads (event images, sponsor logos) will fail without object storage configured; add MinIO to your compose stack or point at an S3 service
- **Seed database on first run** — the interactive chooser offers to seed sample data; this is helpful for exploring the UI but will populate your DB with test organizations/events
- **Redis optional** — Socket.IO real-time chat still works without Redis in single-worker mode; required for clustering/multi-worker production deployments
- **AGPL-3.0** — if you modify and deploy, you must publish your changes under the same license

---

## Links
- GitHub: https://github.com/thesubtleties/atria
- Docs: https://docs.atria.gg
- Demo: https://atria.gg
