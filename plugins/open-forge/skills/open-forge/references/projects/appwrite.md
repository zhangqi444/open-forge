---
name: appwrite-project
description: Appwrite recipe for open-forge. BSD-3-Clause backend-as-a-service platform (auth, databases, storage, functions, messaging, realtime) packaged as a Docker-microservices stack. Self-hosted via a single `docker run ... --entrypoint="install"` bootstrap that generates a docker-compose.yml + .env locally. Covers the Unix / Windows installers, upgrade semantics (re-run the same installer with the new image tag), one-click marketplace deploys (DigitalOcean / Akamai / AWS), and the major operational footguns (_ENV=production switch, SMTP config, storage device choices, function runtime privileges).
---

# Appwrite

BSD-3-Clause end-to-end backend-as-a-service platform. Auth, databases, storage, cloud functions, realtime, messaging — packaged as 20+ Docker microservices behind a Traefik router. Upstream: <https://github.com/appwrite/appwrite>. Docs: <https://appwrite.io/docs>. Self-host docs: <https://appwrite.io/docs/self-hosting>.

## What you're deploying

The installer produces a docker-compose.yml stack roughly comprising:

- **appwrite** — main API (Swoole PHP)
- **appwrite-traefik** — reverse proxy / TLS terminator
- **appwrite-mariadb** — primary DB
- **appwrite-redis** — cache + queue broker
- **appwrite-assistant** (v1.5+) — OpenAI-backed doc assistant (optional)
- **appwrite-executor** — function runtime orchestrator
- **appwrite-worker-*** — one worker per queue (audits, builds, certificates, databases, deletes, functions, mails, messaging, migrations, usage, webhooks)
- **openruntimes-executor** — runs user functions in sandboxed containers
- **appwrite-schedule** — cron-like scheduler
- **influxdb / telegraf** — metrics

Default public port: `:80` + `:443` (Traefik). Admin UI is at `https://<host>/console`.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker installer (Unix) | README §Self-Hosting | ✅ Recommended | The upstream-blessed path. One `docker run` generates the compose + env. |
| Docker installer (Windows CMD / PowerShell) | README §Self-Hosting | ✅ | Windows dev. |
| DigitalOcean 1-Click | <https://marketplace.digitalocean.com/apps/appwrite> | ✅ | Managed droplet. |
| Akamai (Linode) Marketplace | <https://www.linode.com/marketplace/apps/appwrite/appwrite/> | ✅ | Managed VM. |
| AWS Marketplace | <https://aws.amazon.com/marketplace/pp/prodview-2hiaeo2px4md6> | ✅ | AWS-integrated deploy. |
| Manual docker-compose + .env | <https://appwrite.io/install/compose> + <https://appwrite.io/install/env> | ✅ | Air-gapped / custom; use when you need to pre-seed config before first boot. |
| Kubernetes | Community Helm charts | ⚠️ Community | No upstream Helm chart. Several community charts exist but diverge. |
| Docker Swarm | Upstream compose is compatible | ✅ | Scale-out; needs shared storage for `/storage`. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion` | Drives section. |
| preflight | "Install version?" | Free-text, e.g. `1.9.0` (check <https://github.com/appwrite/appwrite/releases>) | Pinned into the `appwrite/appwrite:<tag>` installer invocation. **Do not use `latest`** — version pinning is the whole upgrade story. |
| preflight | "Install directory?" | Free-text, default `/root/appwrite` (installer mounts `$(pwd)/appwrite`) | Generated `docker-compose.yml` + `.env` live here. |
| domain | "Public domain for Appwrite?" | Free-text | Set during installer prompt (`_APP_DOMAIN` / `_APP_DOMAIN_TARGET`). |
| tls | "Let's Encrypt email?" | Free-text | Set as `_APP_SYSTEM_EMAIL_ADDRESS`. Traefik uses this for ACME. |
| env | "`_APP_ENV` = `production` or `development`?" | `AskUserQuestion` | Production mode disables some verbose logging; **`development` exposes MariaDB and Redis on host ports** (DO NOT use on public hosts). |
| console | "Disable public signups to the console?" | Boolean → `_APP_CONSOLE_WHITELIST_EMAILS` | Critical for public-facing deploys. Without a whitelist, anyone can create an admin account. |
| smtp | "SMTP host/port/user/pass/from?" | Free-text | `_APP_SMTP_*` env vars. Required for password resets, magic links, team invites. |
| storage | "Storage device? (local / s3 / do-spaces / backblaze-b2 / linode / wasabi)" | `AskUserQuestion` | `_APP_STORAGE_DEVICE`. S3-compatible strongly recommended for multi-node / durable storage. |
| functions | "Function runtimes to enable?" | Multi-select | `_APP_FUNCTIONS_RUNTIMES` — comma-separated list. Each runtime pulls a Docker image on first use (multi-GB downloads). |

## Install — Unix (upstream one-liner)

Per upstream README, the canonical install command is:

```bash
docker run -it --rm \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume "$(pwd)"/appwrite:/usr/src/code/appwrite:rw \
    --entrypoint="install" \
    appwrite/appwrite:1.9.0   # pin to specific version — check releases page
