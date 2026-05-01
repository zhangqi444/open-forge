---
name: Docassemble
description: "Self-hosted guided interview and document automation platform for legal, government, and form-based workflows. Docker. Python/Flask. jhpyle/docassemble. Build question-and-answer interviews that generate documents, route logic, send emails, integrate databases. AGPL-3.0."
---

# Docassemble

**Self-hosted document automation and guided interview platform.** Build expert-system-style question-and-answer interviews that produce documents, make decisions, send emails, and integrate with external services. Widely used by law firms, legal aid organisations, and government agencies to automate form completion, generate contracts, and guide users through complex workflows without technical expertise.

Built + maintained by **jhpyle** (Jonathan Pyle). AGPL-3.0.

- Upstream repo: <https://github.com/jhpyle/docassemble>
- Docker Hub: `jhpyle/docassemble`
- Website: <https://docassemble.org>
- Docs: <https://docassemble.org/docs/>

## Architecture in one minute

- **Python/Flask** — web + background workers
- **PostgreSQL** — interview sessions and user data
- **Redis** — task queue and caching
- **RabbitMQ** — message broker for background tasks
- **Supervisord** — manages internal processes
- Single Docker container bundles all services (all-in-one)
- Port **80** (HTTP) or **443** (HTTPS with Let's Encrypt)
- Resource: **medium-high** — Python + Postgres + Redis + RabbitMQ; ~1–2 GB RAM recommended

## Compatible install methods

| Infra      | Runtime              | Notes                                                   |
| ---------- | -------------------- | ------------------------------------------------------- |
| **Docker** | `jhpyle/docassemble` | **Primary** — all-in-one container (Postgres inside)    |
| Multi-container | Docker Compose  | External Postgres/Redis for production scale            |

## Install via Docker (simple)

```bash
docker run -d \
  --name docassemble \
  --restart unless-stopped \
  -p 80:80 \
  -e DAHOSTNAME=docassemble.example.com \
  -e TIMEZONE=America/New_York \
  -v docassemble-data:/usr/share/docassemble \
  jhpyle/docassemble
```

## Install via Docker Compose (production)

```yaml
services:
  docassemble:
    image: jhpyle/docassemble:latest
    container_name: docassemble
    restart: unless-stopped
    environment:
      - DAHOSTNAME=docassemble.example.com    # your public hostname
      - TIMEZONE=America/New_York
      - DBHOST=db
      - DBNAME=docassemble
      - DBUSER=docassemble
      - DBPASSWORD=changeme
      - USEHTTPS=false                        # set true + LETSENCRYPTEMAIL for TLS
      - USELETSENCRYPT=false
      - LETSENCRYPTEMAIL=admin@example.com
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - docassemble-data:/usr/share/docassemble
    depends_on:
      - db

  db:
    image: postgres:16
    restart: unless-stopped
    environment:
      - POSTGRES_USER=docassemble
      - POSTGRES_PASSWORD=changeme
      - POSTGRES_DB=docassemble
    volumes:
      - docassemble-db:/var/lib/postgresql/data

volumes:
  docassemble-data:
  docassemble-db:
```

```bash
docker compose up -d
```

Visit `http://docassemble.example.com` (or `http://localhost` for local testing).

## Environment variables

| Variable | Default | Notes |
|----------|---------|-------|
| `DAHOSTNAME` | `docassemble.example.com` | Your public hostname — used in links and TLS cert |
| `TIMEZONE` | `America/New_York` | Timezone |
| `DBNAME` | `docassemble` | PostgreSQL database name |
| `DBUSER` | `docassemble` | PostgreSQL user |
| `DBPASSWORD` | `abc123` | PostgreSQL password — **change this** |
| `DBHOST` | `localhost` | PostgreSQL host (set to service name for external DB) |
| `USEHTTPS` | `false` | Set `true` to enable HTTPS |
| `USELETSENCRYPT` | `false` | Set `true` to auto-provision Let's Encrypt certificate |
| `LETSENCRYPTEMAIL` | _(empty)_ | Email for Let's Encrypt registration |
| `S3ENABLE` | `false` | Enable AWS S3 for file storage |
| `S3ACCESSKEY` | _(empty)_ | AWS access key |
| `S3SECRETACCESSKEY` | _(empty)_ | AWS secret key |
| `S3BUCKET` | _(empty)_ | S3 bucket name |
| `EC2` | `false` | Set `true` when running on EC2 (uses instance metadata) |

## Features overview

| Feature | Details |
|---------|---------|
| Guided interviews | Build YAML-defined question flows with conditional logic |
| Document generation | Generate DOCX, PDF, and RTF documents from templates |
| Legal workflows | Widely used for legal aid, court forms, and contracts |
| Multi-user | User accounts with role-based access |
| Background tasks | Long-running tasks via RabbitMQ/Redis |
| Email integration | Send documents via email from interviews |
| API | REST API for embedding interviews in other apps |
| Webhook support | Integrate with external services |
| HTTPS / Let's Encrypt | Built-in TLS with automatic certificate provisioning |
| S3 storage | Optional AWS S3 for file storage at scale |
| Python extensibility | Full Python code inside interviews for complex logic |
| Slack/Telegram integration | Notify via messaging platforms |
| Data persistence | PostgreSQL for sessions; survives container restarts |

## First run

1. Visit `http://localhost` (or your `DAHOSTNAME`)
2. Log in with default credentials: `admin` / `password`
3. **Immediately change the admin password** in the user menu
4. Go to **Playground** → create your first interview in YAML
5. See the [Hello World interview](https://docassemble.org/docs/helloworld.html) in the docs

## Interview YAML example

```yaml
question: What is your name?
fields:
  - Your name: user_name
---
question: Hello, ${ user_name }!
event: final_screen
buttons:
  - Exit: exit
```

## Gotchas

- **`DBPASSWORD` default is `abc123`.** Change it in production before the first run.
- **All-in-one container embeds Postgres.** The simple Docker run includes an internal PostgreSQL. Use an external DB (`DBHOST=db`) for production so data survives container replacements.
- **`DAHOSTNAME` is important.** Set this to your real hostname — it appears in generated document links, emails, and is required for Let's Encrypt.
- **Let's Encrypt requires public port 80/443.** For TLS, your hostname must be publicly reachable. Don't use `USELETSENCRYPT=true` on a local/non-public host.
- **Heavy image.** The container is large (Python, LibreOffice, LaTeX, Chrome, Postgres, Redis, RabbitMQ). Initial pull takes time. RAM requirement is 1–2 GB.
- **AGPL-3.0 license.** Network-service usage of modified Docassemble requires publishing changes under AGPL-3.0.

## Backup

```sh
docker compose exec db pg_dump -U docassemble docassemble > docassemble-$(date +%F).sql
docker run --rm -v docassemble-data:/data -v $(pwd):/backup alpine \
  tar czf /backup/docassemble-data-$(date +%F).tar.gz /data
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Python/Flask development, widely adopted in legal aid sector, AGPL-3.0.

## Document-automation-family comparison

- **Docassemble** — Python/Flask, YAML-based guided interviews, document generation, legal focus, AGPL-3.0
- **HotDocs** — Commercial document automation; Windows-based
- **OpenDocMan** — PHP, document management/DMS (different use case)
- **DocuSeal** — Go, digital form-signing and PDF templates; AGPL-3.0

**Choose Docassemble if:** you need a self-hosted platform for building guided question-and-answer interviews that generate legal documents, court forms, or complex multi-step decision workflows — especially for legal aid, government, or compliance use cases.

## Links

- Repo: <https://github.com/jhpyle/docassemble>
- Docs: <https://docassemble.org/docs/>
- Docker Hub: <https://hub.docker.com/r/jhpyle/docassemble>
- Hello World: <https://docassemble.org/docs/helloworld.html>
