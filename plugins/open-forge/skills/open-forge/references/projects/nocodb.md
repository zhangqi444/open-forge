---
name: nocodb-project
description: NocoDB recipe for open-forge. Sustainable-Use-License-1.0 no-code database platform (open-source Airtable alternative — grid/gallery/kanban/form/calendar views on top of Postgres/MySQL/SQLite). Covers the four upstream-blessed self-host paths: Docker one-liner with SQLite, Docker with external Postgres/MySQL, `docker-compose` (plain Postgres + plain Traefik variants), and the `install.nocodb.com/noco.sh` Auto-Upstall script (generates a production compose with NocoDB + Postgres + Redis + MinIO + Traefik-TLS + auto-renewal).
---

# NocoDB

No-code database platform — open-source Airtable alternative. Turns any Postgres / MySQL / SQLite database into a collaborative spreadsheet UI with grid / gallery / kanban / form / calendar views.

Upstream: <https://github.com/nocodb/nocodb>. Docs: <https://docs.nocodb.com/>. Self-host docs: <https://nocodb.com/docs/self-hosting>.

**License caveat.** NocoDB is licensed under the Sustainable Use License 1.0 (*not* AGPL / MIT). It's "source-available with commercial-use restrictions" rather than OSI-approved open-source. In practice: self-hosting for your own organisation is fine; reselling NocoDB-as-a-service or building a competing commercial product on top is not. Full text: <https://github.com/nocodb/nocodb/blob/master/LICENSE.md>.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Auto-Upstall (`noco.sh`) | <https://raw.githubusercontent.com/nocodb/nocodb/develop/docker-compose/1_Auto_Upstall/noco.sh> | ✅ | **Recommended production path.** One command sets up Docker + compose + NocoDB + Postgres + Redis + MinIO + Traefik-with-Let's-Encrypt + auto-renewal. Idempotent: re-running upgrades to latest. |
| `docker run` + SQLite | README | ✅ | Quickest start. Single container, SQLite in a volume. Fine for single-user / evaluation; not production-grade. |
| `docker run` + external Postgres/MySQL | README | ✅ | When you already run a DB server. Just NocoDB in a container, no bundled DB. |
| `docker-compose` (Postgres, no TLS) | `docker-compose/2_pg/docker-compose.yml` on `develop` | ✅ | Minimal two-container stack (NocoDB + `postgres:16.6`). Put your own reverse proxy in front for TLS. |
| `docker-compose` (Traefik + Postgres) | `docker-compose/3_traefik/docker-compose.yml` on `develop` | ✅ | Bundled Traefik v2.11 with Let's Encrypt DNS-challenge (Cloudflare) + Watchtower for auto-upgrades. Stricter than Auto-Upstall — you manage the stack directly. |
| Binary | `get.nocodb.com/<os>-<arch>` | ✅ | Quick local testing only (README is explicit about this). Mac/Linux/Windows; arm64 + x64. |
| AWS / GCP / DigitalOcean marketplace | <https://docs.nocodb.com/self-hosting/installation/> | ✅ | Cloud marketplace images — thin wrappers over Docker. Deferred to upstream docs. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Which install method?" | `AskUserQuestion` from the table above | Drives which section runs. |
| preflight | "Docker + Docker Compose available?" | `AskUserQuestion`: `Yes` / `No — install first` / `Use Auto-Upstall (installs Docker for me)` | Auto-Upstall handles Docker install itself. |
| dns | *production* "What's the FQDN for NocoDB?" (e.g. `nocodb.example.com`) | Free-text | Sets `NC_SITE_URL` + Traefik Host rule (or reverse-proxy config). |
| dns | *Traefik variant* "DNS provider for Let's Encrypt DNS-challenge?" | `AskUserQuestion`: `Cloudflare` (compose default) / `Other` | Compose template uses `cloudflare` provider + `CF_DNS_API_TOKEN`; for other providers swap the Traefik flags per <https://doc.traefik.io/traefik/https/acme/#providers>. |
| db | "SQLite / Postgres / MySQL?" | `AskUserQuestion` | SQLite = single-file dev; Postgres = production default (both compose templates use it); MySQL is supported but less represented in upstream templates. |
| db | *external DB* "DB connection string (`NC_DB`)?" | Free-text | Format: `pg://host:port?u=user&p=pass&d=dbname` or `mysql2://host:port?u=user&p=pass&d=dbname`. Upstream uses URL-ish syntax, not a standard DSN. |
| auth | "JWT secret (random 32+ chars)?" | Generated: `openssl rand -hex 32` | Sets `NC_AUTH_JWT_SECRET`. **Mandatory** for production — if omitted, NocoDB generates one on first boot and bakes it into `~/.nc/meta.db`, but setting your own is better practice. |
| smtp | "Set up SMTP for invites / password resets?" | `AskUserQuestion`: `Yes` / `No (configure later in Team & Settings → App Store)` | NocoDB's SMTP is configured via the in-app **App Store**, not env vars. You can defer. |
| storage | "Attachment storage: local (default) / S3 / MinIO / GCS?" | `AskUserQuestion` | Also configured via in-app **App Store → Storage** section, not env vars. Local storage persists inside `/usr/app/data`. |

