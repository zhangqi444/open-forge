---
name: appsmith-project
description: Appsmith recipe for open-forge. Apache-2.0 low-code platform for building internal tools / admin panels / dashboards / CRUD apps against existing databases and APIs. Covers upstream's three recommended install methods (Docker, Kubernetes, AWS AMI), the self-contained `appsmith/appsmith-ce` Community Edition image (single container bundling MongoDB + Redis + Java + nginx + Node), plus the encryption-key semantics that matter for upgrades.
---

# Appsmith

Apache-2.0 low-code platform. Drag-and-drop UI builder + JS glue + 30+ first-class datasource connectors (Postgres, MySQL, MongoDB, REST, GraphQL, S3, Firestore, Snowflake, …). Primary use case: internal tools — dashboards, admin panels, CRUD UIs over your existing data. Upstream: <https://github.com/appsmithorg/appsmith>. Docs: <https://docs.appsmith.com/>. Cloud: <https://www.appsmith.com/>.

Two editions:

- **Community Edition (CE)** — Apache-2.0, self-host, fully featured. Image: `appsmith/appsmith-ce`. What open-forge deploys.
- **Enterprise Edition (EE)** — proprietary. Adds SSO/SAML, audit logs, granular RBAC, workflow orchestration. Image: `appsmith/appsmith-ee`. Paid license required.

This recipe targets CE.

## Stack shape

The `appsmith/appsmith-ce` image is a single container bundling:

- Spring Boot backend (Java)
- Node.js RTS (realtime) server
- MongoDB (internal — app metadata, users, workspaces)
- Redis (internal — queue, cache, pub/sub)
- nginx (terminates 80/443 inside the container, proxies to backend)

Single container = easy deploy, but it does mean you can't independently scale MongoDB/Redis without switching to the Kubernetes Helm chart that splits these out.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (single `docker run`) | <https://docs.appsmith.com/getting-started/setup/installation-guides/docker> | ✅ Recommended | The upstream-blessed install. Easiest path. |
| Docker Compose | Example in <https://github.com/appsmithorg/appsmith/blob/release/deploy/docker/docker-compose.yml> | ✅ | Version-controlled, reproducible. |
| Kubernetes (Helm) | <https://docs.appsmith.com/getting-started/setup/installation-guides/kubernetes> | ✅ | Production K8s. Chart splits Mongo/Redis into separate pods. |
| AWS AMI | <https://docs.appsmith.com/getting-started/setup/installation-guides/aws-ami> | ✅ | One-click on EC2 Marketplace. |
| DigitalOcean 1-Click | <https://marketplace.digitalocean.com/apps/appsmith> | ✅ | One-click droplet. |
| Heroku / Render / Render / Railway | Button / template repos | ⚠️ Community | Various community-maintained one-click deploys. |
| Bare-metal / source build | Contributor setup at <https://github.com/appsmithorg/appsmith/blob/release/contributions/CodeContributionsGuidelines.md> | ⚠️ | Not for production — dev setup only. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker` / `docker-compose` / `k8s-helm` / `aws-ami` / `do-1click` | Drives section. |
| preflight | "Edition?" | `AskUserQuestion`: `CE (free)` / `EE (licensed)` | Switches the image tag / Helm values. |
| storage | "Host path for `/appsmith-stacks`?" | Free-text, default `./stacks` | The persistent volume — holds Mongo data, config, logs, user uploads. |
| secrets | "Encryption password + salt?" | Auto-generate (two `openssl rand -hex 32`) | `APPSMITH_ENCRYPTION_PASSWORD` + `APPSMITH_ENCRYPTION_SALT`. **NEVER CHANGE THESE** after first boot — doing so makes existing credentials un-decryptable. |
| dns | "Public domain?" | Free-text | Required for TLS + OAuth redirect URIs. |
| tls | "TLS strategy?" | `AskUserQuestion`: `nginx built-in (Certbot)` / `reverse proxy (Caddy/Traefik)` / `skip (internal-only)` | Appsmith ships with nginx that can do Certbot, OR you can front it. |
| smtp | "SMTP host/port/user/pass/from?" | Free-text (sensitive) | For password resets, invitations, sign-up emails. `APPSMITH_MAIL_*` env vars. |
| oauth | "OAuth providers? (Google, GitHub, OIDC, …)" | Multi-select, per-provider client-id/secret | Configured via `APPSMITH_OAUTH2_*` env vars. Optional. |

## Install — Docker (upstream-recommended)

```bash
mkdir -p ~/appsmith/stacks
cd ~/appsmith

docker run -d \
  --name appsmith \
  -p 80:80 -p 443:443 \
  -v "$PWD/stacks:/appsmith-stacks" \
  -e APPSMITH_ENCRYPTION_PASSWORD="$(openssl rand -hex 32)" \
  -e APPSMITH_ENCRYPTION_SALT="$(openssl rand -hex 32)" \
  --restart unless-stopped \
  appsmith/appsmith-ce:latest
```

