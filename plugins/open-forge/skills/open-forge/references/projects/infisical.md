---
name: infisical-project
description: Infisical recipe for open-forge. MIT + Enterprise-dual-licensed open-source secrets management platform — central place to manage env vars + API keys + database credentials + certificates, with native integrations for Kubernetes (operator), GitHub/GitLab Actions, AWS Secrets Manager sync, Terraform, Vercel, Netlify, etc. CLI (`infisical run`) injects secrets at process start. SDK-based fetching for Node/Python/Go/Java/Ruby/C#. Stack = Node.js backend + Postgres 14 + Redis. Positioned as an open-source HashiCorp Vault alternative with a sharper DX. Covers the official `docker-compose.prod.yml`, the `.env.example` secrets (ENCRYPTION_KEY, AUTH_SECRET), SMTP/SSO/SAML/SCIM/OAuth setup, and the Helm chart path for K8s.
---

# Infisical

MIT + Enterprise-dual-licensed open-source secrets management platform. Upstream: <https://github.com/Infisical/infisical>. Docs: <https://infisical.com/docs>. Website: <https://infisical.com>. Hosted: <https://app.infisical.com>.

Positioning: "open-source HashiCorp Vault, but DX-first." One dashboard for env vars / API keys / DB creds / certificates; strong integrations story (K8s Operator, GitHub / GitLab / CircleCI / Jenkins Actions, AWS / GCP / Azure secret-manager sync, Terraform, Vercel, Netlify, Railway, Fly, Heroku).

## What you actually use

1. **Sign up / self-host** → create a project → add environments (dev/staging/prod) → add secrets per environment.
2. **In your app**, either:
   - **CLI injection** — `infisical run -- npm start` reads secrets from Infisical and injects as env vars at process start (no code changes).
   - **SDK fetch** — `@infisical/sdk` / `infisical-python` / `infisical-go` / `infisical-java` / etc.
   - **K8s Operator** — syncs Infisical secrets into K8s Secrets automatically.
   - **Sync to another secret store** — AWS Secrets Manager / GCP Secret Manager / Parameter Store / Vault.
3. Rotate secrets / audit logs / PR-review secret changes via the UI.

## Features (OSS vs Enterprise split)

**Free / self-host OSS:**

- Projects + environments + secrets + folders.
- Secret versioning + history.
- CLI + SDKs.
- K8s Operator + native integrations (GitHub, GitLab, Vercel, Netlify, Heroku, Fly, Railway, etc.).
- PIT (point-in-time) recovery.
- Webhook notifications.
- Email-password auth + OAuth (Google, GitHub, GitLab).
- Machine identities (service-to-service auth).
- Audit logs (limited retention).
- Secret approval workflows.
- Dynamic secrets (limited).

**Enterprise / paid:**

- SAML SSO + SCIM provisioning.
- RBAC with custom roles.
- IP allowlisting.
- Extended audit log retention.
- PKI / certificate management features.
- Native secret rotation integrations.
- SLA + support.

License: MIT for the platform, with some Enterprise-only code paths.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (`docker-compose.prod.yml`) | <https://github.com/Infisical/infisical/blob/main/docker-compose.prod.yml> | ✅ Recommended | Standard self-host. |
| Kubernetes (Helm chart) | <https://dl.cloudsmith.io/public/infisical/helm-charts> | ✅ | Clusters. |
| AWS (CloudFormation / ECS) | <https://infisical.com/docs/self-hosting/deployment-options/aws-ec2> | ✅ | AWS users. |
| GCP | <https://infisical.com/docs/self-hosting/deployment-options/gcp-cloud-run> | ✅ | Cloud Run. |
| Azure | <https://infisical.com/docs/self-hosting/deployment-options/azure-app-services> | ✅ | App Services. |
| DigitalOcean 1-click | <https://infisical.com/docs/self-hosting/deployment-options/digital-ocean-marketplace> | ✅ | DO users. |
| Infisical Cloud (hosted) | <https://app.infisical.com> | ✅ (free + paid) | Don't self-host. |

