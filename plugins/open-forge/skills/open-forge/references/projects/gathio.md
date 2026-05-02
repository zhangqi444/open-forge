---
name: gathio-project
description: Gathio recipe for open-forge. Federated, privacy-first event hosting platform. No accounts required for attendees, ActivityPub federation, optional email notifications, configurable attendee lists, MongoDB storage. Upstream: https://github.com/lowercasename/gathio
---

# Gathio

A simple, federated, privacy-first event hosting platform. Create public or private events without requiring attendees to create accounts. Supports ActivityPub federation (events appear on Mastodon and other fediverse platforms), optional RSVP/attendee lists, and email notifications. Flagship public instance at <https://gath.io>.

Upstream: <https://github.com/lowercasename/gathio> | Docs: <https://docs.gath.io>

Two containers: a Node.js app and MongoDB.

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host | Two containers (app + MongoDB); config via TOML file |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port?" | Default: `3000` |
| config | "Your domain?" | `domain` in config.toml — e.g. `events.example.com` — required for ActivityPub federation |
| config | "Site name?" | `site_name` in config.toml |
| config | "Contact email?" | `email` in config.toml |
| config | "Enable federation (ActivityPub)?" | `is_federated = true` — on by default |
| config | "Delete old events after N days?" | `delete_after_days`; set `0` to disable auto-deletion |
| config | "Mail service?" | `mail_service`: `none`, `nodemailer` (SMTP), `sendgrid`, or `mailgun` |
| config (email) | "SMTP server/port/credentials?" | Required if `mail_service = "nodemailer"` |
| config | "Restrict event creation to email allowlist?" | `creator_email_addresses = ["admin@example.com"]` |

## Software-layer concerns

### Image

Gathio is built from source (no prebuilt image on Docker Hub). The upstream Compose uses `build: .`:

```yaml
services:
  gathio:
    build:
      context: .
      dockerfile: Dockerfile
```

This means you need the full repo to build.

```bash
git clone https://github.com/lowercasename/gathio.git
cd gathio
# Create config and compose, then build
docker compose up -d
```

### Compose

```yaml
volumes:
  mongodb_data_db:

services:
  gathio:
    container_name: gathio-app
    build:
      context: .
      dockerfile: Dockerfile
    links:
      - mongo
    environment:
      - NODE_ENV=production
    ports:
      - "3000:3000"
    volumes:
      - ./gathio-docker/config:/app/config
      - ./gathio-docker/static:/app/static
      - ./gathio-docker/images:/app/public/events

  mongo:
    image: mongo:latest
    volumes:
      - mongodb_data_db:/data/db
```

> Source: upstream docker-compose.yml — <https://github.com/lowercasename/gathio>

### config.toml

Create `./gathio-docker/config/config.toml` from the upstream example:

```bash
mkdir -p gathio-docker/config gathio-docker/static gathio-docker/images
curl -o gathio-docker/config/config.toml \
  https://raw.githubusercontent.com/lowercasename/gathio/HEAD/config/config.example.toml
# Edit gathio-docker/config/config.toml
```

Key settings:

```toml
[general]
domain = "events.example.com"    # your public domain — required for federation
port = "3000"
email = "contact@example.com"
site_name = "My Gathio"
is_federated = true
delete_after_days = 7            # 0 = never delete
mail_service = "none"            # or "nodemailer" / "sendgrid" / "mailgun"
creator_email_addresses = []     # empty = anyone can create events

[database]
mongodb_url = "mongodb://mongo:27017/gathio"

[nodemailer]
smtp_server = ""
smtp_port = ""
smtp_username = ""
smtp_password = ""

[sendgrid]
api_key = ""
```

Environment variable substitution is supported: `domain = "${GATHIO_DOMAIN}"` (only `GATHIO_`-prefixed vars).

### Features

- **No attendee accounts** — attendees RSVP with just a name/email; no registration required
- **ActivityPub / fediverse** — when `is_federated = true`, events are published as ActivityPub objects and show up on Mastodon/Mastodon-compatible servers
- **Public event list** — optionally show all public events on the front page (`show_public_event_list = true`)
- **Email notifications** — hosts and attendees get email updates via SMTP/SendGrid/Mailgun
- **Event images** — hosts can upload cover images (stored in `./gathio-docker/images`)
- **Creator allowlist** — lock event creation to specific email addresses
- **Auto-deletion** — events auto-delete N days after they end (`delete_after_days`)
- **Static pages** — customize instance description and privacy policy via `./gathio-docker/static`

### Static pages

Custom static content (instance description, privacy policy) goes in `./gathio-docker/static/`. Copy from upstream `static/` directory as a starting point.

## Upgrade procedure

```bash
cd gathio
git pull
docker compose build
docker compose up -d
```

MongoDB data persists in the `mongodb_data_db` named volume.

## Gotchas

- **No prebuilt Docker image** — Gathio must be built from source. You need the full repo (not just a compose file).
- **`domain` must be set correctly** — ActivityPub federation uses the domain to generate actor URLs. Setting `localhost` or an IP address breaks federation.
- **`mongodb_url` in config must point to the container name** — use `mongodb://mongo:27017/gathio`, not `localhost`.
- **`delete_after_days = 7` is the default** — events are deleted 7 days after they end. Set to `0` to keep events indefinitely.
- **No built-in auth** — event creation is open by default. Use `creator_email_addresses` to restrict who can create events, or front with a reverse proxy auth layer.
- **Images volume must be writable** — the `./gathio-docker/images` bind-mount needs write permissions for the container user. `chmod 755 gathio-docker/images` or equivalent.
- **No built-in HTTPS** — front with Caddy or nginx for TLS. Set `domain` to your real domain (not including port if 443).

## Links

- Upstream README: <https://github.com/lowercasename/gathio>
- Documentation: <https://docs.gath.io>
- Public instance: <https://gath.io>
- Config example: <https://github.com/lowercasename/gathio/blob/main/config/config.example.toml>