**Save the encryption password + salt** to a password manager immediately. Losing them after first boot means losing every stored datasource credential.

Visit `http://<host>` — the first user to sign up becomes workspace admin.

## Install — Docker Compose

Upstream's dev-oriented compose at `deploy/docker/docker-compose.yml`:

```yaml
version: "3"
services:
  appsmith:
    image: appsmith/appsmith-ce:release   # pin a specific tag in production
    container_name: appsmith
    ports:
      - "80:80"
      - "443:443"
    environment:
      APPSMITH_ENCRYPTION_PASSWORD: ${APPSMITH_ENCRYPTION_PASSWORD}
      APPSMITH_ENCRYPTION_SALT: ${APPSMITH_ENCRYPTION_SALT}
    volumes:
      - ./stacks:/appsmith-stacks
    restart: unless-stopped
```

`.env`:

```bash
APPSMITH_ENCRYPTION_PASSWORD=<openssl rand -hex 32>
APPSMITH_ENCRYPTION_SALT=<openssl rand -hex 32>
```

```bash
docker compose up -d
docker compose logs -f appsmith
```

### TLS options

**A. Built-in nginx + Certbot.** Appsmith's container includes a `nginx_app.conf` that can be populated with TLS by running:

```bash
docker exec -it appsmith appsmithctl ssl <your-domain>
```

This obtains a Let's Encrypt cert inside the container and reconfigures nginx. Requires DNS pointing at the host and ports 80/443 open.

**B. External reverse proxy (Caddy).** Bind Appsmith internally and front with Caddy:

```yaml
# compose.yaml
services:
  appsmith:
    ports:
      - "127.0.0.1:8080:80"   # only 80, no 443
    # ... rest same
```

```caddy
appsmith.example.com {
    reverse_proxy 127.0.0.1:8080
}
```

## Install — Kubernetes (Helm)

```bash
helm repo add appsmith https://helm.appsmith.com
helm repo update
helm install appsmith appsmith/appsmith \
  --namespace appsmith --create-namespace \
  --set applicationConfig.encryption.password="$(openssl rand -hex 32)" \
  --set applicationConfig.encryption.salt="$(openssl rand -hex 32)" \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=appsmith.example.com
```

The Helm chart splits MongoDB + Redis into separate pods (bitnami charts) — more scalable but more moving parts than the single-container Docker install. Full values: <https://github.com/appsmithorg/appsmith-helm>.

## Install — AWS AMI / DO 1-Click

Both are click-flow marketplace deploys that essentially run the Docker install inside a pre-baked VM. After provisioning:

- SSH in to retrieve/rotate the encryption secrets.
- Point DNS at the public IP.
- Run the `appsmithctl ssl <domain>` command to enable HTTPS.

Same upgrade path as Docker (re-pull image, restart).

## Data layout

Everything lives under `/appsmith-stacks` inside the container (host bind: `./stacks`):

| Path | Content |
|---|---|
| `./stacks/data/mongodb/` | MongoDB — apps, pages, queries, users, workspaces. |
| `./stacks/data/redis/` | Redis persistence. |
| `./stacks/data/backup/` | `appsmithctl backup` output. |
| `./stacks/configuration/docker.env` | Runtime env vars (persisted copy). |
| `./stacks/logs/` | Backend + nginx logs. |
| `./stacks/ssl/` | Certbot-managed certs (if using built-in TLS). |

