---
name: reactive-resume-project
description: Reactive Resume recipe for open-forge. MIT-licensed free + privacy-focused resume builder. Docker Compose stack with four services — the Reactive Resume Node.js app, Postgres, SeaweedFS (S3-compatible storage for resume PDFs + assets), and Browserless (headless Chromium for PDF rendering). Covers the upstream compose.yml, env var shape, AUTH_SECRET generation, the Browserless token + chromedp/headless-shell alternative, and the common "PDF blank" gotcha caused by PRINTER_APP_URL misconfiguration.
---

# Reactive Resume

MIT-licensed free + open-source resume builder. Upstream: <https://github.com/AmruthPillai/Reactive-Resume>. Hosted: <https://rxresu.me>. Docs: <https://docs.rxresu.me>.

Self-host lets you own your resume data (useful for enterprises / privacy-conscious users) and control branding. Uses a multi-service architecture to keep the web app stateless while PDF rendering, storage, and DB are separate concerns.

## Architecture (from upstream `compose.yml`)

| Service | Image | Purpose |
|---|---|---|
| `reactive_resume` | `amruthpillai/reactive-resume:latest` (or `ghcr.io/amruthpillai/reactive-resume:latest`) | Main Node.js app — web UI + API. Listens on `:3000`. |
| `postgres` | `postgres:latest` | User accounts, resume data, versions. |
| `browserless` | `ghcr.io/browserless/chromium:latest` | Headless Chromium exposed via WebSocket; renders PDFs on demand. (Alternative: `chromedp/headless-shell:latest`.) |
| `seaweedfs` | `chrislusf/seaweedfs:latest` | S3-compatible object store for uploaded images + generated PDFs. |
| `seaweedfs_create_bucket` | `quay.io/minio/mc:latest` | One-shot init job that creates the `reactive-resume` bucket in SeaweedFS. |

All services run on three internal Compose networks (`data_network`, `printer_network`, `storage_network`) so traffic stays private.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (`compose.yml` on `main`) | <https://github.com/AmruthPillai/Reactive-Resume/blob/main/compose.yml> | ✅ Recommended | The canonical self-host path. |
| `docker run` standalone (app only) | `amruthpillai/reactive-resume` on Docker Hub | ✅ (image only) | Only useful if you BYO Postgres + Browserless + S3. Rarely worth it. |
| Build from source | Nx monorepo, pnpm | ✅ | Dev. Needs Node 20+, pnpm, Postgres. |
| Deploy to PaaS (Railway/Fly/etc.) | Community templates | ⚠️ Community | Same image + managed Postgres + managed Chromium. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `compose (recommended)` / `source` | Drives section. |
| secrets | "AUTH_SECRET (≥32 random chars)?" | Free-text, default generated via `openssl rand -base64 64` | MANDATORY — used to sign JWTs. Change = all existing users logged out. |
| secrets | "Browserless token?" | Free-text, default `change-me` | Shared secret between the app and the Chromium service. Upstream default is `change-me` — ALWAYS override. |
| secrets | "SeaweedFS S3 credentials?" | Free-text, defaults `seaweedfs/seaweedfs` | Internal-network-only creds; fine to leave default on single-host but override if exposing SeaweedFS elsewhere. |
| dns | "Public domain (APP_URL)?" | Free-text, default `http://localhost:3000` | Set both `APP_URL` and `PRINTER_APP_URL` — see gotcha below. |
| auth | "Email/password auth, OAuth, or both?" | `AskUserQuestion`: `Email+password` / `OAuth (Google/GitHub)` / `both` | OAuth requires provider client ID + secret env vars. Email+password works out of the box. |
| smtp | "Outbound email provider?" | `AskUserQuestion`: `Skip` / `Resend` / `SendGrid` / `Postmark` / `SMTP (generic)` | Required for password reset + email verification if those features are enabled. |
| storage | "Printer path — Browserless (default) or chromedp/headless-shell?" | `AskUserQuestion` | Browserless is upstream default. headless-shell is lighter and works via plain HTTP; compose commented example provided. |

## Install — Docker Compose (recommended)

