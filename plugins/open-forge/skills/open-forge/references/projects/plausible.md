---
name: Plausible Analytics (Community Edition)
description: Lightweight, privacy-friendly, cookie-less web analytics. Self-hostable Community Edition is AGPL, shares a codebase with the hosted SaaS.
---

# Plausible Analytics (Community Edition)

Plausible CE is the self-hosted distribution of Plausible Analytics. It is a single Elixir/Phoenix app backed by **PostgreSQL** (accounts, sites, user data) and **ClickHouse** (event warehouse). The CE repo is separate from the main app repo and packages the Docker image + sample `compose.yml`.

- Main app repo: <https://github.com/plausible/analytics>
- **Community Edition repo (use this for self-hosting):** <https://github.com/plausible/community-edition>
- Docs hub: <https://github.com/plausible/community-edition/wiki>
- Image: `ghcr.io/plausible/community-edition` (tags at <https://github.com/plausible/community-edition/pkgs/container/community-edition>)

## Compatible install methods

| Infra                | Runtime                 | Notes                                                   |
| -------------------- | ----------------------- | ------------------------------------------------------- |
| Single VM (2+ GB RAM) | Docker + Compose       | Recommended; upstream-blessed                           |
| Kubernetes           | Manual manifests / Helm | No official chart; community charts exist               |
| Bare metal (Elixir)  | Build from source       | Possible but not documented for end-users               |

## Inputs to collect

| Input                    | Example                        | Phase     | Notes                                                                          |
| ------------------------ | ------------------------------ | --------- | ------------------------------------------------------------------------------ |
| `BASE_URL`               | `https://analytics.example.com` | Runtime  | **Required.** Full origin incl. scheme; used in cookies, OAuth, email links    |
| `SECRET_KEY_BASE`        | 64+ random bytes (base64)      | Runtime   | **Required.** Session signing — rotate = all sessions invalidated              |
| `TOTP_VAULT_KEY`         | 32-byte base64 key             | Runtime   | Encrypts TOTP secrets at rest; if lost, 2FA seeds cannot be decrypted          |
| `DISABLE_REGISTRATION`   | `true`                         | Runtime   | Set after creating first user; otherwise anyone can sign up                    |
| SMTP creds               | Mailgun/Postmark/SMTP          | Runtime   | Needed for invites, password reset, reports; CE defaults to local delivery     |
| PostgreSQL               | `postgres:16-alpine` (bundled) | Data      | 16.x supported; data in Docker volume `db-data`                                |
| ClickHouse               | `clickhouse/clickhouse-server:24.12-alpine` (bundled) | Data | Pinned in upstream compose; 24.x line                                 |

## Install via Docker Compose

Clone the Community Edition repo and use its `compose.yml` verbatim; it includes required ClickHouse overlay configs under `./clickhouse/`.

```sh
git clone https://github.com/plausible/community-edition.git plausible
cd plausible

# Generate required secrets
openssl rand -base64 48   # → SECRET_KEY_BASE
openssl rand -base64 32   # → TOTP_VAULT_KEY

cat > .env <<EOF
BASE_URL=https://analytics.example.com
SECRET_KEY_BASE=<paste>
TOTP_VAULT_KEY=<paste>
# optional but recommended once first user exists:
# DISABLE_REGISTRATION=true
EOF

docker compose up -d
```

Upstream's `compose.yml` pins the image at `ghcr.io/plausible/community-edition:v3.2.0` at time of writing — track <https://github.com/plausible/community-edition/releases> for newer versions and bump the tag deliberately.

Browse `https://analytics.example.com` behind your reverse proxy; register the first account; then set `DISABLE_REGISTRATION=true` and redeploy.

### Required env vars

Full list: <https://github.com/plausible/community-edition/wiki/configuration>

- **Required:** `BASE_URL`, `SECRET_KEY_BASE`
- **Strongly recommended:** `TOTP_VAULT_KEY`, SMTP vars (`MAILER_ADAPTER`, `MAILER_EMAIL`, plus provider-specific keys), `DISABLE_REGISTRATION`
- **Optional:** Google OAuth for Search Console integration, MaxMind GeoIP license, GeoNames for city names

### ClickHouse tuning files

Upstream compose mounts four override XMLs from `./clickhouse/` — **don't delete them**:

- `logs.xml` — quiets ClickHouse logging
- `ipv4-only.xml` — binds to IPv4 only (Docker bridges don't enable IPv6)
- `low-resources.xml` — caps memory for <16 GB hosts
- `default-profile-low-resources-overrides.xml` — matching user profile

## Data & config layout

- Postgres data: named volume `db-data` → `/var/lib/postgresql/data`
- ClickHouse data: named volume `event-data` → `/var/lib/clickhouse`
- ClickHouse logs: named volume `event-logs` → `/var/log/clickhouse-server`
- Plausible runtime: named volume `plausible-data` → `/var/lib/plausible` (incl. TMPDIR, session store)
- Compose-local: `./clickhouse/*.xml` (edit only if you know what you're doing)

## Backup

- **Postgres:** `docker compose exec plausible_db pg_dump -U postgres plausible_db > pg.sql`
- **ClickHouse:** `docker compose exec plausible_events_db clickhouse-client --query "BACKUP DATABASE plausible_events_db TO Disk('backups', 'events.zip')"` — or clone the `event-data` volume while the container is stopped.
- Keep `SECRET_KEY_BASE` + `TOTP_VAULT_KEY` in your secret store. **Losing `TOTP_VAULT_KEY` means 2FA secrets are unrecoverable** — users must re-enroll.

## Upgrade

1. `git pull` in the CE repo to refresh compose + ClickHouse overlays.
2. Edit image tag in `compose.yml` (or pin via an override). Check <https://github.com/plausible/community-edition/releases> for migration notes.
3. `docker compose pull && docker compose up -d`.
4. The Plausible container runs `db createdb && db migrate && run` on start — migrations are automatic, but **take a Postgres + ClickHouse backup first** for major version bumps.

## Gotchas

- **Main `plausible/analytics` repo is NOT the self-hosting path.** Its `docker-compose.yml.example` is for development. Use `plausible/community-edition`.
- **Rename history:** the self-hosted edition used to be `hosting` under `plausible/analytics`; it moved to `plausible/community-edition` in 2024. Old tutorials pointing at `hosting/docker-compose.yml` are out of date.
- **License change:** CE is AGPL; the hosted SaaS is under a separate license. If you distribute a modified build over a network, you must offer source.
- **ClickHouse low-resources profile is mandatory on small VMs.** Without the overlay files Plausible's default ClickHouse config wants ~16 GB RAM.
- **IPv6 bind errors** ("Address family for hostname not supported") in ClickHouse logs mean the `ipv4-only.xml` overlay isn't mounted.
- **`BASE_URL` mismatch = broken site embedding.** If users embed the tracker on a site whose origin doesn't match `BASE_URL`, CORS/cookies break; update `BASE_URL` then restart.
- **No built-in backups.** You must arrange Postgres + ClickHouse snapshots yourself.
- **Clock drift kills TOTP.** Keep the host NTP-synced.
- **No self-service password reset without SMTP.** The `MAILER_ADAPTER=local_adapter` default drops mail — configure Postmark/Mailgun/SMTP for any real deployment.

## Links

- CE repo: <https://github.com/plausible/community-edition>
- Config reference: <https://github.com/plausible/community-edition/wiki/configuration>
- Install docs: <https://github.com/plausible/community-edition/wiki/install>
- Releases: <https://github.com/plausible/community-edition/releases>
- Tracker docs: <https://plausible.io/docs>
