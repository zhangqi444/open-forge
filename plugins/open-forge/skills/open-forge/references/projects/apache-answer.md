---
name: Apache Answer
description: Open-source Q&A platform for teams and communities (Stack Overflow-style). Go backend + React frontend. Single-binary, embedded SQLite by default; also supports MySQL/Postgres. Apache 2.0.
---

# Apache Answer

Answer is a self-hosted Stack Overflow: users post questions with tags, others write answers, votes rank content, best answers bubble up. Used for internal team knowledge bases, public community forums, and product support portals. Originally built by SegmentFault; now an Apache Incubator / Top-Level project.

- Upstream repo: <https://github.com/apache/answer>
- Website: <https://answer.apache.org>
- Docs: <https://answer.apache.org/docs>
- Installation: <https://answer.apache.org/docs/installation>
- Image: `apache/answer` on Docker Hub (multi-arch)

## Compatible install methods

| Infra          | Runtime                         | Notes                                                            |
| -------------- | ------------------------------- | ---------------------------------------------------------------- |
| Single VM      | Docker single container         | **Recommended.** Upstream compose is 12 lines, single service     |
| Single VM      | Docker with external MySQL/Postgres | Scales to larger deployments                                   |
| Bare metal     | Static Go binary               | Released on GitHub; run behind nginx/systemd                      |
| Kubernetes     | Plain manifests                 | Stateless-app + DB pattern; no official Helm chart yet            |

## Inputs to collect

| Input              | Example                              | Phase     | Notes                                                              |
| ------------------ | ------------------------------------ | --------- | ------------------------------------------------------------------ |
| Port               | `9080:80`                            | Network   | Behind reverse proxy for TLS                                       |
| Data volume        | `answer-data:/data`                  | Data      | **Critical** — holds config, SQLite DB, uploads                     |
| Admin credentials  | created via installer                | Bootstrap | First-run wizard prompts                                           |
| DB choice          | SQLite (default) / MySQL 5.7+ / Postgres 12+ | Bootstrap | SQLite fine up to ~10k users; pick MySQL/Postgres for larger    |
| Site URL           | `https://answer.example.com`         | Runtime   | Set via admin UI; used for email links                             |
| SMTP               | any provider                         | Runtime   | For email notifications (new answers, mentions)                    |
| Version            | `2.0.0` (as of 2024)                 | Runtime   | Pin explicitly; avoid `:latest`                                    |

## Install via Docker Compose

Upstream `docker-compose.yaml`:

```yaml
services:
  answer:
    image: apache/answer:2.0.0        # pin; check GitHub releases for latest
    restart: unless-stopped
    ports:
      - "9080:80"
    volumes:
      - answer-data:/data

volumes:
  answer-data:
```

Or just `docker run`:

```sh
docker run -d -p 9080:80 -v answer-data:/data --name answer apache/answer:2.0.0
```

Browse `http://<host>:9080`. The web installer walks through:

1. Language selection
2. Database (SQLite / MySQL / Postgres — with connection details)
3. Site settings (name, site URL, contact email)
4. Admin account (name + email + password)

After completion, the installer writes config to `/data/conf/config.yaml` inside the volume. Subsequent boots skip the wizard.

### With external MySQL

```yaml
services:
  answer:
    image: apache/answer:2.0.0
    restart: unless-stopped
    ports:
      - "9080:80"
    volumes:
      - answer-data:/data
    depends_on:
      mysql:
        condition: service_healthy

  mysql:
    image: mysql:8.0
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: REPLACE_ME
      MYSQL_DATABASE: answer
      MYSQL_USER: answer
      MYSQL_PASSWORD: REPLACE_ME
    volumes:
      - mysql_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      retries: 5

volumes:
  answer-data:
  mysql_data:
```

At install time, choose MySQL, point at `mysql:3306`, DB `answer`, user `answer`, password as set above.

## Data & config layout

Inside the `answer-data` volume:

- `/data/conf/config.yaml` — main config (DB connection, SMTP, server settings)
- `/data/answer.db` — SQLite database (if using default)
- `/data/uploads/` — user avatars, question attachments
- `/data/i18n/` — localization files (extendable)
- `/data/plugins/` — installed plugins

## Plugins