```bash
# 1. Clone (or just grab compose.yml + any referenced files)
git clone https://github.com/AmruthPillai/Reactive-Resume.git
cd Reactive-Resume

# 2. Generate secrets
AUTH_SECRET=$(openssl rand -base64 64 | tr -d '\n')
BROWSERLESS_TOKEN=$(openssl rand -hex 32)

# 3. Create .env
cat > .env <<EOF
# Core
AUTH_SECRET=${AUTH_SECRET}
BROWSERLESS_TOKEN=${BROWSERLESS_TOKEN}

# Public URLs
APP_URL=https://resume.example.com
PRINTER_APP_URL=http://reactive_resume:3000

# Postgres (inside Compose network — app uses these by default)
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=postgres

# SeaweedFS / S3
S3_ACCESS_KEY_ID=seaweedfs
S3_SECRET_ACCESS_KEY=seaweedfs
S3_ENDPOINT=http://seaweedfs:8333
S3_BUCKET=reactive-resume
S3_FORCE_PATH_STYLE=true

# Optional — OAuth
# GITHUB_CLIENT_ID=...
# GITHUB_CLIENT_SECRET=...
# GOOGLE_CLIENT_ID=...
# GOOGLE_CLIENT_SECRET=...

# Optional — SMTP
# MAIL_FROM=noreply@example.com
# SMTP_URL=smtp://user:pass@smtp.example.com:587
EOF

# 4. Bring up
docker compose up -d
docker compose logs -f reactive_resume
```

First-run: open `APP_URL` → **Sign up** → create an admin account. The first-registered user is a normal user; there's no built-in "admin" concept, but the first user typically claims a friendly username.

### The upstream compose (truncated to key shape)

```yaml
services:
  postgres:
    image: postgres:latest
    volumes: [ postgres_data:/var/lib/postgresql ]
    environment:
      POSTGRES_DB: postgres
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres

  browserless:
    image: ${BROWSERLESS_IMAGE:-ghcr.io/browserless/chromium:latest}
    environment:
      QUEUED: 10
      HEALTH: true
      CONCURRENT: 5
      TOKEN: ${BROWSERLESS_TOKEN:-change-me}

  seaweedfs:
    image: chrislusf/seaweedfs:latest
    command: server -s3 -filer -dir=/data -ip=0.0.0.0

  seaweedfs_create_bucket:
    image: quay.io/minio/mc:latest
    # ... creates the reactive-resume bucket, then exits

  reactive_resume:
    image: amruthpillai/reactive-resume:latest
    ports: [ "3000:3000" ]
    environment:
      APP_URL: http://localhost:3000
      PRINTER_APP_URL: http://host.docker.internal:3000   # or http://reactive_resume:3000 for Linux
      PRINTER_ENDPOINT: ws://browserless:3000?token=${BROWSERLESS_TOKEN:-change-me}
      DATABASE_URL: postgresql://postgres:postgres@postgres:5432/postgres
      AUTH_SECRET: change-me-to-a-secure-secret-key-in-production
      S3_ENDPOINT: http://seaweedfs:8333
      S3_BUCKET: reactive-resume
      S3_FORCE_PATH_STYLE: "true"
```

## Reverse proxy (Caddy example)

```caddy
resume.example.com {
    reverse_proxy reactive_resume:3000
}
```

Don't forget to set `APP_URL=https://resume.example.com` in `.env` and restart.

## Alternative printer — `chromedp/headless-shell`

Upstream's compose includes a commented-out alternative. If Browserless feels heavy:

```yaml
chrome:
  image: chromedp/headless-shell:latest
  restart: unless-stopped
  networks: [ printer_network ]
  ports: [ "9222:9222" ]
```

Then in the `reactive_resume` env:

```yaml
PRINTER_ENDPOINT: http://chrome:9222
# Remove the Browserless token since headless-shell doesn't require one.
```

Result: smaller image, simpler auth, slightly different feature set. See <https://docs.rxresu.me/self-hosting/docker#alternative-printer-options>.

## Data layout

Three named volumes:

| Volume | Content |
|---|---|
| `postgres_data` | User accounts, resume JSON, versions. |
| `seaweedfs_data` | Uploaded images (avatars, photos), generated PDFs. |
| `reactive_resume_data` | Mounted at `/app/data` — mostly cache; rebuilt on boot. |

