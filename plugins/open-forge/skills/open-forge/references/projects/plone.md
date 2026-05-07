---
name: plone
description: Plone recipe for open-forge. Powerful open-source enterprise CMS built on Python/Zope. Plone 6 supports Volto (React) and Classic UI frontends. ZPL-2.0 licensed. Source: https://github.com/plone
---

# Plone

Enterprise-grade open-source CMS built on Python and Zope, now in version 6. Plone 6 ships two frontend options: **Volto** (modern React-based, default) and **Classic UI** (traditional server-side). Docker images from the Plone community are the recommended path. ZPL-2.0 licensed. Source: <https://github.com/plone>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | Docker Compose (backend + frontend) | Recommended for Plone 6 + Volto |
| Any Linux | Docker (single container, Classic UI) | Simpler — no separate frontend |
| Any Linux | pip / virtualenv | Manual install; requires Python 3.11+ |

> Plone 6 with Volto requires TWO containers: `plone/plone-backend` (Zope/REST API) + `plone/plone-frontend` (Next.js/Volto). Classic UI uses backend only.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. cms.example.com |
| "Frontend type?" | volto / classic | volto = React frontend; classic = server-side |
| "Plone version?" | e.g. 6.0 | Pin to minor version |
| "Site ID?" | String | e.g. Plone — used in URL path |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Data volume path?" | Path | e.g. /opt/plone/data |
| "TLS?" | Yes / No | Via reverse proxy |

## Software-Layer Concerns

- **Two-container stack for Volto**: Backend on port 8080, frontend on port 3000. Frontend proxies API calls to backend.
- **ZODB**: Plone uses the Zope Object Database (ZODB) by default — file-based, stored in `Data.fs`. No SQL required.
- **RelStorage**: Optional — stores ZODB data in PostgreSQL/MySQL for HA/clustering.
- **Data persistence**: Mount `/data` in the backend container (contains `Data.fs` and blob storage).
- **Site creation**: Pass `SITE=Plone` env var on first run to auto-create a Plone site instance.
- **TYPE env var**: `TYPE=classic` for Classic UI, `TYPE=volto` (default) for Volto.
- **Port 8080**: Backend REST API. Not for direct public access — front by NGINX.
- **Versioned image tags**: Use `6.0`, `6.1`, or specific `6.0.14` — tag `latest` not recommended.
- **LISTEN_PORT**: Override Zope's internal listen port (useful in Kubernetes pod networking).

## Deployment

### Option A — Classic UI (single container)

```bash
docker run -d \
  --name plone \
  -p 127.0.0.1:8080:8080 \
  -e SITE=Plone \
  -e TYPE=classic \
  -v /opt/plone/data:/data \
  plone/plone-backend:6.0
```

### Option B — Plone 6 + Volto (two containers)

```yaml
# docker-compose.yaml
version: "3"

services:
  backend:
    image: plone/plone-backend:6.0
    restart: unless-stopped
    environment:
      SITE: Plone
      TYPE: volto
    volumes:
      - /opt/plone/data:/data
    ports:
      - "127.0.0.1:8080:8080"

  frontend:
    image: plone/plone-frontend:latest
    restart: unless-stopped
    environment:
      RAZZLE_INTERNAL_API_PATH: http://backend:8080/Plone
      RAZZLE_DEV_PROXY_API_PATH: http://backend:8080/Plone
    depends_on:
      - backend
    ports:
      - "127.0.0.1:3000:3000"
```

```bash
docker compose up -d
# First run: backend creates the Plone site (~30-60s)
```

### NGINX reverse proxy (Volto)

```nginx
server {
    listen 443 ssl;
    server_name cms.example.com;

    # Volto frontend
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Backend API (accessed by Volto server-side rendering)
    location /++api++ {
        proxy_pass http://127.0.0.1:8080/Plone/++api++;
        proxy_set_header Host $host;
    }
}
```

## Upgrade Procedure

1. Back up `/opt/plone/data` (especially `Data.fs` and `blobstorage/`)
2. `docker compose pull` — fetch new images
3. `docker compose up -d` — recreate containers (Plone runs DB migrations automatically)
4. Monitor logs: `docker compose logs -f backend`

## Gotchas

- **Two containers, one site**: Volto frontend and Plone backend must both run for the site to work. Backend alone shows Zope ZMI, not the Plone site.
- **ZODB backup critical**: `Data.fs` is the database. Back it up before every upgrade.
- **Site ID in URL**: Default site ID `Plone` means API is at `/Plone/++api++`. Change `SITE` env var to customize.
- **Classic vs Volto on same instance**: Not easy to switch post-deploy — choose before first run.
- **RelStorage for HA**: Single-server `Data.fs` is fine for most deployments; clustering requires RelStorage + PostgreSQL.
- **Plone 5 images deprecated**: The old Buildout-based Docker images for Plone 5 are separate and unsupported.
- **Python 3.12 in 6.1**: The 6.1.x image line upgrades Debian (bookworm) and Python (3.12) — test before upgrading from 6.0.

## Links

- Website: https://plone.org/
- Source: https://github.com/plone
- Plone 6 Docs: https://6.docs.plone.org/
- Backend image: https://github.com/plone/plone-backend
- Frontend image: https://github.com/plone/plone-frontend
- Docker Hub: https://hub.docker.com/r/plone/plone-backend
