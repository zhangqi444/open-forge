---
name: Listmonk
description: Self-hosted, high-performance newsletter and mailing-list manager. Single Go binary + PostgreSQL. AGPL v3.
---

# Listmonk

Listmonk is a standalone newsletter and mailing-list manager. Subscriber lists with custom attributes, list segmentation, transactional templates, analytics, bounce processing, and a JSON REST API. Backed by PostgreSQL, packaged as a single Go binary. Handles millions of subscribers on modest hardware.

- Upstream repo: <https://github.com/knadh/listmonk>
- Docs: <https://listmonk.app/docs/>
- Installation docs: <https://listmonk.app/docs/installation/>
- Image: `listmonk/listmonk` on Docker Hub
- License: AGPL v3

## Compatible install methods

| Infra              | Runtime                          | Notes                                                    |
| ------------------ | -------------------------------- | -------------------------------------------------------- |
| Single VM          | Docker + Compose                 | Recommended — upstream ships `docker-compose.yml`        |
| Bare metal         | Downloaded binary + systemd      | Fully supported; Go static binary                        |
| Kubernetes         | Community Helm charts            | No official chart; manifests trivial                     |

## Inputs to collect

| Input                    | Example                                  | Phase     | Notes                                                              |
| ------------------------ | ---------------------------------------- | --------- | ------------------------------------------------------------------ |
| Admin user / password    | `admin` / strong                         | Runtime   | `LISTMONK_ADMIN_USER` + `LISTMONK_ADMIN_PASSWORD` on first boot    |
| DB credentials           | `listmonk`/`listmonk`/`listmonk`         | Runtime   | Upstream defaults — **change before going to prod**                |
| SMTP                     | any provider                             | Runtime   | Configured in the UI (Settings → SMTP)                             |
| Public URL (hostname)    | `lists.example.com`                      | Runtime   | Used in unsubscribe links, tracking pixels                         |
| Uploads dir              | `./uploads:/listmonk/uploads`            | Data      | Bind-mount for subscriber-imported CSVs + email assets             |
| Timezone                 | `Etc/UTC` or local                       | Runtime   | Affects campaign scheduling                                        |

## Install via Docker Compose

Upstream's canonical compose (at <https://github.com/knadh/listmonk/blob/master/docker-compose.yml>) is production-ready but uses default credentials — change them before exposing the instance.

```sh
curl -LO https://github.com/knadh/listmonk/raw/master/docker-compose.yml

# Pin image + set admin creds. Edit docker-compose.yml:
#   image: listmonk/listmonk:v5.0.0   (avoid :latest in production)
#
# And create .env next to it:
cat > .env <<EOF
LISTMONK_ADMIN_USER=admin
LISTMONK_ADMIN_PASSWORD=$(openssl rand -base64 24)
EOF

docker compose up -d
```

Browse `http://<host>:9000` → log in with the admin creds. If you didn't set `LISTMONK_ADMIN_*` on first boot, the first UI visit will prompt you to create them.

Releases: <https://github.com/knadh/listmonk/releases>.

### Key env vars (upstream compose)

Listmonk maps its `config.toml` keys to env vars via the `LISTMONK_<section>__<key>` pattern (two underscores between section and key):

- `LISTMONK_app__address=0.0.0.0:9000` — bind
- `LISTMONK_db__host=db`, `LISTMONK_db__user=listmonk`, `LISTMONK_db__password=...`, `LISTMONK_db__database=listmonk`, `LISTMONK_db__port=5432`, `LISTMONK_db__ssl_mode=disable`
- `LISTMONK_ADMIN_USER` / `LISTMONK_ADMIN_PASSWORD` — one-shot first-boot super admin creation
- All `LISTMONK_*` also support a `_FILE` suffix for Docker/Podman secrets

Full config reference (file form): <https://github.com/knadh/listmonk/blob/master/config.toml.sample>.

### Startup command

Upstream's container command chains three invocations:

```
./listmonk --install --idempotent --yes --config '' && \
./listmonk --upgrade --yes --config '' && \
./listmonk --config ''
```

- `--install --idempotent` installs schema on empty DB, no-ops otherwise
- `--upgrade` runs migrations on each start
- `--config ''` forces the binary to use env vars (no config file)

## Data & config layout

- Volume `listmonk-data` → `/var/lib/postgresql/data` — Postgres data (pinned to `postgres:17-alpine` in upstream compose)
- `./uploads` on host → `/listmonk/uploads` — subscriber-imported CSVs, uploaded media, campaign assets. Path configured in Admin → Settings → Media.
- Config is env-var driven; no config file needed when `--config ''`.

## Backup

```sh
# Database
docker compose exec -T db pg_dump -U listmonk listmonk | gzip > listmonk-$(date +%F).sql.gz

# Uploads (bind-mounted, just tar the host dir)
tar czf listmonk-uploads-$(date +%F).tgz ./uploads
```

## Upgrade

1. Check release notes: <https://github.com/knadh/listmonk/releases>.
2. Bump the `listmonk/listmonk` image tag in compose.
3. `docker compose pull && docker compose up -d`.
4. The entrypoint's `--upgrade` flag runs DB migrations automatically on boot.
5. **Back up Postgres before major-version upgrades.** Migrations are largely additive but have occasionally been destructive.

## Gotchas

- **Default credentials** (`listmonk` / `listmonk` / `listmonk` for DB) are baked into the upstream compose. Change them before the Postgres volume is first initialized — afterwards the creds are locked in on disk.
- **Postgres port 5432 binds to `127.0.0.1` by default.** Don't change to `0.0.0.0` without adding host firewall rules.
- **Public URL is not auto-detected.** Set `LISTMONK_app__root_url` (or UI: Settings → General) to your public HTTPS URL, otherwise unsubscribe/tracking URLs go to `localhost:9000`.
- **SMTP is configured in the UI**, not via env vars. After first login, go to Settings → SMTP, add at least one server, and send a test. Campaign-send failure without SMTP configured is silent.
- **Bounce processing** needs an IMAP mailbox (`bounce@yourdomain`) plus configuration in Settings → Bounces. Without it, bouncing addresses stay "enabled" forever.
- **Admin user creation is first-boot-only via env.** After the super admin exists, `LISTMONK_ADMIN_USER`/`_PASSWORD` env are ignored — to reset the password, use `./listmonk --config '' --admin-password <new>` inside the container.
- **AGPL v3.** If you expose a modified Listmonk over a network, you must offer source.
- **Campaign rate limiting**: Listmonk will saturate your SMTP provider. Set `max_msg_body` + per-SMTP `max_conns` and `max_msgs_per_min` in Settings → SMTP to stay within provider limits (e.g. SES, Sendgrid, Postmark).
- **DKIM/SPF/DMARC** are your responsibility; Listmonk signs nothing. Misconfigured DNS = your campaigns land in spam.
- **Postgres 17 is very new.** Upstream pinned to it in 2025; to downgrade for a managed Postgres 16 elsewhere, restore from pg_dump (on-disk format differs across majors).
- **The sample compose exposes Postgres on localhost** — fine for single-host, surprising if you thought it was internal-only.
- **The `--yes` flags auto-confirm destructive-sounding prompts.** They're safe when chained as in the default command, but be aware if you script custom CLI invocations.

## Links

- Docs: <https://listmonk.app/docs/>
- Installation: <https://listmonk.app/docs/installation/>
- Upgrade guide: <https://listmonk.app/docs/maintenance/update/>
- Config reference: <https://github.com/knadh/listmonk/blob/master/config.toml.sample>
- Compose file: <https://github.com/knadh/listmonk/blob/master/docker-compose.yml>
- Releases: <https://github.com/knadh/listmonk/releases>
- Docker Hub: <https://hub.docker.com/r/listmonk/listmonk>