Image: `infisical/infisical:latest`. Pin a version in prod (e.g. `infisical/infisical:v0.80.0`).

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-compose` / `kubernetes-helm` / `aws-ecs` / `gcp-cloud-run` / `azure-app-services` / `digitalocean-1click` | Drives section. |
| dns | "Site URL?" | e.g. `https://infisical.example.com` | `SITE_URL` env var — emails + OAuth callbacks rely on this. |
| ports | "HTTP port?" | Default `80` in compose (maps to internal 8080) | Map via reverse proxy. |
| secrets | "ENCRYPTION_KEY?" | 16-byte hex (`openssl rand -hex 16`) | Encrypts secret values at rest. NEVER ROTATE (see gotchas). |
| secrets | "AUTH_SECRET?" | 32-byte base64 (`openssl rand -base64 32`) | JWT signing key for sessions. |
| db | "Postgres password?" | Random | `POSTGRES_PASSWORD` — part of `DB_CONNECTION_URI`. |
| smtp | "SMTP credentials?" | Multi-field | Required for password reset, team invites. |
| oauth | "OAuth providers?" | `AskUserQuestion`: `github` / `google` / `gitlab` / `none` | Per-provider client ID + secret. |
| sso | "SAML SSO / SCIM?" | Boolean | Enterprise only. |
| tls | "Reverse proxy?" | `AskUserQuestion`: `caddy` / `traefik` / `nginx` / `none` | Production needs TLS. |

## Install — Docker Compose (`docker-compose.prod.yml`)

Upstream production compose (verbatim — short file):

```yaml
services:
  backend:
    container_name: infisical-backend
    restart: unless-stopped
    depends_on:
      db:    { condition: service_healthy }
      redis: { condition: service_started }
    image: infisical/infisical:latest       # ⚠️ PIN THIS
    pull_policy: always
    env_file: .env
    ports:
      - 80:8080
    environment:
      - NODE_ENV=production
    networks: [infisical]

  redis:
    image: redis
    container_name: infisical-dev-redis
    env_file: .env
    restart: always
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
    networks: [infisical]
    volumes:
      - redis_data:/data

  db:
    container_name: infisical-db
    image: postgres:14-alpine
    restart: always
    env_file: .env
    volumes:
      - pg_data:/var/lib/postgresql/data
    networks: [infisical]
    healthcheck:
      test: "pg_isready --username=${POSTGRES_USER} && psql --username=${POSTGRES_USER} --list"
      interval: 5s
      timeout: 10s
      retries: 10

volumes:
  pg_data:     { driver: local }
  redis_data:  { driver: local }

networks:
  infisical:
```

Bring up:

```bash
mkdir ~/infisical && cd ~/infisical
curl -fsSLO https://raw.githubusercontent.com/Infisical/infisical/main/docker-compose.prod.yml
mv docker-compose.prod.yml docker-compose.yml
curl -fsSLO https://raw.githubusercontent.com/Infisical/infisical/main/.env.example
mv .env.example .env
# Edit .env — see below
docker compose up -d
# → http://<host>/
```

## `.env` — critical settings

From `.env.example` (abbreviated to essentials):

```bash
# MUST ROTATE — the sample values in .env.example are public
ENCRYPTION_KEY=<openssl rand -hex 16>
AUTH_SECRET=<openssl rand -base64 32>

# Postgres
POSTGRES_PASSWORD=<random>
POSTGRES_USER=infisical
POSTGRES_DB=infisical
DB_CONNECTION_URI=postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}

# Redis
REDIS_URL=redis://redis:6379

# Public URL — MUST match how users access the instance
SITE_URL=https://infisical.example.com

# SMTP (required for invites / password reset)
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_FROM_ADDRESS=infisical@example.com
SMTP_FROM_NAME=Infisical
SMTP_USERNAME=infisical
SMTP_PASSWORD=<smtp-pwd>

# OAuth (optional — one per provider you enable)
CLIENT_ID_GITHUB=
CLIENT_SECRET_GITHUB=
CLIENT_ID_GOOGLE=
CLIENT_SECRET_GOOGLE=
CLIENT_ID_GITLAB=
CLIENT_SECRET_GITLAB=
```

