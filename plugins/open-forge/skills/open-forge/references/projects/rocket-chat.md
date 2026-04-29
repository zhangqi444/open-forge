---
name: rocket-chat-project
description: Rocket.Chat recipe for open-forge. MIT-licensed team chat platform (Slack/Teams alternative) with channels, DMs, video/voice calls, federation, livechat, mobile + desktop apps. Meteor/Node.js server backed by MongoDB with replica set. Upstream pivoted its compose location — the original `RocketChat/Docker.Official.Image` compose is deprecated in favor of `RocketChat/rocketchat-compose`. Covers the new compose stack (Rocket.Chat + MongoDB + Traefik + NATS + Prometheus), Snap install, minimal MongoDB-replica-set setup, and the Bitnami-MongoDB-migration footgun.
---

# Rocket.Chat

MIT-licensed team chat server, developed in JavaScript on the Meteor framework. Upstream: <https://github.com/RocketChat/Rocket.Chat>. Docs: <https://docs.rocket.chat/>.

Primary features: channels, DMs, threads, E2E encryption (opt-in), file sharing, LDAP/OIDC/SAML auth, federation (native + Matrix bridge), voice + video calls (WebRTC + Jitsi), livechat, LDAP/OIDC/SAML, desktop + mobile apps, bot integrations.

**MongoDB replica set is mandatory.** Rocket.Chat ≥ 5.0 uses Meteor's change streams, which require MongoDB replica-set mode. Single-node Mongo without `rs.initiate()` = Rocket.Chat won't start.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| `rocketchat-compose` (new official) | <https://github.com/RocketChat/rocketchat-compose> | ✅ Recommended | The current upstream-blessed Compose stack. Includes Traefik, MongoDB official, NATS, Prometheus, Grafana. |
| `Docker.Official.Image` compose (legacy) | <https://github.com/RocketChat/Docker.Official.Image> | ⚠️ **Deprecated** | Old stack using Bitnami MongoDB. Upstream is migrating people OFF this — the current compose shows a deprecation warning and fails unless `DEPRECATED_COMPOSE_ACK=1` is set. |
| Snap (`snap install rocketchat-server`) | <https://snapcraft.io/rocketchat-server> | ✅ | Single-box Linux install. Has built-in reverse proxy + Let's Encrypt. |
| Kubernetes Helm | <https://github.com/RocketChat/helm-charts> | ✅ | Production multi-node. |
| Launchpad (managed K8s) | <https://docs.rocket.chat/docs/deploy-with-launchpad> | ✅ | Upstream-hosted managed Kubernetes deploy. |
| Manual Docker image (`rocketchat/rocket.chat`) | <https://hub.docker.com/r/rocketchat/rocket.chat> | ✅ | DIY compose / orchestration. |
| Air-gapped | <https://docs.rocket.chat/docs/rocketchat-air-gapped-deployment> | ✅ | Isolated networks. |
| Cloud (managed) | <https://www.rocket.chat/cloud> | ✅ | Managed SaaS (paid). |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion` | Drives section. |
| preflight | "Rocket.Chat version?" | Free-text, check <https://github.com/RocketChat/Rocket.Chat/releases> for current LTS | Set as `RELEASE` in `.env`. |
| domain | "Public domain?" | Free-text | `DOMAIN` for Traefik; also set as `ROOT_URL` env so client links resolve correctly. |
| tls | "Let's Encrypt email?" | Free-text | Required if using included Traefik with `le` resolver. |
| db | "MongoDB version?" | Default `8.2` | `MONGODB_VERSION` in `.env`. Replica-set bootstrapping is handled by compose. |
| admin | "First admin username/email/password?" | Free-text | Injected via `SETUP_WIZARD_*` env vars (optional); otherwise set interactively on first visit. |
| federation | "Enable Matrix federation?" | Boolean | Adds a Synapse bridge via the federation-sidecar image; out-of-scope here but documented upstream. |

## Install — `rocketchat-compose` (new upstream, recommended)

### 1. Clone the upstream repo

```bash
cd /opt
git clone --depth 1 https://github.com/RocketChat/rocketchat-compose.git
cd rocketchat-compose
cp .env.example .env
```

### 2. Edit `.env`

Key vars (many more in the example file):

```bash
RELEASE=8.0.1              # pin an exact version — check releases page
IMAGE=registry.rocket.chat/rocketchat/rocket.chat
MONGODB_VERSION=8.2
DOMAIN=chat.example.com
ROOT_URL=https://chat.example.com
LETSENCRYPT_EMAIL=admin@example.com
METRICS_PORT=9458
HOST_PORT=3000
BIND_IP=0.0.0.0

# Grafana (for monitoring profile)
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=<change-me>
```

### 3. Bring up the full recommended stack

Upstream's "recommended stack" is a composition of several compose files:

```bash
docker compose \
  -f compose.monitoring.yml \
  -f compose.traefik.yml \
  -f compose.database.yml \
  -f compose.yml \
  -f docker.yml \
  up -d
```