```

The installer:

1. Pulls the base image.
2. Prompts interactively for domain, port mapping, https settings, DB passwords, secret keys (defaults are generated — you can usually accept).
3. Writes `./appwrite/docker-compose.yml` + `./appwrite/.env` on the host.
4. Runs `docker compose up -d` from that directory.

After it finishes, the full stack is up; admin UI at `http://localhost` (or `https://<domain>` after DNS + TLS).

**DNS and TLS happen at first Traefik request** — Let's Encrypt cert is obtained on-demand. Point your A-record at the host BEFORE running the installer, or update `.env` + restart after.

### Windows (CMD)

```cmd
docker run -it --rm ^
    --volume //var/run/docker.sock:/var/run/docker.sock ^
    --volume "%cd%"/appwrite:/usr/src/code/appwrite:rw ^
    --entrypoint="install" ^
    appwrite/appwrite:1.9.0
```

### Windows (PowerShell)

```powershell
docker run -it --rm `
    --volume /var/run/docker.sock:/var/run/docker.sock `
    --volume ${pwd}/appwrite:/usr/src/code/appwrite:rw `
    --entrypoint="install" `
    appwrite/appwrite:1.9.0
```

## Post-install — lock down the console

On first visit to `https://<domain>/console`, the FIRST user to sign up becomes a root admin. On public-facing deploys, either:

1. Hit the console IMMEDIATELY and create the admin account before anyone else can, OR
2. Set `_APP_CONSOLE_WHITELIST_EMAILS=you@example.com,teammate@example.com` in `.env` BEFORE the first `docker compose up` so only whitelisted emails can create console accounts.

Pre-install prompting for this is why the installer's interactive flow matters.

## Upgrade procedure

Upstream's upgrade story is "re-run the same installer with a new image tag":

```bash
cd /path/to/appwrite-parent   # the directory that contains appwrite/docker-compose.yml
docker run -it --rm \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume "$(pwd)"/appwrite:/usr/src/code/appwrite:rw \
    --entrypoint="upgrade" \
    appwrite/appwrite:1.9.0
```

The `upgrade` entrypoint:

1. Generates a new `docker-compose.yml` + `.env` (merging in any new env vars with defaults; YOUR existing values are preserved).
2. Runs DB schema migrations via the `appwrite migrate` command.
3. `docker compose up -d` with the new images.

**Read the release notes before every upgrade** — <https://github.com/appwrite/appwrite/releases>. Major-version bumps (0.x → 1.0, 1.x → 2.x) have historically had one-time migration steps.

**Back up `./appwrite/` + MariaDB + `/storage` BEFORE upgrading.** The installer does not do this.

### Manual backup

```bash
cd /path/to/appwrite
# DB
docker compose exec mariadb sh -c 'mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" --all-databases' > backup-$(date +%F).sql
# Storage + config
sudo tar -czf appwrite-backup-$(date +%F).tar.gz docker-compose.yml .env  # no storage here
docker compose down
sudo tar -czf appwrite-volumes-$(date +%F).tar.gz \
  $(docker volume inspect appwrite_appwrite-uploads appwrite_appwrite-functions appwrite_appwrite-config -f '{{.Mountpoint}}')
docker compose up -d
```

## Data layout

Named volumes managed by Compose (check `docker volume ls`):

| Volume | Content |
|---|---|
| `appwrite-uploads` | User-uploaded files (buckets). Skip if using `_APP_STORAGE_DEVICE=s3` or equivalent. |
| `appwrite-functions` | Function source tarballs + deployment artifacts. |
| `appwrite-builds` | Transient build artifacts from function deployments. |
| `appwrite-mariadb` | MariaDB data. |
| `appwrite-redis` | Redis persistence. |
| `appwrite-influxdb` | Metrics. |
| `appwrite-config` | Internal config cache. |
| `appwrite-certificates` | Traefik-managed Let's Encrypt certs. |

On the host, the only persistent files outside volumes are `./appwrite/docker-compose.yml` and `./appwrite/.env`. Version-control these (with `.env` in a separate encrypted secret store) for disaster recovery.

## Configuration

