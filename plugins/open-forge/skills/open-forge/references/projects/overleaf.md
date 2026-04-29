---
name: Overleaf (Community Edition)
description: Web-based collaborative LaTeX editor. Self-hosted "Overleaf Community Edition" (free, community-supported) + paid "Server Pro" share a codebase. Managed via the official `overleaf/toolkit` wrapper.
---

# Overleaf (Community Edition)

Overleaf is a web-based real-time collaborative LaTeX editor. The self-host distribution ships as a single monolithic image (`sharelatex/sharelatex`) that runs Overleaf's internal services together with TeX Live. You compose it with MongoDB + Redis + optional sibling `texlive` containers and (optionally) a TLS-terminating nginx.

**Do NOT try to hand-write a compose file.** Use `overleaf/toolkit`, the official wrapper — it generates and updates the compose + config from a small set of files under `config/`. The toolkit is the upstream-blessed self-host path.

- Main repo: <https://github.com/overleaf/overleaf>
- **Toolkit (use this):** <https://github.com/overleaf/toolkit>
- Docs: <https://github.com/overleaf/overleaf/wiki>
- Image: `sharelatex/sharelatex` on Docker Hub

## Architecture in one minute

Toolkit splits `docker-compose` into modular fragments under `lib/`:

1. `docker-compose.base.yml` — the `sharelatex` container
2. `docker-compose.mongo.yml` — MongoDB 8.0 (upstream-pinned)
3. `docker-compose.redis.yml` — Redis 7.4
4. `docker-compose.nginx.yml` — optional TLS-terminating nginx (for the recommended TLS proxy setup)
5. `docker-compose.sibling-containers.yml` — enables spawning per-project TeX Live containers
6. `docker-compose.git-bridge.yml` — Server Pro only

Your state lives in `./config/overleaf.rc` + `./config/variables.env` + `./data/`.

## Compatible install methods

| Infra              | Runtime                               | Notes                                                                         |
| ------------------ | ------------------------------------- | ----------------------------------------------------------------------------- |
| Single VM (4+ GB RAM, 20+ GB disk) | Docker + toolkit          | **Recommended.** Upstream-supported path                                      |
| Single VM          | Hand-rolled docker-compose            | Legacy — upstream has a migration guide *away* from this                      |
| Kubernetes         | Not officially supported (CE)         | Community Helm charts exist but aren't upstream-maintained                    |
| Server Pro         | Toolkit + `SERVER_PRO=true`           | Paid — same toolkit, different image, license key required                    |

## Inputs to collect

| Input                            | Example                                    | Phase     | Notes                                                              |
| -------------------------------- | ------------------------------------------ | --------- | ------------------------------------------------------------------ |
| Public URL                       | `https://overleaf.example.com`             | Runtime   | `OVERLEAF_SITE_URL`; used in email links                           |
| SMTP / AWS SES                   | any provider                               | Runtime   | Required — no mail = no password reset, no invites, no alerts       |
| `OVERLEAF_ADMIN_EMAIL`           | `admin@example.com`                        | Runtime   | Admin contact shown to users                                       |
| Open TCP 80 + 443                | firewall                                   | Network   | If using toolkit's nginx TLS proxy                                  |
| TLS cert + key                   | `overleaf_certificate.pem` / `overleaf_key.pem` | TLS  | Bind-mounted into nginx; get via Let's Encrypt or your CA          |
| Docker socket                    | `/var/run/docker.sock`                     | Runtime   | Mounted by default for sibling-containers; high-trust — see Gotchas |
| Data dir                         | `./data/overleaf`, `./data/mongo`, `./data/redis` | Data | All state lives under `./data/`                                     |

## Install via `overleaf/toolkit` (recommended)

Per <https://github.com/overleaf/toolkit/blob/master/doc/quick-start-guide.md>:

```sh
# 1. Clone the toolkit
git clone https://github.com/overleaf/toolkit.git overleaf-toolkit
cd overleaf-toolkit

# 2. Initialize config (creates config/overleaf.rc + variables.env + version)
bin/init

# 3. Edit config/overleaf.rc — pick SERVER_PRO (false for CE), IPs, ports, mongo/redis versions.
# 4. Edit config/variables.env — set OVERLEAF_SITE_URL, OVERLEAF_ADMIN_EMAIL, SMTP_*, OVERLEAF_NAV_TITLE, etc.
# 5. Bring it up:
bin/up -d
```

First boot takes several minutes while MongoDB initializes and the image unpacks TeX Live. Watch logs with `bin/logs`.

After up, browse `OVERLEAF_SITE_URL` and visit `/launchpad` to create the first admin account. The launchpad is disabled after the first admin is created.

### Backups

Toolkit ships `bin/backup-config` (captures `config/` to a tarball) and helper scripts under `bin/`. For data: snapshot `./data/mongo/`, `./data/redis/`, `./data/overleaf/` (compile outputs, user uploads, history).

### CLI wrapper

Never call `docker compose` directly — use the toolkit wrappers:

- `bin/up [-d]` — start
- `bin/down` — stop
- `bin/restart` — restart
- `bin/logs <service>` — logs
- `bin/shell` — shell inside the sharelatex container
- `bin/upgrade` — pull + upgrade per `config/version`
- `bin/docker-compose` — the underlying compose call if you really need it (accepts -f flags; output of `bin/docker-compose config` shows the effective merged compose)
- `bin/doctor` — produce diagnostic output (include in support requests)

## Data & config layout

- `config/overleaf.rc` — which subsystems to enable (Mongo/Redis/Git-bridge/Nginx/sibling containers) + data paths
- `config/variables.env` — all app-level env vars (SMTP, S3, LDAP, Server Pro features)
- `config/version` — image version pin; `bin/upgrade` bumps this
- `config/nginx/` — nginx config + TLS certs (only if `NGINX_ENABLED=true`)
- `data/overleaf/` — user compile output, history, uploads
- `data/mongo/` — MongoDB 8.0 data
- `data/redis/` — Redis 7.4 AOF data
- `data/git-bridge/` — Server Pro only

## Upgrade

1. `bin/upgrade` — interactive. Prompts for target version (from <https://github.com/overleaf/overleaf/wiki/Release-Notes>), pulls the new image, optionally runs MongoDB/Redis container upgrades, preserves config.
2. The script handles MongoDB version bumps carefully — it will refuse to upgrade across a MongoDB major without an explicit opt-in.
3. Read release notes before every major jump. Some changes require running a data-migration script inside the container.

## Gotchas

- **Don't hand-roll compose.** People still copy-paste `sharelatex/sharelatex` into their own compose stack; it works briefly, then breaks on upgrade when internal process managers and MongoDB versions diverge. The toolkit exists because upstream tried to migrate everyone off ad-hoc compose.
- **Server Pro vs Community Edition:** Server Pro is paid and unlocks LDAP/SAML/SCIM, templates, Git bridge, references management, enterprise audit logs. CE is free and runs the same core editor — but individual features gated in `variables.env` simply don't activate without a license.
- **Docker socket is mounted.** With `SIBLING_CONTAINERS_ENABLED=true` (default), the sharelatex container launches per-project `texlive` containers via the host Docker socket. That means the sharelatex container is effectively root-on-host — treat its trust boundary accordingly.
- **TeX Live inside the image is huge.** Default `sharelatex/sharelatex:*-with-texlive-full` is ~8–10 GB. First pull takes a long time; plan disk.
- **MongoDB 8.0 is a recent upgrade.** Older toolkit versions pinned `mongo:5.0` / `mongo:6.0`. Check `config/overleaf.rc`'s `MONGO_VERSION` before upgrading — a cross-major Mongo bump needs `mongosh` compat mode flags.
- **Redis AOF persistence** is on by default. Don't disable — losing Redis midflight corrupts compile queue state and active collaboration sessions.
- **`OVERLEAF_SITE_URL` must match exactly** (scheme + host + port, no trailing slash). Wrong value = broken email links, broken asset URLs.
- **Air-gapped setups:** set `PULL_BEFORE_UPGRADE=false` in `overleaf.rc` and manually sideload images; same for `SIBLING_CONTAINERS_PULL=false`.
- **`EMAIL_CONFIRMATION_DISABLED=true`** is the default in `variables.env`. Fine for single-team CE; turn it off (set to `false`) if your users need email verification before editing projects.
- **`TEX_LIVE_DOCKER_IMAGE=quay.io/sharelatex/texlive-full:YYYY.1`** (Server Pro only) lets you pin the sibling-container TeX Live edition. CE bundles TeX Live inside the main image; Server Pro can spawn per-project TeX Live containers.
- **No built-in TLS unless `NGINX_ENABLED=true`.** Community users often put Overleaf behind their own Caddy/Traefik — works fine, but ensure `OVERLEAF_BEHIND_PROXY=true` + `OVERLEAF_SECURE_COOKIE=true` in `variables.env`.
- **CE has no admin UI for users before first admin exists.** Hit `/launchpad` exactly once to create the first admin; afterward, manage users from `/admin/users`.
- **Linked files to external URLs** are disabled by default in CE — enable via `ENABLED_LINKED_FILE_TYPES=url,project_file,project_output_file` only on trusted networks; URL linking is a modest SSRF risk.
- **Git bridge is Server Pro only.** CE users who need Git integration push/pull through a third-party integration or the raw history API.
- **`bin/doctor` output should be attached to every CE issue report.** It's the only reliable way for upstream to understand your config.

## Links

- Toolkit repo: <https://github.com/overleaf/toolkit>
- Quick start: <https://github.com/overleaf/toolkit/blob/master/doc/quick-start-guide.md>
- Docs index: <https://github.com/overleaf/toolkit/blob/master/doc/README.md>
- Wiki: <https://github.com/overleaf/overleaf/wiki>
- Release notes: <https://github.com/overleaf/overleaf/wiki/Release-Notes>
- Docker Hub: <https://hub.docker.com/r/sharelatex/sharelatex>
- Server Pro (commercial): <https://www.overleaf.com/for/enterprises>