Alternatively, for a minimal setup without Traefik / Prometheus:

```bash
docker compose -f compose.database.yml -f compose.yml -f docker.yml up -d
```

The `database` file initializes the MongoDB replica set (`rs.initiate`) automatically.

### 4. First admin

Browse to `https://chat.example.com`. The first visit runs the Setup Wizard — create the admin account there.

To skip interactive setup (e.g. for reproducible deploys), add these env vars to `.env` before first boot:

```bash
OVERWRITE_SETTING_Show_Setup_Wizard=completed
ADMIN_USERNAME=admin
ADMIN_EMAIL=admin@example.com
ADMIN_PASS=<strong-random>
```

## Install — Legacy compose (deprecated, don't use for new installs)

For reference only. The old compose at `RocketChat/Docker.Official.Image` now fails unless you acknowledge deprecation:

```bash
export DEPRECATED_COMPOSE_ACK=1
docker compose up -d
```

### ⚠️ Bitnami MongoDB migration

Bitnami's free MongoDB images were [discontinued](https://forums.rocket.chat/t/action-required-docker-compose-moving-from-bitnami-to-official-mongodb-image/22693) in mid-2025. If you're on an older Rocket.Chat install using `bitnami/mongodb`, migrate to the official `mongodb/mongodb-community-server` image BEFORE Bitnami pulls the `latest` tag. Upstream's migration post is linked in `rocketchat-compose/README.md`.

The new stack uses:

```yaml
mongodb:
  image: mongodb/mongodb-community-server:${MONGODB_VERSION:-8.2}-ubi8
```

## Install — Snap (single-box)

```bash
sudo snap install rocketchat-server
sudo snap set rocketchat-server hostname=chat.example.com
sudo rocketchat-server.initcaddy   # configures Caddy reverse proxy + Let's Encrypt
```

The snap bundles MongoDB, Node, and a reverse proxy. Updates are auto-applied. Good for dev / small teams, less flexible than Docker for multi-instance / federation.

## Install — Kubernetes (Helm)

```bash
helm repo add rocketchat https://rocketchat.github.io/helm-charts
helm repo update
helm install rocketchat rocketchat/rocketchat \
  --namespace rocketchat --create-namespace \
  --set host=chat.example.com \
  --set mongodb.auth.rootPassword=<strong> \
  --set mongodb.replicaCount=3
```

Full values reference at <https://github.com/RocketChat/helm-charts/tree/master/rocketchat>.

## Reverse proxy (if not using included Traefik)

```caddy
chat.example.com {
    reverse_proxy 127.0.0.1:3000
}
```

For nginx, WebSocket upgrade headers are critical (Meteor DDP + LiveData):

```nginx
location / {
    proxy_pass http://127.0.0.1:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forward-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forward-Proto http;
    proxy_set_header X-Nginx-Proxy true;
    proxy_redirect off;
    client_max_body_size 200M;  # for large file uploads
}
```

## Data layout

| Volume | Content |
|---|---|
| `mongodb_data` (or `rocketchat-compose_mongodb_data_*`) | MongoDB data dir. The whole workspace lives here. |
| File uploads default | Stored inside MongoDB via GridFS UNLESS you configure S3/FileSystem in Admin UI → Files. |
| Grafana/Prometheus data (if monitoring stack enabled) | Metrics history. Not user data. |

**Backup = `mongodump` the rocketchat DB while the replica set is up:**

```bash
docker compose exec mongodb mongodump --db=rocketchat --out=/tmp/dump
docker cp $(docker compose ps -q mongodb):/tmp/dump ./mongo-backup-$(date +%F)
```

Restore:

```bash
docker cp mongo-backup-YYYY-MM-DD $(docker compose ps -q mongodb):/tmp/dump
docker compose exec mongodb mongorestore --db=rocketchat /tmp/dump/rocketchat
```

For large installs with GridFS uploads in MongoDB, backups get huge. Migrate uploads to S3 via **Admin → Files → Storage Type: AmazonS3** before data grows unmanageable.

## Configuration

Most settings live in the in-app **Admin → General/Accounts/Message/Livechat/...** UI. Env vars can override them with `OVERWRITE_SETTING_<SettingName>=<value>`:

| Env pattern | Purpose |
|---|---|
| `ROOT_URL` | Canonical URL; must match what users type. Wrong value → failed logins, broken avatar URLs. |
| `PORT` | App bind port (default 3000). |
| `MONGO_URL` | Full MongoDB DSN w/ replica-set param (`?replicaSet=rs0`). |
| `MONGO_OPLOG_URL` | Oplog DSN for real-time updates (required for Meteor). |
| `OVERWRITE_SETTING_*` | Override any admin UI setting. Useful for reproducible deploys. |
| `ADMIN_USERNAME` / `ADMIN_EMAIL` / `ADMIN_PASS` | One-shot admin seed on first boot. |
| `REG_TOKEN` | Optional Cloud registration token to enable premium trial features. |
| `LICENSE_DEBUG` | Log license info. |

