# Reactive Resume

Free and open-source resume builder that simplifies creating, updating, and sharing resumes. Supports multiple templates, real-time preview, PDF export, AI-assisted writing (optional), and full self-hosting with no tracking or data collection.

**Official site:** https://rxresu.me

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Recommended; requires PostgreSQL + Browserless + SeaweedFS |
| Any Linux host | Docker Compose (minimal) | Local filesystem for storage instead of SeaweedFS |
| VPS / cloud VM | Docker Compose + reverse proxy | Expose via Nginx/Traefik with HTTPS |

---

## Inputs to Collect

### Phase 1 — Planning
- Public-facing URL for the app (required — used for resume share links and PDF printing)
- Storage backend: SeaweedFS (default) or local filesystem
- Email/SMTP config (optional — used for account verification; logs to console if omitted)

### Phase 2 — Deployment
- `APP_URL` — public URL (e.g. `https://resume.example.com`)
- `AUTH_SECRET` — 32-byte random secret (`openssl rand -hex 32`)
- `BROWSERLESS_TOKEN` — token for headless Chrome PDF renderer
- PostgreSQL credentials (`POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`)
- S3/storage credentials if using SeaweedFS

---

## Software-Layer Concerns

### Docker Compose (`compose.yml`)

```yaml
name: reactive_resume

services:
  postgres:
    image: postgres:latest
    restart: unless-stopped
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
    volumes:
      - postgres_data:/var/lib/postgresql
    networks:
      - data_network

  browserless:
    image: ghcr.io/browserless/chromium:latest
    restart: unless-stopped
    environment:
      - QUEUED=10
      - CONCURRENT=5
      - TOKEN=change-me
    networks:
      - printer_network

  seaweedfs:
    image: chrislusf/seaweedfs:latest
    restart: unless-stopped
    command: server -s3 -filer -dir=/data -ip=0.0.0.0
    volumes:
      - seaweedfs_data:/data
    networks:
      - storage_network

  reactive_resume:
    image: ghcr.io/amruthpillai/reactive-resume:latest
    ports:
      - "3000:3000"
    environment:
      - TZ=Etc/UTC
      - NODE_ENV=production
      - APP_URL=http://localhost:3000
      - PRINTER_APP_URL=http://host.docker.internal:3000
      - PRINTER_ENDPOINT=ws://browserless:3000?token=change-me
      - DATABASE_URL=postgresql://postgres:postgres@postgres:5432/postgres
      - AUTH_SECRET=change-me-to-a-secure-secret-key-in-production
      - S3_ACCESS_KEY_ID=seaweedfs
      - S3_SECRET_ACCESS_KEY=seaweedfs
      - S3_ENDPOINT=http://seaweedfs:8333
      - S3_BUCKET=reactive-resume
      - S3_FORCE_PATH_STYLE=true
    depends_on:
      - postgres
      - browserless
    extra_hosts:
      - "host.docker.internal:host-gateway"
    networks:
      - data_network
      - printer_network
      - storage_network

volumes:
  postgres_data:
  seaweedfs_data:

networks:
  data_network:
  printer_network:
  storage_network:
```

### Key Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `APP_URL` | Yes | Public-facing URL (used in share links) |
| `PRINTER_APP_URL` | Yes | Internal URL for PDF renderer to reach the app |
| `PRINTER_ENDPOINT` | Yes | WebSocket URL for Browserless instance |
| `DATABASE_URL` | Yes | PostgreSQL connection string |
| `AUTH_SECRET` | Yes | Random 32-byte hex secret for session signing |
| `S3_*` | No | S3-compatible storage (omit to use local `/app/data`) |
| `SMTP_*` | No | Email settings (optional; defaults to console logging) |
| `FLAG_DISABLE_SIGNUPS` | No | Set `true` to prevent new registrations |
| `FLAG_DISABLE_EMAIL_AUTH` | No | Set `true` to disable email/password login |

### Data Directories
| Container path | Purpose |
|---------------|---------|
| `/var/lib/postgresql` | PostgreSQL data |
| `/data` (seaweedfs) | File/image storage |
| `/app/data` | Local filesystem storage (if S3 disabled) |

### Social OAuth (Optional)
Add to environment: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET`

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

Database schema migrations run automatically on startup.

---

## Gotchas

- **`APP_URL` must be the externally reachable URL** — PDF generation uses this to load the resume preview. Set `PRINTER_APP_URL` to an internal URL when the app is behind a reverse proxy.
- **Browserless is mandatory** — without it, PDF export fails. The alternative is `chromedp/headless-shell:latest` (see compose comments).
- **SeaweedFS vs local storage** — omit all `S3_*` variables to fall back to local filesystem at `/app/data`. Mount this path to a volume.
- **`host.docker.internal`** — the `extra_hosts` entry is needed on Linux for the printer to reach the app via its public URL when running in Docker.
- **PostgreSQL major version upgrades** require manual data migration (dump/restore).
- Default admin credentials are set at first signup; no default password is pre-configured.

---

## References
- GitHub: https://github.com/AmruthPillai/Reactive-Resume
- Docs: https://docs.rxresu.me
- compose.yml (upstream): https://github.com/AmruthPillai/Reactive-Resume/blob/main/compose.yml
- .env.example: https://github.com/AmruthPillai/Reactive-Resume/blob/main/.env.example