Write answers to state so resume skips re-prompting.

## Install — `docker run` with SQLite (simplest)

```bash
docker run -d \
  --name noco \
  -v "$(pwd)/nocodb:/usr/app/data/" \
  -p 8080:8080 \
  nocodb/nocodb:latest
```

Open <http://localhost:8080/dashboard>. First user to sign up becomes the super-admin.

Data + SQLite file live in `./nocodb/` on the host. Back up by stopping the container + tar'ing that directory.

## Install — `docker run` with external Postgres

```bash
docker run -d \
  --name noco \
  -v "$(pwd)/nocodb:/usr/app/data/" \
  -p 8080:8080 \
  -e NC_DB="pg://host.docker.internal:5432?u=root&p=password&d=nocodb" \
  -e NC_AUTH_JWT_SECRET="$(openssl rand -hex 32)" \
  nocodb/nocodb:latest
```

Replace `host.docker.internal` with the DB's reachable host from inside the container. On Linux, use the host's LAN IP or `--network=host`.

## Install — Auto-Upstall (production, one-liner)

Upstream's recommended production path. Script at <https://raw.githubusercontent.com/nocodb/nocodb/develop/docker-compose/1_Auto_Upstall/noco.sh>.

```bash
# Read the script first. Don't 'curl | bash' blind.
curl -sSL http://install.nocodb.com/noco.sh -o /tmp/noco.sh
less /tmp/noco.sh
bash /tmp/noco.sh <(mktemp)
```

It prompts interactively for:

1. Domain / subdomain (used for Let's Encrypt cert + `NC_SITE_URL`)
2. Whether to enable SSL (yes, unless you have a reason)
3. Whether to enable MinIO for attachment storage
4. Whether to enable Redis for caching
5. Admin email (for Let's Encrypt notices)

It then:

- Installs Docker + Docker Compose if missing.
- Writes a `docker-compose.yml` under `/root/nocodb/` (or the dir you ran from).
- Pulls images: `nocodb/nocodb:latest`, `postgres`, `redis`, `minio/minio`, `traefik`.
- Brings the stack up.
- Obtains + installs Let's Encrypt certs via Traefik's HTTP-01 challenge.
- Sets up automatic renewal (Traefik handles it live).

To upgrade later: **re-run the same command.** The script is idempotent — detects existing install, pulls latest images, restarts services.

## Install — `docker-compose` (Postgres, no TLS)

Upstream minimal compose at `docker-compose/2_pg/docker-compose.yml` on `develop`. Pulls `nocodb/nocodb:latest` + `postgres:16.6`.

```bash
mkdir -p /opt/nocodb && cd /opt/nocodb
curl -fsSL -o docker-compose.yml \
  https://raw.githubusercontent.com/nocodb/nocodb/develop/docker-compose/2_pg/docker-compose.yml

# Edit the Postgres password before first boot
sed -i "s|POSTGRES_PASSWORD: password|POSTGRES_PASSWORD: $(openssl rand -hex 24)|" docker-compose.yml
# Mirror the new password into the NC_DB URL
# (or better — refactor to use an .env file; upstream's template hardcodes)

docker compose up -d
```

NocoDB is at `http://<host>:8080/dashboard`. Put your own reverse proxy (Caddy / Nginx / Traefik) in front for TLS.

## Install — `docker-compose` (Traefik + Postgres + Watchtower)

Upstream's Traefik-fronted template at `docker-compose/3_traefik/docker-compose.yml`. Uses Traefik v2.11 with Cloudflare DNS-01 challenge (wildcard cert) + Watchtower for auto-updates.

```bash
mkdir -p /opt/nocodb && cd /opt/nocodb
curl -fsSL -o docker-compose.yml \
  https://raw.githubusercontent.com/nocodb/nocodb/develop/docker-compose/3_traefik/docker-compose.yml

# Required env vars
cat > .env <<EOF
DOMAINNAME=example.com
DATABASE_USER=nocodb
DATABASE_PW=$(openssl rand -hex 24)
DATABASE_NAME=nocodb
CF_DNS_API_TOKEN=<cloudflare-api-token-with-zone-dns-edit-scope>
EOF

docker compose up -d
```

NocoDB at `https://nocodb.${DOMAINNAME}/`. Traefik obtains a wildcard cert for `*.${DOMAINNAME}` via Cloudflare DNS-01.

**Using a different DNS provider?** Edit the `--certificatesresolvers.letsencrypt.acme.dnschallenge.provider=cloudflare` Traefik flag + swap the `CF_DNS_API_TOKEN` env var for the provider's equivalent. List: <https://doc.traefik.io/traefik/https/acme/#providers>.

## Config surface

| Env var | Role |
|---|---|
| `NC_DB` | DB connection URL. `pg://host:port?u=user&p=pass&d=db` / `mysql2://...` / omit = SQLite in `/usr/app/data/`. |
| `NC_AUTH_JWT_SECRET` | JWT signing secret. Auto-generated if omitted; set your own for stable tokens across container recreates. |
| `NC_SITE_URL` | Public URL (for email links, OAuth callbacks). e.g. `https://nocodb.example.com`. |
| `NC_ADMIN_EMAIL` / `NC_ADMIN_PASSWORD` | Pre-create super-admin at first boot instead of relying on "first user wins." |
| `NC_DISABLE_TELE` | Set to `true` to opt out of anonymous telemetry. |
| `NC_REDIS_URL` | Optional Redis for cache. `redis://host:port`. |
| `NC_SMTP_*` | NOT env vars — SMTP is configured in-app (App Store). |
| `NC_S3_*` | NOT env vars — storage backends configured in-app (App Store). |

Full env var reference: <https://docs.nocodb.com/self-hosting/environment-variables>.

## Upgrade

- **Auto-Upstall:** re-run `bash <(curl -sSL http://install.nocodb.com/noco.sh) <(mktemp)`. Idempotent.
- **Plain Docker / Compose:**
  ```bash
  cd /opt/nocodb
  docker compose pull
  docker compose up -d
  # Schema migrations run automatically on NocoDB container startup.
  ```
- **Traefik template** ships with Watchtower scheduled daily at 05:00 — it pulls + restarts labeled containers automatically. Disable by removing the `watchtower` service or the `com.centurylinklabs.watchtower.enable=true` labels.

Always dump the Postgres DB before major upgrades:

```bash
docker compose exec -T root_db pg_dump -U postgres nocodb | gzip \
  > backups/nocodb-$(date +%Y%m%d-%H%M%S).sql.gz
```

## Gotchas

- **License is Sustainable Use, not OSI-open-source.** Self-hosting for your own org/team is fine; building a commercial NocoDB-as-a-service on top isn't. Read <https://github.com/nocodb/nocodb/blob/master/LICENSE.md> once before committing to it for business-critical work.
- **`NC_DB` URL syntax is custom.** Not a standard DSN — NocoDB parses `pg://host:port?u=user&p=pass&d=db` into its own connection object. Special chars in passwords need URL-encoding (`openssl rand -hex` output is safe; generated passwords with `$`, `&`, `%` may break parsing).
- **JWT secret on first boot is bad for disaster recovery.** If you don't set `NC_AUTH_JWT_SECRET`, NocoDB generates one and stores it in the metadata DB. Restoring a backup to a fresh container generates a *new* secret, invalidating all old tokens. Set your own JWT secret and store it with your backups.
- **SMTP / storage configured in-app, not env.** Counterintuitive — most self-hosted tools use env vars for these. In NocoDB, log in as admin, go to **Team & Settings → App Store → Email / Storage**, configure there. Settings are stored in the metadata DB (backed up with Postgres).
- **Auto-Upstall writes to `/root/`.** If you ran the installer as root (which it expects), it drops the compose under `/root/nocodb/`. That's non-standard on modern Linux hosts — consider `mv`'ing to `/opt/nocodb/` post-install if you care.
- **Traefik template uses DNS-01 challenge.** Requires API access to your DNS provider (Cloudflare API token by default). Won't work on networks where DNS is managed elsewhere. Switch to HTTP-01 by editing Traefik's acme flags if you can't / don't want DNS-01.
- **Postgres version mismatch between templates.** `2_pg` uses `postgres:16.6`; `3_traefik` uses `postgres:12.17-alpine`. Both work, but pick one and don't cross-migrate volumes. Upstream should harmonise these; flag in an issue if it bites.
- **"First user wins" for super-admin.** Guard the URL during bootstrap, or pre-create admin via `NC_ADMIN_EMAIL` + `NC_ADMIN_PASSWORD`.
- **Watchtower auto-upgrades on the Traefik template.** Daily at 05:00. If you pin a NocoDB version and Watchtower still pulls `latest`, that's because the container uses tag `nocodb/nocodb:latest`. To pin, change the image tag AND remove the Watchtower label.
- **Local attachment storage lives in the container volume.** Not in Postgres. Back up `nc_data` / `nocodb-data` volumes separately. Moving to S3 / MinIO via App Store is the production path.

## Upstream references

- Repo: <https://github.com/nocodb/nocodb>
- Docs: <https://docs.nocodb.com/>
- Self-hosting index: <https://nocodb.com/docs/self-hosting>
- Env var reference: <https://docs.nocodb.com/self-hosting/environment-variables>
- Auto-Upstall script: <https://raw.githubusercontent.com/nocodb/nocodb/develop/docker-compose/1_Auto_Upstall/noco.sh>
- Compose templates: <https://github.com/nocodb/nocodb/tree/develop/docker-compose>
- License: <https://github.com/nocodb/nocodb/blob/master/LICENSE.md>

## TODO — verify on first deployment

- Confirm the compose-template Postgres versions (one uses 16.6, the other 12.17 — may have drifted).
- Verify `NC_ADMIN_EMAIL` / `NC_ADMIN_PASSWORD` first-boot bootstrap still works as documented (feature added in 0.200.x; ensure it's not regressed).
- Test Auto-Upstall on a fresh Ubuntu 24.04 host end-to-end; document actual file layout + what it creates.
- Verify the in-app App Store SMTP / S3 wiring still matches upstream docs after the next minor release.
