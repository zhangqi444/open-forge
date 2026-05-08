---
name: memex
description: memEx recipe for open-forge. Structured personal knowledge base inspired by Zettelkasten and org-mode. Docker Compose, PostgreSQL, Elixir/Phoenix. AGPL-3.0. Based on upstream at https://codeberg.org/shibao/memEx.
---

# memEx

Structured personal knowledge base inspired by Zettelkasten note-taking methodology and Emacs org-mode. Organise notes, modules (structured documents), and processes (workflows/checklists) with bidirectional links. Built with Elixir/Phoenix. AGPL-3.0. Upstream: https://codeberg.org/shibao/memEx.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose | Standard; simplest setup |
| Source (Elixir/Mix) | Development or custom builds |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| database | "PostgreSQL URL?" | postgres://user:pass@host:5432/db | |
| config | "SECRET_KEY_BASE?" | Random 64+ byte hex string | Phoenix secret key; generate with `mix phx.gen.secret` or `openssl rand -hex 64` |
| config | "HOST?" | FQDN (e.g. memex.yourdomain.com) | Used for cookie domain and URLs |
| config | "Allow registration?" | Boolean (default true) | Set REGISTRATION=invite or disabled to restrict signups |
| network | "Port to expose?" | Number (default 4000) | Proxy behind nginx/Caddy for HTTPS |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Language | Elixir (Phoenix framework) |
| Database | PostgreSQL |
| Port | 4000 (default; proxy behind nginx/Caddy) |
| Registration | REGISTRATION env: public / invite / disabled |
| Email | SMTP optional (for password resets) |
| Image | registry.gitlab.com/shibao/memex (check upstream for current tag) |

## Install: Docker Compose

Source: https://codeberg.org/shibao/memEx

```yaml
services:
  db:
    image: postgres:14-alpine
    environment:
      POSTGRES_USER: memex
      POSTGRES_PASSWORD: changeme
      POSTGRES_DB: memex
    volumes:
      - db_data:/var/lib/postgresql/data
    restart: unless-stopped

  web:
    image: registry.gitlab.com/shibao/memex:latest
    ports:
      - "4000:4000"
    environment:
      DATABASE_URL: postgres://memex:changeme@db:5432/memex
      SECRET_KEY_BASE: REPLACE_WITH_LONG_RANDOM_STRING
      HOST: memex.yourdomain.com
      REGISTRATION: public  # or: invite, disabled
      # Optional email:
      # MAILER_ADDRESS: memex@yourdomain.com
      # SMTP_HOST: smtp.yourdomain.com
      # SMTP_PORT: 587
      # SMTP_USERNAME: ...
      # SMTP_PASSWORD: ...
    depends_on:
      - db
    restart: unless-stopped

volumes:
  db_data:
```

Run migrations and start:

```bash
docker compose up -d
docker compose exec web bin/memex eval "Memex.Release.migrate"
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
docker compose exec web bin/memex eval "Memex.Release.migrate"
```

## Gotchas

- Run migrations after every upgrade: Elixir/Phoenix releases require an explicit migration step — they do not auto-migrate on startup.
- SECRET_KEY_BASE must be long and random: Use `openssl rand -hex 64` or `mix phx.gen.secret`. Never reuse across environments.
- Registration control: Default registration is open (public). Set `REGISTRATION=invite` to require invite codes, or `disabled` to close registration entirely.
- HOST must match your domain: Phoenix uses HOST for cookie scoping and URL generation. Mismatches cause login and CSRF issues.
- Email is optional but useful: Without SMTP configured, password resets won't work. Configure SMTP for production deployments.
- Zettelkasten model: memEx organises knowledge into Notes (free-form), Modules (structured), and Processes (workflows). Understanding the data model before migrating existing notes saves time.

## Links

- Source: https://codeberg.org/shibao/memEx
- Upstream README: https://codeberg.org/shibao/memEx/src/branch/develop/README.md
