# Dashwise

A homelab dashboard that brings all your self-hosted services into one place. Features GUI-based link management, SSO via OIDC (PocketBase), RSS news feeds, push notifications, Spotlight-style search with bangs, modular widgets, downtime monitoring, and integrations with Karakeep, Dashdot, Beszel, and Jellyfin. Three-container stack: Next.js frontend, PocketBase backend, and a jobs/scheduler service.

- **Official site / docs:** https://github.com/andreasmolnardev/dashwise
- **Docker image:** `andreasmolnardev/dashwise:stable`
- **License:** Open-source

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | Docker Compose | Three containers: dashwise + pocketbase + jobs |

---

## Inputs to Collect

### Deploy Phase

**Main container (`dashwise`):**
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `NEXT_PUBLIC_PB_URL` | Yes | `http://pocketbase:8090` | URL of the PocketBase instance |
| `PB_ADMIN_EMAIL` | Yes | `default@dashwise.local` | PocketBase admin email |
| `PB_ADMIN_PASSWORD` | Yes | `DashwiseIsAwesome` | PocketBase admin password — **change this!** |
| `NEXT_PUBLIC_APP_URL` | Yes | `http://localhost:3000` | Public URL of the Dashwise web app |
| `NEXT_PUBLIC_ENABLE_SSO` | No | `false` | Enable OIDC SSO via PocketBase |
| `NEXT_PUBLIC_INTEGRATIONS_ENABLE_SSL` | No | `false` | Enable SSL for integration calls |
| `NEXT_PUBLIC_DEFAULT_BG_URL` | No | `/dashboard-wallpaper.png` | Default wallpaper URL |
| `NEXT_PUBLIC_JOBS_WEBHOOK_ENABLE` | No | `false` | Enable jobs webhook explicitly |
| `NEXT_PUBLIC_JOBS_URL` | No | `http://127.0.0.1:3001` | Internal jobs webhook URL |

**Jobs container:**
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `PB_URL` | Yes | `http://pocketbase:8090` | Internal PocketBase API URL |
| `DASHWISE_URL` | Yes | `http://dashwise:3000` | Internal Dashwise URL |
| `PB_ADMIN_EMAIL` | Yes | `default@dashwise.local` | PocketBase admin email |
| `PB_ADMIN_PASSWORD` | Yes | `DashwiseIsAwesome` | PocketBase admin password |
| `SEARCHITEMS_SCHEDULE` | No | `*/10 * * * *` | Search indexing cron schedule |
| `ENABLE_ICONS_REFRESH` | No | `false` | Enable automatic icon refresh |
| `PULL_ICONS_SCHEDULE` | No | `0 */6 * * *` | Icon refresh cron schedule |
| `MONITORING_INDEXER_SCHEDULE` | No | `*/10 * * * *` | Monitoring indexer cron schedule |
| `MONITORING_RUNNER_SCHEDULE` | No | `*/1 * * * *` | Monitoring runner cron schedule |
| `ALLOW_SSL` | No | `false` | Enable SSL for internal service communication |

---

## Software-Layer Concerns

### Config
- All configuration via environment variables
- SSO configured through PocketBase admin UI (OAuth2/OIDC providers)

### Data Directories
- `./pocketbase:/app/pb_data` — PocketBase database, user data, settings

### Ports
- `3016` (dashwise web UI — maps to internal 3000)
- `8092` (PocketBase admin — maps to internal 8090)
- `3001` (jobs service)

### Architecture
- `dashwise` — Next.js web frontend + API layer
- `pocketbase` — Backend database, auth, file storage
- `jobs` — Background scheduler for indexing, monitoring, icon refresh

---

## Minimal docker-compose.yml

```yaml
services:
  dashwise:
    image: andreasmolnardev/dashwise:stable
    ports:
      - "3016:3000"
    restart: unless-stopped
    environment:
      PB_ADMIN_EMAIL: admin@example.com
      PB_ADMIN_PASSWORD: changeme_strong_password
      NEXT_PUBLIC_PB_URL: http://pocketbase:8090
      NEXT_PUBLIC_APP_URL: http://localhost:3016
    depends_on:
      - pocketbase

  pocketbase:
    image: andreasmolnardev/dashwise-pb:stable
    volumes:
      - ./pocketbase:/app/pb_data
    ports:
      - "8092:8090"
    restart: unless-stopped
    environment:
      PB_ADMIN_EMAIL: admin@example.com
      PB_ADMIN_PASSWORD: changeme_strong_password

  jobs:
    image: andreasmolnardev/dashwise-jobs:stable
    ports:
      - "3001:3001"
    environment:
      PB_URL: http://pocketbase:8090
      DASHWISE_URL: http://dashwise:3000
      PB_ADMIN_EMAIL: admin@example.com
      PB_ADMIN_PASSWORD: changeme_strong_password
    restart: unless-stopped
```

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

PocketBase data persists in the mounted volume.

---

## Gotchas

- **Change default passwords:** `DashwiseIsAwesome` is the example password — always set a strong password before deploying
- **PB_ADMIN_EMAIL/PASSWORD must match** across dashwise, pocketbase, and jobs containers
- **NEXT_PUBLIC_APP_URL:** Set to your actual public URL (with port if non-standard) for proper SSO redirects and link generation
- **SSO:** Uses PocketBase's built-in OAuth2; tested with PocketId but should work with any OIDC provider configured in PocketBase
- **Jobs webhook:** Automatically enabled if `NEXT_PUBLIC_JOBS_URL` is set to a non-default value; explicit enable via `NEXT_PUBLIC_JOBS_WEBHOOK_ENABLE=true`
- **Under active development:** Integration logic is being revamped; expect breaking changes between releases

---

## References
- README: https://github.com/andreasmolnardev/dashwise
- docker-compose.yaml: https://raw.githubusercontent.com/andreasmolnardev/dashwise/HEAD/docker-compose.yaml