`.env` holds 100+ variables. Full reference: <https://appwrite.io/docs/advanced/self-hosting/environment-variables>. The ones that change across deployments:

| Var | Purpose |
|---|---|
| `_APP_ENV` | `production` or `development`. Set to `production` for public-facing. |
| `_APP_DOMAIN` / `_APP_DOMAIN_TARGET` | Canonical URL + target host for TLS. |
| `_APP_CONSOLE_WHITELIST_EMAILS` | Comma-separated emails allowed to create console accounts. |
| `_APP_SYSTEM_EMAIL_ADDRESS` | "From" address for system emails + Let's Encrypt registration. |
| `_APP_SMTP_*` | Outbound mail. |
| `_APP_STORAGE_DEVICE` | `local` / `s3` / `dospaces` / `backblaze` / `linode` / `wasabi`. |
| `_APP_STORAGE_S3_*` | S3 creds if using s3-compatible. |
| `_APP_FUNCTIONS_RUNTIMES` | Comma-separated runtimes, e.g. `node-20.0,python-3.11,php-8.2`. |
| `_APP_FUNCTIONS_CPUS` / `_APP_FUNCTIONS_MEMORY` | Per-function resource limits. |
| `_APP_OPTIONS_ABUSE` | `enabled` to throttle bruteforce. |
| `_APP_OPTIONS_FORCE_HTTPS` | `enabled` for production. |
| `_APP_MAINTENANCE_*` | Cleanup retention windows. |

After editing `.env`:

```bash
docker compose up -d --force-recreate
```

## One-click / managed deploys

DigitalOcean, Akamai (Linode), and AWS Marketplace ship pre-built Appwrite droplets/VMs/AMIs. These are upstream-blessed (linked from the README) and essentially run the same installer on provision. Upgrade path after: same `docker run ... --entrypoint=upgrade ...` inside the VM.

## Gotchas

- **Installer writes to `$(pwd)/appwrite/`.** The canonical docs run it from `~` / `/root`, which results in `/root/appwrite/`. Prefer `/opt/appwrite/` as a more standard location — `cd /opt && sudo run …` first.
- **The first console signup is root.** On public installs, set `_APP_CONSOLE_WHITELIST_EMAILS` before first `up`, or firewall port 80/443 until you've claimed the admin account.
- **`_APP_ENV=development` exposes DB + Redis on host ports.** Never set this on a public-facing host — MariaDB:3306 and Redis:6379 become directly addressable.
- **Function runtime downloads are huge.** Each enabled runtime (Node, Python, PHP, Deno, Ruby, …) is a multi-GB Docker image pulled on first function invocation. Enable only the runtimes you actually use.
- **Executor mounts `/var/run/docker.sock`.** That effectively grants root on the host. Don't run Appwrite on a machine that hosts other tenants.
- **TLS certs live in a volume, not a file.** To move Appwrite to a new host without re-issuing certs, migrate the `appwrite-certificates` volume along with the rest.
- **Upgrading across major versions can require a one-shot `migrate` command.** Always read the release notes — in past major bumps, the installer asks for confirmation before running destructive migrations.
- **Telegraf / InfluxDB are always on.** If you don't care about metrics, they still run — some users remove them from the generated compose to free RAM. Upstream does NOT currently provide a "disable metrics" toggle.
- **Default `_APP_SMTP_HOST=maildev` is a dev-only MailDev container.** Password-reset emails go into the MailDev UI, NOT to real users. Switch to a real SMTP provider for production.
- **Not official Kubernetes support.** Community Helm charts exist but drift — upstream considers Docker Compose the supported deploy. If you need K8s, be prepared to maintain the Helm chart.
- **Storage default is `local` (host volume).** For any multi-node or durable-storage deploy, switch to an S3-compatible backend via `_APP_STORAGE_DEVICE=s3` + creds.
- **BSD-3 vs BSL trap.** Appwrite core is BSD-3. Some satellite tooling / enterprise features may ship under different licenses in the future — check the `LICENSE` file of anything you add beyond the core image.

## Links

- Upstream repo: <https://github.com/appwrite/appwrite>
- Docs site: <https://appwrite.io/docs>
- Self-hosting guide: <https://appwrite.io/docs/self-hosting>
- Environment variables: <https://appwrite.io/docs/advanced/self-hosting/environment-variables>
- Upgrade guide: <https://appwrite.io/docs/advanced/self-hosting/update>
- Manual compose: <https://appwrite.io/install/compose>
- Manual .env: <https://appwrite.io/install/env>
- Releases: <https://github.com/appwrite/appwrite/releases>
- Discord: <https://appwrite.io/discord>
