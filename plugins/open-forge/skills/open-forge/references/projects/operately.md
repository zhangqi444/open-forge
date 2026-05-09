---
name: operately
description: Operately recipe for open-forge. Open-source company operating system for managing goals (OKRs), projects, and teams. Apache 2.0. Self-host via Docker Compose using the official single-host installer. Upstream: https://github.com/operately/operately
---

# Operately

Open-source company operating system for aligning goals, managing projects, and coordinating teams. Apache 2.0. Upstream: <https://github.com/operately/operately>. Install guide: <https://operately.com/install>.

Operately is an opinionated work management platform — not a generic project tool. It ships with built-in OKR/goal tracking, project check-ins, team spaces, message boards, and an execution cadence system. It also exposes a CLI and REST API, and has published skills for Claude Code and OpenClaw.

## Compatible install methods

| Method | Upstream source | When to use |
|---|---|---|
| Single-host Docker Compose (via `install.sh`) | <https://github.com/operately/operately/blob/main/docs/installation/single-host.md> | Recommended production. Handles SSL (Let's Encrypt), domain config, and email setup interactively. |
| Development Docker Compose | <https://github.com/operately/operately/blob/main/docker-compose.yml> | Local dev only — uses `operately-dev` image, not for production. |

## Requirements

- Docker + Docker Compose
- Public domain pointed to the server (A/AAAA record, no proxy)
- 2 GB RAM minimum (8 GB recommended for teams >30)
- Outbound SMTP (optional but recommended for invites/notifications)

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "What domain will Operately run on?" (e.g. `operately.example.com`) | Required — used in Let's Encrypt cert and app config. |
| email | "Which email delivery method?" `SendGrid` / `SMTP (host/port/user/pass)` / `Skip for now` | SendGrid: needs API key. SMTP: needs host, port, username, password. |
| email | "From address?" | Must be on a verified sending domain. |

## Method — Single-host Docker Compose

> **Source:** <https://github.com/operately/operately/blob/main/docs/installation/single-host.md>

### 1 — Download release bundle

```bash
wget -q https://github.com/operately/operately/releases/latest/download/operately-single-host.tar.gz
tar -xf operately-single-host.tar.gz
cd operately
```

As of 2026-05-09, the latest release is `1.5.0`.

### 2 — Run the interactive installer

```bash
./install.sh
```

The script prompts for:
- **Domain** — the FQDN where Operately will be served (e.g. `work.example.com`).
- **Email delivery** — SendGrid API key, SMTP credentials, or defer.
- **SSL** — whether to auto-manage certificates via Let's Encrypt (recommended; requires port 80 open for ACME challenge).

The installer writes a `.env` file and configures `docker-compose.yml`.

### 3 — Start the stack

```bash
docker compose up --wait --detach
```

Operately starts on the configured domain (HTTPS if SSL was enabled). Initial setup wizard runs on first visit.

### 4 — Verify

Open `https://<your-domain>` in a browser. The setup wizard creates the first admin user and workspace.

### Updating

```bash
cd operately
docker compose pull
docker compose up --wait --detach
```

Check the [upgrade guide](https://github.com/operately/operately/blob/main/docs/installation/upgrade.md) for migration notes between major versions.

## Reverse proxy notes

The single-host installer configures Caddy (embedded) for SSL termination. If you run your own NGINX or Traefik in front, disable the built-in SSL and proxy to the internal port. See `docker-compose.yml` port mappings in the release tarball.

## Email configuration

Operately uses email for invites, notifications, and password resets.

### SendGrid

Set in `.env`:
```
MAILER_PROVIDER=sendgrid
SENDGRID_API_KEY=SG.xxx
MAIL_FROM=notifications@example.com
```

### SMTP (generic)

```
MAILER_PROVIDER=smtp
SMTP_HOST=mail.example.com
SMTP_PORT=587
SMTP_USERNAME=user@example.com
SMTP_PASSWORD=secret
SMTP_SSL=false
MAIL_FROM=notifications@example.com
```

For AWS SES: set `SMTP_PROVIDER=aws-ses` in addition to standard SMTP vars.

## CLI access

Operately ships a CLI for scripting and AI agent integration:

```bash
# Install
npm install -g @operately/cli

# Authenticate
operately login --url https://operately.example.com

# Create a goal
operately goals create --name "Q3 growth" --space engineering
```

Full CLI docs: <https://operately.com/help/cli>

## Ports

| Port | Service |
|---|---|
| 80 | HTTP (ACME challenge + redirect to HTTPS) |
| 443 | HTTPS (Caddy / your reverse proxy) |

## License

Apache 2.0 — <https://github.com/operately/operately/blob/main/LICENSE>