⚠️ **The sample `ENCRYPTION_KEY=f13dbc92aaaf86fa7cb0ed8ac3265f47` and `AUTH_SECRET=5lrMXKKWCVocS/uerPsl7V+TX/aaUaI7iDkgl3tSmLE=` in upstream `.env.example` are PUBLIC values.** Do NOT use them for production. Generate fresh.

Full `.env` reference: <https://github.com/Infisical/infisical/blob/main/.env.example> (142 lines — includes all optional OAuth providers, SAML, SCIM, telemetry toggles).

## Reverse proxy (Caddy example)

```caddy
infisical.example.com {
    reverse_proxy backend:8080
}
```

Set `SITE_URL=https://infisical.example.com` so OAuth callbacks and email links work.

## Install — Helm (Kubernetes)

```bash
helm repo add infisical 'https://dl.cloudsmith.io/public/infisical/helm-charts/helm/charts/'
helm repo update
helm install infisical infisical/infisical-standalone \
  --namespace infisical --create-namespace \
  --values values.yaml
```

See <https://infisical.com/docs/self-hosting/deployment-options/kubernetes-helm> for `values.yaml` reference.

## First-run setup

1. Open `https://infisical.example.com/` → sign up → the first account becomes org admin.
2. Create an organization → create a project → add environments (e.g. `dev`, `staging`, `prod`).
3. Add secrets via the UI, or push from an existing `.env` file: `infisical secrets set --path / --env dev $(cat .env)`.
4. Install the CLI locally:
   ```bash
   brew install infisical/get-cli/infisical        # macOS
   # OR
   curl -1sLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.deb.sh' | sudo -E bash
   sudo apt install infisical
   ```
5. Authenticate: `infisical login --domain https://infisical.example.com`.
6. Use in your app:
   ```bash
   infisical run --projectId <id> --env dev -- npm start
   ```

## K8s Operator (secret sync to K8s Secrets)

```bash
helm repo add infisical-helm-charts 'https://dl.cloudsmith.io/public/infisical/helm-charts/helm/charts/'
helm install infisical-operator infisical-helm-charts/secrets-operator \
  --namespace infisical-operator --create-namespace
```

Then create an `InfisicalSecret` CR pointing at your self-hosted Infisical URL + project + environment → operator syncs values into a named K8s `Secret`. See <https://infisical.com/docs/integrations/platforms/kubernetes>.

## Integrations story

Built-in "push to" targets:

- AWS Secrets Manager / Parameter Store
- GCP Secret Manager
- Azure Key Vault
- Vault
- GitHub Actions / GitLab CI / CircleCI
- Vercel / Netlify / Railway / Heroku / Fly / Cloudflare Workers / Render / Supabase
- Terraform Cloud variables

Set up in UI: **Project → Integrations** → pick target → authenticate → map env → scheduled or manual sync.

## Data layout

| Volume | Content |
|---|---|
| `pg_data:/var/lib/postgresql/data` | Organizations, projects, environments, secrets (ENCRYPTED at rest w/ `ENCRYPTION_KEY`), audit logs, users |
| `redis_data:/data` | Cache, session store, job queues |

**Backup priority:**

1. **Postgres** (`pg_dump`) — everything. Without it, your secrets are gone.
2. **`ENCRYPTION_KEY`** — without it, the Postgres data is unreadable ciphertext. Store in a SEPARATE secret manager / safe.
3. Redis — rebuildable cache; don't bother.

## Upgrade procedure

```bash
# Pin a specific version — DON'T use :latest blindly
docker compose pull
docker compose up -d
docker compose logs -f backend
```

Release notes: <https://github.com/Infisical/infisical/releases>. Backend runs DB migrations automatically on startup.

## Gotchas

