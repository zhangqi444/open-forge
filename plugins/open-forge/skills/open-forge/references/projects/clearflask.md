---
name: clearflask
description: ClearFlask recipe for open-forge. Open-source feedback management and public roadmap tool — alternative to Canny/UserVoice. Docker Compose deployment. Upstream: https://github.com/clearflask/clearflask
---

# ClearFlask

Open-source customer feedback management and public roadmap tool. Collect product ideas, bug reports, and questions from users; prioritise them on a public (or private) roadmap; close the feedback loop by notifying users when their request ships. Alternative to Canny, UserVoice, and Upvoty. Upstream: <https://github.com/clearflask/clearflask> — AGPL-3.0.

ClearFlask is a Java/Spring backend + React frontend backed by Elasticsearch and DynamoDB (local in self-hosted mode).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://github.com/clearflask/clearflask/blob/master/clearflask-server/src/main/docker/deploy-local/docker-compose.yml> | Yes | Recommended. Single-server self-hosted deployment. |
| ClearFlask Cloud | <https://clearflask.com> | Yes (managed) | Out of scope for open-forge — managed SaaS. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| domain | Public hostname (e.g. feedback.example.com) | Free-text | All — used in auth callbacks and email links |
| smtp | SMTP host, port, user, password, from address | Free-text | Required — user sign-up and notification emails |
| admin | Super admin email address | Free-text | First-run setup |
| auth | Domain to use for magic-link auth emails | Free-text | Typically same as public hostname domain |

## Docker Compose method

Upstream Compose file: <https://github.com/clearflask/clearflask/blob/master/clearflask-server/src/main/docker/deploy-local/docker-compose.yml>

```yaml
version: "3.8"

services:
  clearflask:
    image: clearflask/clearflask-server:latest
    container_name: clearflask
    restart: unless-stopped
    ports:
      - "443:443"
      - "80:80"
    environment:
      # Public URL
      - CLEARFLASK_HOST=feedback.example.com
      # Super admin email
      - CLEARFLASK_SUPERADMIN_EMAIL=admin@example.com
      # SMTP
      - SMTP_HOST=smtp.example.com
      - SMTP_PORT=587
      - SMTP_USERNAME=smtp-user
      - SMTP_PASSWORD=smtp-password
      - SMTP_FROM_EMAIL=noreply@example.com
      # Optional: SSL via built-in Let's Encrypt
      - SSL_LETSENCRYPT_EMAIL=admin@example.com
    volumes:
      - clearflask_data:/opt/clearflask/data

volumes:
  clearflask_data:
```

The container bundles Elasticsearch, DynamoDB-local, and a reverse proxy — no separate database container needed for a single-server deployment.

Navigate to `https://feedback.example.com` after startup and sign in with the super admin email (magic link sent to email).

## Architecture (self-hosted)

The self-hosted Docker image bundles:
- **ClearFlask backend** (Java/Spring Boot)
- **ClearFlask frontend** (React, served via Nginx)
- **Elasticsearch** (search and data storage)
- **DynamoDB-local** (metadata storage)
- **Internal reverse proxy** (routes traffic, handles TLS)

This keeps the deployment simple (one container) at the cost of flexibility for scaling.

## Key features

- **Feedback portals** — public or private; branded with your logo and colours
- **Roadmap** — prioritise and publish planned/in-progress/shipped items
- **Voting** — users upvote existing ideas instead of duplicating requests
- **Status updates** — notify all voters when a request is shipped/rejected
- **Multiple projects** — manage several products from one ClearFlask instance
- **SSO** — OAuth2 (Google, GitHub) and SAML integration
- **API** — REST API for custom integrations

## Upgrade procedure

```bash
docker compose pull clearflask
docker compose up -d clearflask
```

Data migrations are applied automatically on startup.

## Gotchas

- **SMTP is required.** ClearFlask uses magic-link (email) authentication for all users, including admins. Without working SMTP, nobody can log in.
- **CLEARFLASK_HOST must be correct.** Authentication tokens and email links embed this hostname. Setting it to localhost or an IP will break external access.
- **Port 443 by default.** The container binds to 443 directly. If you already have a reverse proxy on the host, either change the port mapping or configure ClearFlask to run on a non-standard port and terminate TLS at the proxy.
- **Bundled Elasticsearch.** The self-hosted image runs Elasticsearch inside the same container. For large deployments (thousands of feedback items, many users), consider a separate Elasticsearch cluster.
- **AGPL-3.0 licence.** If you modify and distribute the source, you must release modifications under AGPL-3.0.
- **First login.** After deploying, the first admin login is via magic link to the `CLEARFLASK_SUPERADMIN_EMAIL` address. Check spam if the email doesn't arrive.

## Upstream docs

- GitHub: <https://github.com/clearflask/clearflask>
- Self-hosted setup guide: <https://github.com/clearflask/clearflask/tree/master/clearflask-server/src/main/docker/deploy-local>
- Docker Hub: <https://hub.docker.com/r/clearflask/clearflask-server>
- Demo: <https://product.clearflask.com>
