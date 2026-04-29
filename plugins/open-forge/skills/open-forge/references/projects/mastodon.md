---
name: mastodon-project
description: Mastodon recipe for open-forge. AGPL-3.0 federated social network server (ActivityPub). Rails monolith + Node.js streaming API + PostgreSQL + Redis + Sidekiq. Two canonical self-host paths — Docker Compose (upstream's production-oriented `docker-compose.yml`) and a bare-metal install using the upstream Ubuntu guide. Covers the `tootctl setup` bootstrapping wizard, object storage (local vs S3/R2), SMTP, the full-text search engine choice (Elasticsearch optional), and the sidekiq-queue sizing story.
---

# Mastodon

AGPL-3.0 federated ActivityPub social network server. Upstream: <https://github.com/mastodon/mastodon>. Docs: <https://docs.joinmastodon.org/>.

Tech stack (from upstream README):

- **Ruby on Rails** — web + REST API (`web` service, Puma).
- **Node.js** — streaming API (`streaming` service; longpolling-style websocket for live timelines).
- **PostgreSQL 14+** — primary database.
- **Redis 7+** — cache + Sidekiq queue broker.
- **Sidekiq** — background workers (queue for federation delivery, media processing, push notifications).
- **Elasticsearch 7.17.x** (optional) — full-text search. Without it, search falls back to username/hashtag only.

**Network exposure in compose:** `web` on `127.0.0.1:3000`, `streaming` on `127.0.0.1:4000`, Postgres/Redis internal-only. A reverse proxy in front (nginx / Caddy / Traefik) handles TLS + routes `/api/v1/streaming/*` to `:4000` and everything else to `:3000`.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://github.com/mastodon/mastodon/blob/main/docker-compose.yml> | ✅ | The upstream-recommended production path for self-host. |
| Bare-metal install (Ubuntu) | <https://docs.joinmastodon.org/admin/install/> | ✅ | Traditional install: rbenv + Node + nginx + systemd. More moving parts, more tuning levers. |
| Dev environment (local Docker) | <https://github.com/mastodon/mastodon/blob/main/docs/DEVELOPMENT.md> | ✅ | Development only — separate compose shape. |
| Community Helm / K8s charts | Various community | ⚠️ Community | No upstream Helm; charts drift. |
| Masto.host / Hostdon / etc. | Third-party | ⚠️ Managed | Paid managed Mastodon hosting. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method? (docker / bare-metal)" | `AskUserQuestion` | Drives section. |
| domain | "Mastodon primary domain (e.g. `mastodon.example.com`)?" | Free-text | **IMMUTABLE after first federation event** — you cannot change this without breaking every existing follow. |
| domain | "Federation-alias domain (e.g. `example.com` with `LOCAL_DOMAIN` rewrite)?" | Free-text (optional) | Advanced WebFinger aliasing — see upstream guide. Only skip if you're sure the primary `LOCAL_DOMAIN` equals `WEB_DOMAIN`. |
| secrets | "Regenerate `SECRET_KEY_BASE`, `OTP_SECRET`, VAPID keys?" | Boolean (default yes) | Generated via `bundle exec rake secret` and `bundle exec rake mastodon:webpush:generate_vapid_key`. |
| db | "Postgres: bundled container or external server?" | `AskUserQuestion` | Production at scale usually splits out Postgres for backups + scaling. |
| redis | "Redis: bundled container or external?" | `AskUserQuestion` | Same reasoning. |
| storage | "Media storage? (local volume / S3 / R2 / DO Spaces / MinIO)" | `AskUserQuestion` | S3-compatible recommended for anything expecting users. Sets `S3_ENABLED`, `S3_BUCKET`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `S3_ALIAS_HOST` (CDN domain). |
| smtp | "SMTP host/user/pass/from?" | Free-text (sensitive) | Required for account confirmation + password resets. Without SMTP, no one can register. |
| search | "Enable Elasticsearch full-text search?" | `AskUserQuestion` | Adds `es` service + 512MB+ RAM. `ES_ENABLED=true`. |
| admin | "Initial admin email + username?" | Free-text | Created via `tootctl accounts create` + `tootctl accounts modify --role Owner`. |

## Install — Docker Compose (upstream)

Get upstream's compose + .env.production.sample:

```bash
sudo mkdir -p /opt/mastodon
cd /opt/mastodon
sudo curl -O https://raw.githubusercontent.com/mastodon/mastodon/main/docker-compose.yml
sudo curl -o .env.production https://raw.githubusercontent.com/mastodon/mastodon/main/.env.production.sample

# Create host-mount dirs (compose uses bind mounts for pg/redis/system)
sudo mkdir -p postgres14 redis public/system
sudo chown -R 991:991 public/system  # mastodon user inside container is UID 991
```

### Generate secrets + bootstrap `.env.production`

Mastodon ships a `tootctl setup` wizard that walks through config:

```bash
sudo docker compose run --rm web bundle exec rake mastodon:setup
```

The wizard prompts for:

- Domain (LOCAL_DOMAIN)
- Single-user mode (yes/no)
- Postgres / Redis host+creds (defaults to compose internal hosts)
- S3 / local media storage
- SMTP config
- Save `.env.production` to stdout (you copy/paste to file)
- Create the admin account (`tootctl accounts create` under the hood)

After wizard completes, write the generated config to `.env.production`, then:

```bash
# Initial DB setup
sudo docker compose run --rm web bundle exec rake db:setup

# Bring up the full stack
sudo docker compose up -d
sudo docker compose logs -f web
```

Visit `https://<LOCAL_DOMAIN>/` (after reverse-proxy + DNS). Log in with the admin account.

### Reverse proxy (nginx — upstream-published config)

Upstream maintains a sample nginx config at <https://github.com/mastodon/mastodon/blob/main/dist/nginx.conf>. Key points:

- Everything proxies to `web` on `:3000` by default.
- `/api/v1/streaming` → `streaming` on `:4000` (websocket upgrade).
- `/system` → static file serve from `/opt/mastodon/public/system/` (or S3 alias host).
- `X-Forwarded-*` headers passed through.

### Scaling Sidekiq

The default compose runs a single Sidekiq process with all queues. On servers with >100 users / heavy federation:

```yaml
# Extra sidekiq workers, each on different queue groups
sidekiq_push:
  image: ghcr.io/mastodon/mastodon:v4.5.9
  command: bundle exec sidekiq -q push
  # ... same env_file, depends_on ...

sidekiq_pull:
  command: bundle exec sidekiq -q pull

sidekiq_mailers:
  command: bundle exec sidekiq -q mailers
```

See <https://docs.joinmastodon.org/admin/scaling/#scaling-sidekiq> for the recommended queue-splitting patterns.

## Install — Bare-metal (Ubuntu)

Upstream guide: <https://docs.joinmastodon.org/admin/install/>. Summary:

```bash
# 1. System packages
sudo apt-get install -y curl wget gnupg apt-transport-https lsb-release ca-certificates
# Node 20 via Nodesource
curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash -
# PostgreSQL
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y imagemagick ffmpeg libpq-dev libxml2-dev libxslt1-dev file git-core \
    g++ libprotobuf-dev protobuf-compiler pkg-config nodejs gcc autoconf \
    bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev \
    libncurses5-dev libffi-dev libgdbm-dev nginx redis-server redis-tools \
    postgresql postgresql-contrib certbot python3-certbot-nginx libidn11-dev libicu-dev libjemalloc-dev

# 2. corepack + yarn
sudo corepack enable

# 3. mastodon system user
sudo adduser --disabled-login mastodon
sudo su - mastodon

# 4. rbenv + Ruby 3.3
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
cd ~/.rbenv && src/configure && make -C src
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
exec bash
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
rbenv install 3.3.7
rbenv global 3.3.7

# 5. Clone Mastodon
git clone https://github.com/mastodon/mastodon.git live && cd live
git checkout $(git tag -l | grep -v 'rc[0-9]*$' | sort -V | tail -n 1)  # latest stable
bundle config deployment 'true'
bundle config without 'development test'
bundle install -j$(nproc)
yarn install --pure-lockfile

# 6. Setup wizard
RAILS_ENV=production bundle exec rake mastodon:setup

# 7. Systemd units (upstream ships three: mastodon-web, mastodon-sidekiq, mastodon-streaming)
# Copy from dist/ in the repo — mastodon-*.service files
```

Full walkthrough (including nginx vhost, LE cert, systemd unit files) at <https://docs.joinmastodon.org/admin/install/>. Expect 1–2 hours end-to-end for a first-time bare-metal install.

## Data layout

### Docker compose bind mounts

| Host path | Container path | Content |
|---|---|---|
| `./postgres14/` | `/var/lib/postgresql/data` | Postgres data. |
| `./redis/` | `/data` | Redis AOF. |
| `./public/system/` | `/mastodon/public/system` | Uploaded media (if `S3_ENABLED=false`). |
| `./elasticsearch/` (optional) | `/usr/share/elasticsearch/data` | ES indices. |

### Bare-metal

| Path | Content |
|---|---|
| `/home/mastodon/live/` | Rails app |
| `/home/mastodon/live/public/system/` | Uploaded media |
| `/var/lib/postgresql/` | Postgres |
| `/var/log/nginx/` | Reverse-proxy logs |

## Upgrade procedure

### Docker

```bash
cd /opt/mastodon

# 1. Back up Postgres + .env.production + public/system (if using local storage)
sudo docker compose exec db pg_dump -U postgres mastodon_production > backup-$(date +%F).sql
sudo cp .env.production .env.production.bak-$(date +%F)

# 2. Read the release notes at https://github.com/mastodon/mastodon/releases

# 3. Pin the new version in docker-compose.yml
#    `image: ghcr.io/mastodon/mastodon:vX.Y.Z` (and same for mastodon-streaming)

# 4. Pull + migrate + up
sudo docker compose pull
sudo docker compose run --rm web bundle exec rake db:migrate
sudo docker compose up -d

# 5. Verify
sudo docker compose logs -f web
curl -I https://<domain>/api/v1/instance
```

### Bare-metal

```bash
sudo su - mastodon
cd ~/live
git fetch --tags
git checkout vX.Y.Z
bundle install
yarn install --pure-lockfile
RAILS_ENV=production bundle exec rake db:migrate
RAILS_ENV=production bundle exec rake assets:precompile
exit
sudo systemctl restart mastodon-web mastodon-sidekiq mastodon-streaming
```

**Cross-major upgrades sometimes need pre/post-deploy migrations.** Release notes list them. Common pattern: migrate with old code running → switch code → migrate remainder.

## `tootctl` — the admin CLI

All runtime admin ops go through `tootctl` (inside Docker: `docker compose run --rm web bin/tootctl ...`):

```bash
# Create user + promote to owner
bin/tootctl accounts create myadmin --email me@example.com --confirmed
bin/tootctl accounts modify myadmin --role Owner

# Reset password
bin/tootctl accounts modify myadmin --reset-password

# Approve all pending signups (useful for closed registrations)
bin/tootctl accounts approve --all

# Clean up old remote media (saves disk)
bin/tootctl media remove --days 7

# Fix stuck jobs
bin/tootctl search deploy    # rebuild ES indices
```

## Gotchas

- **`LOCAL_DOMAIN` is forever.** Changing it after the instance has federated breaks every existing follow, post URL, and thread. Pick carefully at setup. Use `WEB_DOMAIN` for the case where `LOCAL_DOMAIN=example.com` but Mastodon itself runs at `mastodon.example.com` — requires WebFinger proxy on the apex.
- **Single-user mode vs open registration.** Set at setup. Single-user mode hides the signup UI entirely. Toggle later via `SINGLE_USER_MODE=true` in env.
- **Media storage on local disk grows forever.** Remote media is cached indefinitely unless you run `tootctl media remove` periodically. On any instance with federation, local disk hits 100GB+ fast. S3/R2 with lifecycle policies is the durable answer.
- **Elasticsearch is optional but single-node ES breaks on OOM.** Without `-Xms512m -Xmx512m` Java options AND `bootstrap.memory_lock=true` + `vm.max_map_count=262144` on the host, ES silently fails indexing. See the commented block in upstream's compose for the full required config.
- **Email is required for open registration.** Without working SMTP, account confirmation emails don't send and signups stay unconfirmed.
- **Federation is a huge fanout.** A single popular post triggers delivery to every follower's instance — thousands of HTTP POSTs queued in Sidekiq. Sizing Sidekiq queues (especially `push`) is operational concern #1.
- **`docker-compose.yml` has bind mounts to `./postgres14`.** The directory name has the PG version in it — if you change Postgres major (15, 16), bind-mount the new path separately and do a pg_upgrade dance. Upstream pins `postgres:14-alpine` to avoid this.
- **Mastodon's Rails config assumes `X-Forwarded-Proto: https`.** Without it, OAuth redirects break and CSRF tokens reject form submissions.
- **VAPID keys must be regenerated if lost.** Users' web push subscriptions tie to the specific VAPID pubkey. Rotating it silently breaks all mobile web push notifications.
- **Postgres `shm_size: 256mb` matters.** Upstream compose sets this. On high-throughput instances, bump to 512mb+ or `pg_stat_statements` queries start failing.
- **Sidekiq web UI is exposed at `/sidekiq` but requires admin login.** Useful for debugging queue backlogs; don't expose to the public internet without an additional auth layer.
- **Registrations-API rate limits are easy to hit in dev.** `MAX_SESSION_ACTIVATIONS`, `IP_RETENTION_PERIOD`, and signup-captcha config all interact — check the `.env.production.sample` comments.
- **Image processing memory spikes.** ImageMagick on large uploads can spike RSS to 2GB+. Tune `MAX_ATTACHMENT_SIZE` to prevent accidental OOM.

## Links

- Upstream repo: <https://github.com/mastodon/mastodon>
- Docs: <https://docs.joinmastodon.org/>
- Install guide: <https://docs.joinmastodon.org/admin/install/>
- Config reference: <https://docs.joinmastodon.org/admin/config/>
- Scaling: <https://docs.joinmastodon.org/admin/scaling/>
- Backup/restore: <https://docs.joinmastodon.org/admin/backups/>
- `tootctl` reference: <https://docs.joinmastodon.org/admin/tootctl/>
- Releases: <https://github.com/mastodon/mastodon/releases>
- Container image: <https://github.com/mastodon/mastodon/pkgs/container/mastodon>