**Backup = snapshot `./stacks/` while the container is running** (safe due to MongoDB's journaling + Redis RDB), OR use the built-in CLI:

```bash
docker exec -it appsmith appsmithctl backup
# → creates a timestamped archive under ./stacks/data/backup/
```

Restore with:

```bash
docker exec -it appsmith appsmithctl restore
# → interactive; picks from ./stacks/data/backup/
```

## Common env vars

Full reference: <https://docs.appsmith.com/getting-started/setup/instance-configuration>.

| Var | Purpose |
|---|---|
| `APPSMITH_ENCRYPTION_PASSWORD` | **Immutable after first boot.** Encrypts stored datasource passwords. |
| `APPSMITH_ENCRYPTION_SALT` | **Immutable after first boot.** |
| `APPSMITH_MONGODB_URI` | Override to use external MongoDB (advanced). |
| `APPSMITH_REDIS_URL` | Override to use external Redis (advanced). |
| `APPSMITH_MAIL_*` | SMTP for transactional emails. |
| `APPSMITH_OAUTH2_GOOGLE_*` / `APPSMITH_OAUTH2_GITHUB_*` / `APPSMITH_OAUTH2_OIDC_*` | OAuth providers. |
| `APPSMITH_DISABLE_TELEMETRY` | Set to `true` to opt out of anonymous usage pings. |
| `APPSMITH_ADMIN_EMAILS` | Comma-separated list of emails granted super-admin. |
| `APPSMITH_SIGNUP_DISABLED` | `true` to disable public signup after initial admin. |
| `APPSMITH_INSTANCE_NAME` | Display name on login page. |
| `APPSMITH_DISABLE_EMBEDDED_KEYCLOAK` / `APPSMITH_DISABLE_EMBEDDED_MONGODB` / `…_REDIS` | For users who bring their own Mongo/Redis/Keycloak. |

## Upgrade procedure

Upgrading is just a new image:

```bash
# 1. Back up first
docker exec -it appsmith appsmithctl backup

# 2. Read release notes
# https://github.com/appsmithorg/appsmith/releases

# 3. Pull + restart
docker compose pull
docker compose up -d
docker compose logs -f appsmith
```

Database migrations run on container start. They're idempotent and safe to run repeatedly. For major version bumps, upstream sometimes ships a manual `appsmithctl migrate` command — check the release notes.

**Before upgrading MongoDB versions inside the container** (upstream has historically bumped from 5.0 → 6.0 → 7.0), read the release notes carefully. In-place MongoDB major-version upgrades don't always "just work."

## First run — lock down signup

1. Visit `http://<host>`.
2. The first email to sign up becomes workspace admin.
3. After creating your admin account, set:
   ```yaml
   environment:
     APPSMITH_SIGNUP_DISABLED: "true"
     APPSMITH_ADMIN_EMAILS: "you@example.com,teammate@example.com"
   ```
4. Restart: `docker compose up -d --force-recreate appsmith`.

Public instances with signup enabled accumulate spam accounts within hours.

## Gotchas

- **NEVER rotate encryption password/salt after first boot.** Existing stored datasource credentials are encrypted with them; rotating leaves those credentials permanently un-decryptable. You'd have to delete every datasource config and re-enter secrets manually.
- **First signup = admin.** Lock the URL down or set `APPSMITH_ADMIN_EMAILS` + `APPSMITH_SIGNUP_DISABLED=true` immediately. Public instances without this get hijacked fast.
- **Built-in Certbot binds port 80 on the container.** That means you can't use an external reverse proxy AND the built-in TLS simultaneously — pick one.
- **The container is "fat" by design.** ~4GB image, 2GB+ RAM at idle. Not suitable for Raspberry Pi or 1GB VPS; upstream recommends 4GB RAM minimum.
- **Single container = single point of failure.** For production HA, you need the Helm chart (MongoDB replica set + Redis Sentinel).
- **Logs grow unbounded in `./stacks/logs/`.** Rotate with logrotate on the host; upstream doesn't auto-rotate.
- **Supervisor restart loop after OOM.** If Mongo gets OOM-killed on a memory-constrained host, supervisord keeps restarting it and the container looks "unhealthy forever." Give it more RAM.
- **CE ↔ EE migration is one-way.** Switching from `appsmith-ce` → `appsmith-ee` with the same `/appsmith-stacks` works. Going back isn't supported — EE adds tables CE doesn't recognize.
- **OAuth redirect URIs must match exactly.** Google / GitHub / OIDC configs fail silently if the redirect URI doesn't match the callback configured at the provider. Check `/oauth2/authorization/*` paths against the app spec.
- **Embedded MongoDB limits schema upgrade flexibility.** If you outgrow the bundled MongoDB (roughly >50 users + heavy usage), switching to external MongoDB via `APPSMITH_MONGODB_URI` is advertised but operationally painful — requires full dump/restore of the existing data.
- **`:latest` tag bites.** Use a specific version (`appsmith/appsmith-ce:v1.76.0`) in production so Watchtower/Renovate-style auto-upgrades don't surprise-break a shared-editor's workspace.
- **Telemetry is on by default.** Upstream collects anonymous usage metrics. Set `APPSMITH_DISABLE_TELEMETRY=true` to opt out.
- **"Appsmith" apps are not Docker images.** Each app you build inside Appsmith is metadata stored in MongoDB, not a deployable artifact. To "move an app to another instance," use Appsmith's **Export App** (JSON) + **Import App** flow in the web UI.
- **Private Git sync requires SSH keys.** Appsmith's Git integration for app source-of-truth requires configuring an SSH deploy key on your repo — HTTPS clone with password-in-URL is not supported.

## Links

- Upstream repo: <https://github.com/appsmithorg/appsmith>
- Docs: <https://docs.appsmith.com/>
- Docker install: <https://docs.appsmith.com/getting-started/setup/installation-guides/docker>
- Kubernetes install: <https://docs.appsmith.com/getting-started/setup/installation-guides/kubernetes>
- AWS AMI install: <https://docs.appsmith.com/getting-started/setup/installation-guides/aws-ami>
- Instance configuration: <https://docs.appsmith.com/getting-started/setup/instance-configuration>
- Helm chart: <https://github.com/appsmithorg/appsmith-helm>
- Releases: <https://github.com/appsmithorg/appsmith/releases>
- CE vs EE matrix: <https://www.appsmith.com/pricing>
- Discord: <https://discord.gg/rBTTVJp>