Answer has a Go plugin system — custom auth providers (SSO), additional notification channels (Slack, Discord), custom rankings. See <https://answer.apache.org/community/plugins> for available plugins and <https://answer.apache.org/plugins> for the plugin registry.

To install: download plugin binary → drop in `/data/plugins/` → enable in admin UI.

## Backup

```sh
# Entire volume — includes DB + config + uploads
docker run --rm -v answer-data:/src -v "$PWD":/backup alpine \
  tar czf /backup/answer-$(date +%F).tgz -C /src .

# If using external MySQL:
docker compose exec -T mysql mysqldump -u root -p"$PASS" answer | gzip > answer-mysql-$(date +%F).sql.gz
```

SQLite backup of an actively-written DB can be inconsistent — for busy instances, use `sqlite3 answer.db ".backup /tmp/answer.db"` via `docker exec` before tarring.

## Upgrade

1. Releases: <https://github.com/apache/answer/releases>. Major versions (1.x → 2.x) may include schema migrations.
2. Bump image tag, `docker compose pull && docker compose up -d`.
3. Migrations run automatically on startup. Check container logs.
4. Upgrade docs: <https://answer.apache.org/docs/upgrade>.
5. Before major jumps, tar the `answer-data` volume.

## Gotchas

- **SQLite is the default but not production-safe for HA.** Works fine for single-node + modest traffic. For multi-instance or heavy-write workloads, pick MySQL or Postgres at install time (you cannot migrate between DBs from the admin UI — requires manual data export/import).
- **Installation is a web wizard, not env-variable driven.** First boot on port :9080 shows a setup page. Until you complete it, the app isn't usable. Automated infrastructure-as-code setups need to script the wizard or use the CLI `answer init`.
- **`:latest` tag exists but isn't recommended.** Pin to specific version tags — Answer has shipped schema-breaking changes across minor versions.
- **No built-in TLS.** Run behind Caddy/Traefik/nginx. Set "Site URL" in admin → General with `https://`.
- **`/data/conf/config.yaml` contains DB creds in plaintext.** Protect the volume accordingly; back up separately from application backups and encrypt.
- **Email notifications require SMTP configured post-install** (not at Docker level). Go to admin → SMTP, save config, test. Without SMTP: no account-verification emails, no mentions.
- **Upload limits** are controlled in admin UI. Default 2 MB can be too small for screenshots. Adjust before users complain.
- **Anti-spam is minimal out of the box.** reCAPTCHA is an admin-UI toggle (requires Google reCAPTCHA key). For a public-facing site, enable before launch or expect spam signups within hours.
- **Rate limits exist but default to lenient.** Adjust in admin → privileges + reputation config.
- **Permissions system is reputation-based (SO-style).** New users have limited abilities; privileges unlock as they earn reputation through upvotes. Admin-tune the thresholds for small-community deployments (default thresholds are calibrated for Stack Overflow-sized traffic).
- **Search uses the DB's full-text capabilities** (SQLite FTS / MySQL FULLTEXT / Postgres tsvector). Performance acceptable to ~100k questions; larger installs should integrate Meilisearch plugin.
- **Multi-language support is solid** — 20+ languages shipped. Per-user locale selection in profile settings. Useful for international teams.
- **Default port in container is :80.** If you change host-side mapping, make sure the reverse proxy matches.
- **Single-container simplicity is a trade-off** — no separate web/worker split. Long-running admin tasks (bulk user imports, search index rebuilds) occupy request-serving goroutines.
- **Apache license means commercial use is fine**, including as a closed-source company internal tool. Upstream is project of the Apache Software Foundation since 2024 — strong governance guarantees.

## Links

- Repo: <https://github.com/apache/answer>
- Site: <https://answer.apache.org>
- Docs index: <https://answer.apache.org/docs>
- Installation: <https://answer.apache.org/docs/installation>
- Upgrade: <https://answer.apache.org/docs/upgrade>
- Plugins directory: <https://answer.apache.org/plugins>
- Plugin development: <https://answer.apache.org/community/plugins>
- Releases: <https://github.com/apache/answer/releases>
- Docker Hub: <https://hub.docker.com/r/apache/answer>
- Discord: <https://discord.gg/Jm7Y4cbUej>