- **`ENCRYPTION_KEY` is one-way.** Rotating it requires decrypting all secrets with the old key and re-encrypting with the new — a supported but non-trivial migration (`infisical migration rotate-encryption-key`). Losing the key = all stored secrets are unrecoverable gibberish. Back it up OFFLINE.
- **The sample `ENCRYPTION_KEY` + `AUTH_SECRET` in `.env.example` are PUBLIC.** Many self-hosters leave them default by accident — that makes your entire secrets DB decryptable by anyone who grabs a Postgres dump. Generate fresh before first boot.
- **`latest` tag changes often.** Pin to a version in `docker-compose.yml`. Upgrading across major versions may require a database migration (usually automatic, but read release notes).
- **`SITE_URL` must match user-facing URL EXACTLY.** OAuth callbacks, email links, SAML AssertionConsumerService — all use it. Mismatch = broken login.
- **Redis has `ALLOW_EMPTY_PASSWORD=yes`** in default compose — fine if Redis is on an internal network. Expose Redis port externally = full compromise.
- **SSO / SAML / SCIM / RBAC / IP allowlisting are Enterprise-only.** OSS has OAuth (GitHub/Google/GitLab) + email/password. For true enterprise auth, pay for Enterprise OR put Infisical behind Authelia/Authentik ForwardAuth.
- **Audit log retention is limited in OSS.** For compliance-heavy deploys, ship audit logs externally (webhook → SIEM, or pay for Enterprise retention).
- **CLI caches secrets locally** in memory during `infisical run` — child process sees env vars, Infisical doesn't. Secrets never hit disk (unless the child process logs them).
- **SDK fetching is network-dependent.** If Infisical goes down mid-deploy, services using SDKs fail. CLI-injected env vars at process start = no runtime dependency. Tradeoff: CLI-injected = stale on change; SDK = live.
- **K8s Operator** syncs on a schedule (default 15 min). For real-time sync on secret change, you need to pair with webhook triggers or reduce poll interval.
- **Machine Identities** (service-to-service auth) replaced the older "service tokens" — migrate if you're still using tokens.
- **Dynamic secrets** (ephemeral credentials for AWS/GCP/Azure/DBs) are OSS but marked "beta" in docs. Vault is more mature for this specific use case.
- **Smtp setup** is the #1 hang on first-run setup — test with a real SMTP account (SendGrid / Mailgun / Postmark / SES / your own Postfix). Gmail "allow less secure apps" is gone; use app passwords.
- **OAuth provider setup** requires registering your self-hosted URL as callback — per provider. `https://infisical.example.com/api/v1/sso/redirect/google` etc.
- **Postgres version pinned to 14** in upstream compose. 15 / 16 / 17 should work but aren't officially tested. Safer to stay on 14.
- **Redis is required** for rate-limiting, background jobs, and session store. Not optional.
- **Helm chart uses `infisical-standalone`** (all-in-one pod) by default. For production K8s, split: `infisical-backend` + external managed Postgres + external Redis.
- **Audit log performance** — long-retention + heavy query volume = Postgres hot spot. For high-traffic orgs, export logs to external storage.
- **vs Vault**: Vault has deeper dynamic secrets + policy engine + PKI + transit (encryption-as-a-service). Infisical has cleaner UX + app-dev-focused integrations. If you need Vault's feature surface, use Vault.
- **vs Doppler / 1Password Secrets Automation**: similar feature set; Infisical is the self-hostable open-source one.

## Links

- Upstream repo: <https://github.com/Infisical/infisical>
- Docs: <https://infisical.com/docs>
- Self-hosting docs: <https://infisical.com/docs/self-hosting/overview>
- Docker Compose install: <https://infisical.com/docs/self-hosting/deployment-options/standalone>
- Kubernetes Helm install: <https://infisical.com/docs/self-hosting/deployment-options/kubernetes-helm>
- Reference `.env.example`: <https://github.com/Infisical/infisical/blob/main/.env.example>
- Configuration reference: <https://infisical.com/docs/self-hosting/configuration/envars>
- Infisical CLI: <https://infisical.com/docs/cli/overview>
- K8s Operator: <https://infisical.com/docs/integrations/platforms/kubernetes>
- Releases: <https://github.com/Infisical/infisical/releases>
- Infisical Cloud: <https://app.infisical.com>
- Slack: <https://infisical.com/slack>
- Status: <https://status.infisical.com>
- Pricing (Enterprise feature gates): <https://infisical.com/pricing>