**Backup = pg_dump + tar seaweedfs_data** while the stack is stopped:

```bash
docker compose stop
docker run --rm -v reactive-resume_postgres_data:/source -v $(pwd):/backup alpine \
  tar czf /backup/postgres-$(date +%F).tar.gz /source
docker run --rm -v reactive-resume_seaweedfs_data:/source -v $(pwd):/backup alpine \
  tar czf /backup/seaweedfs-$(date +%F).tar.gz /source
docker compose start
```

## Upgrade procedure

```bash
# 1. Back up DB + SeaweedFS (see above).
# 2. Pull new images + up
docker compose pull
docker compose up -d
docker compose logs -f reactive_resume
```

Prisma migrations run automatically on `reactive_resume` startup. If migrations fail, the container restarts in a loop — check logs and match the new version's release notes.

## Gotchas

- **PDF renders blank / "Cannot connect to host.docker.internal"** — this is the #1 self-host issue. `PRINTER_APP_URL` must be reachable FROM the Browserless container. On Linux, `host.docker.internal` doesn't resolve inside Compose by default; change `PRINTER_APP_URL=http://reactive_resume:3000` (the internal service name). The Compose file has `extra_hosts: host.docker.internal:host-gateway` to mitigate, but it only works on recent Docker. When in doubt, use the service name.
- **AUTH_SECRET in .env must be set BEFORE first user signs up.** Changing it later logs everyone out (JWTs invalidated). Generate once, store in a password manager.
- **`BROWSERLESS_TOKEN` default is `change-me`.** If you leave it, anyone reaching `http://host:3001/` (if exposed) can drive your Chromium to fetch arbitrary URLs. Always override.
- **SeaweedFS needs init + mc create-bucket to run before first resume export.** The `seaweedfs_create_bucket` one-shot service handles this, but if it fails (Compose network not ready), the bucket won't exist → PDF uploads 500. Check `docker compose logs seaweedfs_create_bucket`.
- **APP_URL vs PRINTER_APP_URL is a chicken-and-egg.** APP_URL is what users type in their browser (public). PRINTER_APP_URL is what Browserless uses internally to load the resume for printing. They should NOT be the same URL unless you explicitly want Browserless making external HTTPS requests back to your public hostname. Use the internal service name for PRINTER_APP_URL.
- **Email sign-up requires SMTP if `disableSignups=false` and email verification is on.** Without SMTP config, signup "succeeds" but verification links never arrive. Either configure SMTP or set `DISABLE_SIGNUPS=true` + create users manually via the DB.
- **OAuth provider callback URLs must match APP_URL.** `<APP_URL>/api/auth/callback/github` etc. Mismatch → OAuth redirect loop.
- **Postgres `postgres:latest` has no volume for config.** Fine for self-host; minor for prod-hardening (pin a specific version, e.g. `postgres:16`).
- **SeaweedFS unauthenticated S3 on port 8333.** Exposed only on the `storage_network` by default — fine. If you map it to host, enable real auth first.
- **RAM footprint is ~2 GB idle.** Chromium (Browserless) is the majority; Postgres + Node are small. Low-end VPS should pick a plan with ≥2 GB RAM.
- **MIT license applies to the code**, but the templates shipped with the app may have their own licenses — check `LICENSE` and `apps/client/public/templates/` before redistributing.
- **Version tag drift.** `amruthpillai/reactive-resume:latest` pulls the current main build. For production, pin a specific version from <https://github.com/AmruthPillai/Reactive-Resume/releases>.

## Links

- Upstream repo: <https://github.com/AmruthPillai/Reactive-Resume>
- Docs: <https://docs.rxresu.me>
- Self-hosting guide: <https://docs.rxresu.me/self-hosting>
- Docker self-host guide: <https://docs.rxresu.me/self-hosting/docker>
- Environment variables: <https://docs.rxresu.me/self-hosting/environment-variables>
- Compose file: <https://github.com/AmruthPillai/Reactive-Resume/blob/main/compose.yml>
- Releases: <https://github.com/AmruthPillai/Reactive-Resume/releases>
- Docker image: <https://hub.docker.com/r/amruthpillai/reactive-resume>