## Upgrade procedure

### Compose

```bash
# 1. Back up MongoDB + .env
docker compose exec mongodb mongodump --db=rocketchat --out=/tmp/pre-upgrade-dump

# 2. Read release notes — https://github.com/RocketChat/Rocket.Chat/releases
#    LTS releases get upgrade-path docs; non-LTS may have breaking changes

# 3. Bump RELEASE in .env, don't skip major versions
sed -i 's/^RELEASE=.*/RELEASE=8.1.0/' .env

# 4. Pull + recreate
docker compose pull
docker compose up -d

# 5. Watch logs — Meteor does DB migrations on boot
docker compose logs -f rocketchat | grep -E 'migration|startup complete'
```

**Do not skip major versions.** Rocket.Chat migrations are cumulative but each major version's migrations assume the previous major ran. Always upgrade one major at a time (e.g. 5.x → 6.x → 7.x → 8.x).

### MongoDB major version upgrades

MongoDB upgrades (e.g. 6.x → 7.x → 8.x) need feature-compatibility-version flips:

```bash
docker compose exec mongodb mongosh --eval \
  'db.adminCommand({setFeatureCompatibilityVersion: "8.0"})'
```

Do this BEFORE bumping `MONGODB_VERSION` in `.env`.

## Gotchas

- **Deprecated compose stack.** If you follow a 2-year-old blog post, you'll end up on `Docker.Official.Image` compose with Bitnami MongoDB. Bitnami images are EOL — migrate to `rocketchat-compose`. Upstream's current compose fails loudly if `DEPRECATED_COMPOSE_ACK=1` is not set, which is the "migrate now" hint.
- **Meteor requires MongoDB replica set.** Single-node Mongo without `rs.initiate()` breaks real-time messaging. The new compose handles this for you; DIY setups must run `rs.initiate()` manually and set `replSet` in mongod config.
- **`ROOT_URL` mismatch breaks logins.** Setting `ROOT_URL=http://localhost` and accessing via `https://chat.example.com` makes client-side redirects confused. Must match protocol + hostname exactly.
- **Oplog URL subtle bug.** If you forget `MONGO_OPLOG_URL`, Meteor falls back to polling — CPU goes up, real-time feels laggy. Include the oplog URL pointing at the `local` DB.
- **GridFS uploads blow up DB size.** Default "Local (GridFS)" stores uploads inside MongoDB. A 50GB uploads dir = 50GB in your Mongo data files + backups. Switch to S3 or FileSystem storage in **Admin → Files** early.
- **First visit = admin account.** Like many self-hosted apps, the first sign-up becomes workspace admin. Either create the account IMMEDIATELY after first boot, or firewall :3000 until you've claimed it.
- **Federation is opt-in and heavy.** Matrix federation requires a running Synapse homeserver bridged to Rocket.Chat. Don't enable unless you actually need federation — it adds a lot of moving parts.
- **Livechat SDK iframe needs same-origin or CORS tweaks.** Embedding Rocket.Chat's livechat widget on a site at a different domain requires allowlisting the domain in **Admin → Livechat → General**.
- **Push notifications go through Rocket.Chat Cloud by default.** iOS/Android push uses Rocket.Chat's gateway; for self-hosted-only push you'd need to build your own custom mobile app or use premium push gateway license.
- **Desktop app has its own update channel.** The server version and desktop app version drift — some admin features only appear on the latest desktop build.
- **Snap auto-updates.** The `rocketchat-server` snap updates automatically. Production deploys usually want to control the update window — consider switching to Docker.
- **MongoDB memory footprint matters.** Rocket.Chat + MongoDB wants ≥ 4GB RAM for small teams, ≥ 8GB for 50+ active users. MongoDB's working-set-in-RAM model punishes undersized hosts.

## Links

- Upstream repo: <https://github.com/RocketChat/Rocket.Chat>
- New compose (recommended): <https://github.com/RocketChat/rocketchat-compose>
- Deprecated compose: <https://github.com/RocketChat/Docker.Official.Image>
- Docs site: <https://docs.rocket.chat/>
- System requirements: <https://docs.rocket.chat/docs/system-requirements>
- Deploy with Docker Compose: <https://docs.rocket.chat/docs/deploy-with-docker-docker-compose>
- Deploy on Kubernetes (Helm): <https://github.com/RocketChat/helm-charts>
- Releases: <https://github.com/RocketChat/Rocket.Chat/releases>
- Bitnami-to-official MongoDB migration: <https://forums.rocket.chat/t/action-required-docker-compose-moving-from-bitnami-to-official-mongodb-image/22693>
- Docker image: <https://hub.docker.com/r/rocketchat/rocket.chat>
- Community chat (eat-your-own-dogfood): <https://open.rocket.chat/>
