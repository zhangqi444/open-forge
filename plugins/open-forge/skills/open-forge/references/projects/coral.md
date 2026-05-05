---
name: coral
description: Coral (coralproject/talk) recipe for open-forge. Covers Docker-based deployment of this open-source commenting platform for publishers. Node.js + MongoDB stack. GitHub: coralproject/talk.
---

# Coral

Open-source commenting platform for online publishers. Rethinks moderation, comment display, and community conversations. Built by the Coral team (part of Vox Media). Upstream: <https://github.com/coralproject/talk>. Documentation: <https://docs.coralproject.net/>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux VPS / bare metal | Docker / Docker Compose | Primary self-host path. Official Docker image: `coralproject/talk` on Docker Hub. |
| Any Linux VPS / bare metal | Node.js from source | Requires Node.js LTS + MongoDB. See upstream docs for monorepo build. |
| Cloud managed | Docker on managed VM | Works on any VM that can run Docker + reach a MongoDB instance. |

## Requirements (preflight)

- MongoDB instance (self-hosted or managed, e.g. MongoDB Atlas).
- SMTP / email provider for transactional emails (password reset, comment notifications).
- A domain name with TLS — Coral enforces HTTPS for embed scripts on publishers' pages.
- Node.js environment or Docker runtime.

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| infra | "Will you run MongoDB locally (Docker) or use a managed service (Atlas)?" | Affects `MONGODB_URI`. |
| dns | "What domain will Coral be served on?" | Used for `ROOT_URL` and embed script URLs. |
| tls | "How will TLS be terminated? (Caddy / NGINX / cloud LB)" | Coral itself listens on HTTP; TLS must be terminated upstream. |
| email | "SMTP host, port, user, password for transactional emails?" | Sets `EMAIL_*` env vars. |
| auth | "Which authentication integrations? (local / SSO / OAuth)" | Upstream docs cover SSO integration with existing publisher auth systems. |
| admin | "Initial admin email and password?" | Used to seed the first admin account. |

## Install (Docker)

Follow the upstream documentation at <https://docs.coralproject.net/> for current Docker Compose examples.

The Docker Hub image is `coralproject/talk`. A typical Compose stack pairs it with a MongoDB container:

```
services:
  talk:
    image: coralproject/talk:latest
    restart: always
    ports:
      - "3000:3000"
    environment:
      - MONGODB_URI=mongodb://mongo:27017/coral
      - REDIS_URI=redis://redis:6379
      - SIGNING_SECRET=<random secret>
      - ROOT_URL=https://<your-domain>
    depends_on:
      - mongo
      - redis

  mongo:
    image: mongo:4.4
    volumes:
      - mongo_data:/data/db

  redis:
    image: redis:6
    volumes:
      - redis_data:/data
```

Do NOT use these as authoritative install steps — follow the upstream documentation at <https://docs.coralproject.net/> for the current recommended configuration.

## Software-layer concerns

### Key environment variables

| Variable | Description |
|---|---|
| `MONGODB_URI` | MongoDB connection string. |
| `REDIS_URI` | Redis connection string (used for caching + job queues). |
| `SIGNING_SECRET` | Secret for signing JWT tokens. Generate with `openssl rand -hex 32`. |
| `ROOT_URL` | Canonical URL of the Coral instance (must be HTTPS in production). |
| `PORT` | HTTP port Coral listens on. Default: `3000`. |
| `EMAIL_SMTP_HOST` | SMTP server hostname. |
| `EMAIL_SMTP_PORT` | SMTP port. |
| `EMAIL_SMTP_USER` | SMTP username. |
| `EMAIL_SMTP_PASSWORD` | SMTP password. |
| `EMAIL_SMTP_SECURE` | `true` for TLS/SSL (port 465); `false` for STARTTLS (port 587). |
| `EMAIL_FROM_ADDRESS` | From address for transactional emails. |

See full environment variable reference in the Coral documentation: <https://docs.coralproject.net/>.

### Data directories

| Path | Contents |
|---|---|
| MongoDB data volume | All comments, users, settings, stories. |
| Redis data volume | Cache, job queues (can be ephemeral if acceptable). |

### Config paths

Coral is configured entirely via environment variables — no config file on disk.

## Upgrade procedure

```
# Pull the new image
docker compose pull talk

# Restart with the new image
docker compose up -d talk
```

Coral runs database migrations automatically on startup. Review the changelog at <https://github.com/coralproject/talk/releases> before upgrading major versions.

## Gotchas

- **TLS is required for embed scripts.** Publisher sites embed a JavaScript snippet that loads from Coral's `ROOT_URL`. Browsers block mixed-content (HTTP) loads on HTTPS pages, so Coral must be served over HTTPS.
- **`ROOT_URL` must match the actual URL exactly.** Mismatch between `ROOT_URL` and the actual serving domain causes CORS errors and broken embeds.
- **MongoDB version compatibility.** Verify the MongoDB version supported by the Coral release you're deploying — check the upstream release notes / Dockerfile.
- **`SIGNING_SECRET` must be persistent.** Changing it invalidates all active user sessions (everyone is logged out). Treat it like a DB password: set once, store securely, never rotate casually.
- **Redis is required, not optional.** Coral uses Redis for job queues and caching; omitting it causes startup errors.
- **SSO integration complexity.** Connecting Coral to a publisher's existing auth system requires implementing the SSO JWT flow documented at <https://docs.coralproject.net/sso/>. Plan extra time for this.

## Upstream docs

- Documentation: <https://docs.coralproject.net/>
- GitHub README: <https://github.com/coralproject/talk/blob/main/README.md>
- Docker Hub image: <https://hub.docker.com/r/coralproject/talk>
- Community guides: <https://guides.coralproject.net/start-here/>
