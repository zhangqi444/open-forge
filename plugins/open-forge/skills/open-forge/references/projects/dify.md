---
name: dify-project
description: Dify recipe for open-forge — open-source LLMOps + AI app builder platform (github.com/langgenius/dify, ~70k★). Visual workflow builder, RAG with multiple vector-store backends (Weaviate / Qdrant / Milvus / pgvector / Elasticsearch / OpenSearch / Couchbase / Chroma / Oracle / IRIS / OceanBase / +more), agent framework, plugin marketplace, multi-tenant with role-based access. The "build a SaaS-grade AI app without writing infrastructure" project. Different category from chat UIs (Open WebUI / LibreChat) — Dify is the platform for building AI products, not just consuming them. Covers every upstream-blessed install method: Docker Compose (the canonical path; ~12 services in the default profile), Kubernetes via community Helm charts, source-code deployment, plus cloud-template flavors (Terraform on Azure / GCP / AWS, AWS CDK for EKS/ECS, Alibaba Computing Nest). Pairs with `references/runtimes/{docker,kubernetes,native}.md`.
---

# Dify

Open-source platform for building AI applications. Think "Heroku-for-AI": users define LLM workflows in a visual builder, attach datasets for RAG, expose them as web apps / APIs / chatbots, and operate them with built-in monitoring + logs + evals. Not a chat UI — Dify is the layer **above** the chat UI, where AI products get built.

The Docker Compose default deploys ~12 services: an Nginx reverse proxy, a Next.js web frontend, a Flask API server, a Celery worker + beat scheduler, Postgres, Redis, a sandbox for safe code execution, a plugin daemon, an SSRF-prevention squid proxy, a Weaviate vector database, and an init-permissions helper. Additional vector DBs / SQL DBs / object stores live behind compose profiles for users who want alternatives.

Default URL: `http://localhost/install` (port 80, served by Nginx). First user to register becomes the admin/workspace-owner.

Upstream: <https://github.com/langgenius/dify> — docs at <https://docs.dify.ai>.

## Compatible combos

Dify's deploy surface is unusually broad — Docker Compose is canonical, but there are first-class alternatives for Kubernetes (community Helm), source code, and cloud-vendor-shaped deploys (Terraform + CDK templates).

| How (runtime / install) | Module | Notes |
|---|---|---|
| **Docker Compose** (the canonical path) | `runtimes/docker.md` + project section below | What upstream's README leads with. `docker compose up -d` from `dify/docker/`. ~12 services in the default profile; 20+ more behind profiles. |
| **Kubernetes / Helm** (community-maintained) | `runtimes/kubernetes.md` + project section below | Multiple community charts (LeoQuote, BorisPolonsky, magicsong) + community YAML manifests (Winson-030, wyy-holding, Zhoneym for v1.6.0+). No first-party chart. |
| **Source code** (Python venv + Node frontend + manual services) | `runtimes/native.md` + project section below | For contributors / heavy customization. The most painful install — you run Postgres, Redis, Weaviate, the API, the worker, and the web frontend separately. |
| **Cloud Templates** | (specialized infra adapters) | Terraform on **Azure**, **GCP**; **AWS CDK** with EKS or ECS variants; **Alibaba Cloud** Computing Nest + DMS. Each is a one-shot deploy script that provisions everything. |
| **Dify Cloud** (paid hosted) | (out of scope) | <https://dify.ai> — pointer-only; open-forge is for self-hosting. |

For the **where** axis, Dify is CPU-bound (LLM inference happens at whatever provider you configure — OpenAI, Anthropic, Ollama, etc.). The compose stack runs comfortably on a 4 GB / 2 vCPU VPS for hobby use; production with real RAG needs more (vector DB indexing is RAM-hungry).

## Inputs to collect

| Phase | Prompt | Tool | Notes |
|---|---|---|---|
| preflight | "What do you want to host?" | (inferred from "Dify" in user's ask) | — |
| preflight | "Where?" | `AskUserQuestion`: AWS / Azure / Hetzner / DO / GCP / Oracle / Hostinger / BYO VPS / localhost / Kubernetes | Loads matching infra adapter |
| preflight | "How?" (dynamic from combo table) | `AskUserQuestion`: Docker Compose / Kubernetes-Helm / source / Cloud template | Filtered by infra |
| preflight (cloud-template only) | "Which cloud template?" | `AskUserQuestion`: Azure Terraform / GCP Terraform / AWS CDK (EKS) / AWS CDK (ECS) / Alibaba Computing Nest | Each cloud has its own template repo + flow |
| preflight | "Vector database?" | `AskUserQuestion`: Weaviate (default) / Qdrant / Milvus / pgvector / Chroma / Elasticsearch / OpenSearch / Other (Couchbase / Oracle / IRIS / OceanBase / SeekDB / Vastbase / pgvecto-rs / OpenGauss / MyScale / MatrixOne / TiDB) | Drives the compose profile |
| preflight | "Relational database?" | `AskUserQuestion`: Postgres (default) / MySQL | Drives `db_postgres` vs `db_mysql` profile |
| provision | "Public domain?" | Free-text or skip | Triggers `NGINX_HTTPS_ENABLED=true` + certbot service in compose, OR external reverse proxy via runtimes/native.md |
| provision | "Admin email + password?" | Free-text (sensitive) — created via the `/install` web flow on first launch | First user becomes admin/workspace-owner; no `--admin` env var |
| provision | "LLM provider(s) to wire up?" | `AskUserQuestion`: OpenAI / Anthropic / Google Gemini / Ollama / OpenRouter / Azure OpenAI / Bedrock / Multiple | Configured via the *Settings → Model Providers* UI on first login (not env vars) |
| provision | "Object storage backend?" | `AskUserQuestion`: Local filesystem (default) / S3 / Azure Blob / GCS / Aliyun OSS / Tencent COS / Volcengine TOS | For uploaded files; `STORAGE_TYPE` env var |

Project-conditional outputs:

| Recorded as | Derived from |
|---|---|
| `outputs.public_url` | `http://<host>/` (or `https://<domain>/`) |
| `outputs.install_url` | `<public_url>install` (first-launch admin-creation page) |
| `outputs.compose_dir` | `<install_dir>/dify/docker/` (where `docker-compose.yaml` lives) |
| `outputs.vector_db` | `weaviate` / `qdrant` / `milvus` / etc. |
| `outputs.relational_db` | `postgres` / `mysql` |
| `outputs.object_storage` | `local` / `s3` / `azure-blob` / `gcs` / etc. |
| `outputs.api_url` | Programmatic API base (`<public_url>v1`) — Dify exposes its own API for app integrations |

## Software-layer concerns (apply to every deployment)

### Architecture — what's actually running

The default Docker Compose profile starts ~12 services. Knowing what does what is critical for debugging:

| Service | Image | Role |
|---|---|---|
| `nginx` | `nginx:latest` | Reverse proxy. Terminates TLS (when enabled). Routes `/` → web, `/api/*` + `/console/api/*` + `/v1/*` → api. **The only externally-exposed service** (ports 80/443). |
| `web` | `langgenius/dify-web:<ver>` | Next.js frontend. Internal only. |
| `api` | `langgenius/dify-api:<ver>` | Flask REST API. Handles auth, dataset CRUD, app runtime, model-provider integrations, prompt execution. Internal port 5001. |
| `worker` | `langgenius/dify-api:<ver>` (same image, different command) | Celery worker. Async tasks: dataset indexing, embedding generation, email send, plugin execution. |
| `worker_beat` | `langgenius/dify-api:<ver>` | Celery Beat. Scheduled jobs (cleanup, scheduled workflows). |
| `db_postgres` | `postgres:15-alpine` | App database. Users, workspaces, apps, datasets, conversation history. (`db_mysql` is the alternative — pick one via compose profile.) |
| `redis` | `redis:6-alpine` | Cache + Celery broker. |
| `weaviate` | `semitechnologies/weaviate:<ver>` | Default vector DB. Stores RAG embeddings. (Replaceable — see *Vector DB choice* below.) |
| `sandbox` | `langgenius/dify-sandbox:<ver>` | Isolated container for executing user-provided Python in workflow nodes. Critical security boundary. |
| `plugin_daemon` | `langgenius/dify-plugin-daemon:<ver>` | Manages plugin lifecycle + execution + storage. Plugins are the extension mechanism for new model providers / tools / data loaders. |
| `ssrf_proxy` | `ubuntu/squid:latest` | SSRF-prevention proxy. All outbound HTTP from sandbox + plugin code routes through here, blocking access to private network ranges + cloud-metadata endpoints. |
| `init_permissions` | `busybox:latest` | One-shot job. Sets ownership/permissions on the storage volume before other services start. |

Optional (compose profiles, off by default):

- `certbot` — Let's Encrypt cert provisioning + renewal (when `NGINX_HTTPS_ENABLED=true` + `NGINX_ENABLE_CERTBOT_CHALLENGE=true`).
- Vector DB alternatives: `qdrant`, `milvus-standalone` (+ `etcd` + `minio`), `chroma`, `elasticsearch` (+ `kibana`), `opensearch` (+ `opensearch-dashboards`), `pgvector`, `pgvecto-rs`, `couchbase-server`, `oracle`, `iris`, `oceanbase`, `seekdb`, `vastbase`, `opengauss`, `myscale`, `matrixone`.
- `unstructured` — document parsing service for advanced file ingestion (PDF tables, etc.).

### Vector DB choice — the biggest decision

Dify supports many vector DBs because users have strong existing preferences. Pick once at install time; switching later requires re-indexing all datasets.

| Vector DB | When to pick |
|---|---|
| **Weaviate** (default) | Sensible default. Mature, well-supported, single-node fits in the compose stack. **Use this unless you have a specific reason not to.** |
| **Qdrant** | Better performance at scale (millions of vectors). Cleaner API for power users. |
| **Milvus** | Largest scale (billions of vectors). Adds `etcd` + `minio` to the stack — heavier resource footprint. Justified only for production-grade workloads. |
| **pgvector** / **pgvecto-rs** | When you already run Postgres and don't want a separate vector DB. Less performant than dedicated DBs at scale. |
| **Elasticsearch** / **OpenSearch** | When you want a unified text+vector search story (BM25 + dense vectors). Heavier than Weaviate; adds dashboard services. |
| **Chroma** | Lightest weight; good for very small RAG datasets and dev. |
| **Couchbase / Oracle / IRIS / OceanBase / Vastbase / OpenGauss / MyScale / MatrixOne / SeekDB / TiDB** | When the user already runs that DB for other reasons. None of these is the right default. |

The choice is set via `VECTOR_STORE=<name>` in `.env` plus the matching compose profile (`docker compose --profile <name> up -d`).

### Authentication + multi-tenant model

Dify is **multi-tenant by design** — users → workspaces → apps. Roles within a workspace: `owner` / `admin` / `editor` / `normal`. The first user to register on `/install` becomes the workspace owner.

| Mode | Set via | Behavior |
|---|---|---|
| **Open signup** | `ENABLE_REGISTER=true` (default) | Anyone can register; new users land in their own personal workspace. |
| **Invite-only** | `ENABLE_REGISTER=false` (after admin exists) | New users only via workspace invite emails. Recommended for any non-localhost deploy. |
| **OAuth / OIDC / SSO** | Various env vars + `ENABLE_SSO=true` | Federate with Google / GitHub / generic OIDC. See upstream docs. |
| **Email setup** | `MAIL_TYPE=smtp` (or `resend`) + provider env vars | Required for invites + password resets. Without it, the admin can't send invites. |

The `/install` page is **the only path to bootstrap the first admin**. Once that user exists, `/install` is dead and registration / invite flows take over. Guard the `/install` URL during initial setup — whoever hits it first owns the deployment.

### LLM provider configuration

Unlike Open WebUI / OpenClaw, Dify does **not** read provider keys from env vars. Instead:

1. Log in as the workspace owner.
2. **Settings → Model Providers**.
3. Click *Configure* on each provider you want to use.
4. Paste API keys + endpoints. Stored encrypted in Postgres.

Supported providers (extensive — the list grows constantly via the plugin marketplace): OpenAI, Anthropic, Google Gemini, Cohere, Mistral, Together, Ollama, OpenRouter, Azure OpenAI, Bedrock, Vertex AI, Hugging Face TGI, Replicate, LocalAI, vLLM, Xinference, plus many more via plugins.

To use Dify with a self-hosted Ollama (per the Ollama recipe in this skill):

- *Model Provider* → *Ollama*.
- *Base URL*: `http://host.docker.internal:11434` (compose with `extra_hosts: "host.docker.internal:host-gateway"`) or `http://<ollama-ip>:11434` for a remote Ollama.

### Object storage backend

Dify writes uploaded files (RAG documents, app icons, exported logs) somewhere. Default is local filesystem (`./volumes/app/storage/`); production should use S3-compatible:

| `STORAGE_TYPE` value | Backend |
|---|---|
| `opendal` (default for local) | Local filesystem under `./volumes/` |
| `s3` | AWS S3 (or any S3-compatible — MinIO, R2, Backblaze B2, Wasabi) |
| `azure-blob` | Azure Blob Storage |
| `google-storage` | GCS |
| `aliyun-oss` | Alibaba Cloud OSS |
| `tencent-cos` | Tencent Cloud COS |
| `volcengine-tos` | Volcengine TOS |
| `huawei-obs` | Huawei OBS |
| `baidu-obs` | Baidu OBS |
| `oci-storage` | Oracle Cloud Object Storage |
| `supabase-storage` | Supabase |

For S3, set `STORAGE_TYPE=s3` + `S3_ENDPOINT` + `S3_BUCKET_NAME` + `S3_ACCESS_KEY` + `S3_SECRET_KEY` + `S3_REGION`. For S3-compatible (MinIO, R2), include `S3_USE_PATH_STYLE=true`.

### Plugin marketplace + the plugin daemon

Dify v1.0+ introduced a plugin system. Plugins extend Dify with: new model providers, tools (web search, code interpreter, etc.), data loaders, and agentic strategies. The `plugin_daemon` service runs them isolated from the main API.

Plugins install from:

- **Marketplace** (`marketplace.dify.ai`) — official curated list. Default in self-hosted unless `MARKETPLACE_ENABLED=false`.
- **GitHub URL** — direct install from a `dify-plugin-*` repo.
- **Local upload** — `.difypkg` files dragged into the UI.

Plugins are arbitrary code with controlled API surface. Marketplace plugins go through an upstream review; GitHub-direct + local-upload are unrestricted — treat as supply-chain risk.

### Critical environment variables

Most live in `dify/docker/.env` (copy from `.env.example`). Hundreds of keys exist; the ones to watch:

| Variable | Purpose |
|---|---|
| `SECRET_KEY` | Cookies + CSRF + session signing. **Generate explicitly** with `openssl rand -base64 42`. |
| `INIT_PASSWORD` | (Optional) Pre-set the initial admin password. If unset, the admin is created via the `/install` web flow. |
| `CONSOLE_API_URL` / `CONSOLE_WEB_URL` / `SERVICE_API_URL` / `APP_API_URL` / `APP_WEB_URL` | URLs used in emails, OAuth callbacks, and CORS. **Must match your public URL** when behind a reverse proxy or on a custom domain — wrong URLs break OAuth + invite emails silently. |
| `NGINX_SERVER_NAME` | The hostname Nginx serves. `_` for any-host (default). |
| `NGINX_HTTPS_ENABLED` | `true` enables 443 + the certbot service. |
| `NGINX_ENABLE_CERTBOT_CHALLENGE` | `true` provisions Let's Encrypt certs. Pair with `CERTBOT_DOMAIN` + `CERTBOT_EMAIL`. |
| `VECTOR_STORE` | Picks the vector DB. Pair with the matching compose profile. |
| `DB_USERNAME` / `DB_PASSWORD` / `DB_DATABASE` / `DB_HOST` / `DB_PORT` | Postgres / MySQL connection. |
| `REDIS_HOST` / `REDIS_PORT` / `REDIS_PASSWORD` | Redis. |
| `STORAGE_TYPE` + S3 / Azure / GCS / etc. keys | Object storage backend (see table above). |
| `ENABLE_REGISTER` | `false` after first admin to lock down. |
| `MAIL_TYPE` + `RESEND_API_KEY` / `SMTP_*` keys | Outbound email. Required for invites + password resets. |
| `WEB_API_CORS_ALLOW_ORIGINS` / `CONSOLE_CORS_ALLOW_ORIGINS` | CORS allowlists. |
| `LOG_LEVEL` | `INFO` (default) / `DEBUG`. |
| `MIGRATION_ENABLED` | `true` (default) — auto-run DB migrations on startup. Set `false` if you want manual control. |

For the full env-var matrix, see <https://docs.dify.ai/getting-started/install-self-hosted/environments>.

### Security model

Dify takes security more seriously than most chat UIs:

- **Sandbox isolation** for user-provided Python (workflow code blocks).
- **SSRF proxy** for all sandbox + plugin outbound HTTP — blocks access to `127.0.0.1`, `169.254.0.0/16` (cloud metadata), and other RFC1918 ranges.
- **Per-workspace isolation** for users + datasets + apps.
- **Encrypted storage** of provider API keys in Postgres.

But it's not perfect:

- The `/install` URL is only protected by "first one wins" — race condition during initial setup.
- Marketplace plugins are reviewed but local-upload + GitHub-direct plugins are not.
- `WEB_API_CORS_ALLOW_ORIGINS=*` (default) is permissive.
- Default `SECRET_KEY` is empty — set explicitly.

For any non-localhost deploy:

1. Set `SECRET_KEY` explicitly.
2. Set `ENABLE_REGISTER=false` after creating the admin.
3. Configure email (`MAIL_TYPE=...`) so invites work.
4. Set `*_API_URL` / `*_WEB_URL` to match your public domain.
5. Front with TLS (built-in certbot, or external reverse proxy).
6. Lock down CORS allowlists.

### Composing with Ollama and Open WebUI

- **Ollama as a model provider** — *Settings → Model Providers → Ollama* with `Base URL: http://host.docker.internal:11434`. Make sure Ollama is bound to a reachable interface (`OLLAMA_HOST=0.0.0.0:11434`).
- **Open WebUI as a model provider** — Open WebUI exposes an OpenAI-compatible `/v1`, so configure it as the *OpenAI* provider with a custom base URL: `http://<openwebui-host>:3000/v1` + an API key generated from Open WebUI's *Settings → Account → API Keys*.
- **Dify in front of OpenClaw / Hermes** — less common; Dify is a higher level than those tools. If a user wants to chain them, expose Dify as the API and have OpenClaw/Hermes hit Dify's `/v1` (Dify exposes an OpenAI-compatible app API per published-app).

---

## Docker Compose (the canonical path)

When the user picks **any infra → Docker**. Pair with [`references/runtimes/docker.md`](../runtimes/docker.md) for host-level Docker install.

Upstream docs: <https://docs.dify.ai/getting-started/install-self-hosted/docker-compose>.

### Prereqs

- Docker Engine 19+ + Compose v2 on the host.
- 4 GB RAM minimum (8 GB+ recommended for production).
- 20 GB disk free (more if you'll ingest large RAG datasets).
- Outbound HTTPS for image pulls + your chosen LLM provider APIs.

### Install

```bash
git clone https://github.com/langgenius/dify.git
cd dify/docker

cp .env.example .env

# Generate a secure SECRET_KEY before first start — replace the .env line
sed -i.bak "s|^SECRET_KEY=.*|SECRET_KEY=$(openssl rand -base64 42)|" .env

# (Optional but recommended) Set public URLs if you have a domain
# Edit .env: NGINX_SERVER_NAME, CONSOLE_API_URL, CONSOLE_WEB_URL,
#           SERVICE_API_URL, APP_API_URL, APP_WEB_URL — all should be
#           https://your-domain when behind TLS

# Bring up the default profile (api + worker + worker_beat + web + nginx
# + db_postgres + redis + sandbox + plugin_daemon + ssrf_proxy + weaviate)
docker compose up -d

# Watch logs until everything's settled
docker compose logs -f api
```

First `docker compose up -d` pulls ~5 GB of images and takes 5–15 minutes on a fresh host. Subsequent runs use the local cache.

### Bootstrap the admin

1. Wait for `docker compose ps` to show all services as `running` (not `restarting`).
2. Open `http://<host>/install` in a browser.
3. Enter admin email + password — first user becomes workspace owner.
4. Log in, go to *Settings → Model Providers*, configure your LLM provider(s).
5. *Settings → Workspace Settings → Members* → invite team members (requires `MAIL_TYPE` configured).

### Picking a non-default vector DB

Edit `.env`:

```bash
# Pick one
VECTOR_STORE=qdrant
# or: weaviate (default) / milvus / chroma / pgvector / pgvecto-rs / elasticsearch
#     opensearch / tidb / oracle / iris / oceanbase / seekdb / vastbase
#     opengauss / myscale / matrixone / couchbase
```

Then bring up with the matching profile:

```bash
docker compose --profile qdrant up -d
# or:
docker compose --profile milvus up -d        # also starts etcd + minio
docker compose --profile elasticsearch up -d # also starts kibana
```

To switch later: stop, change `VECTOR_STORE`, switch profile, restart. **Existing datasets need re-indexing** — embeddings live in the old vector DB.

### Picking MySQL instead of Postgres

```bash
# In .env:
DB_TYPE=mysql

docker compose --profile mysql up -d
```

The default `--profile postgres` is implicit. Pick one — running both is wasteful and the API only talks to one.

### Enabling HTTPS via the built-in certbot

The compose ships a `certbot` service that handles Let's Encrypt automatically when configured:

```bash
# In .env:
NGINX_HTTPS_ENABLED=true
NGINX_SERVER_NAME=dify.example.com
NGINX_ENABLE_CERTBOT_CHALLENGE=true
CERTBOT_DOMAIN=dify.example.com
CERTBOT_EMAIL=admin@example.com

# Bring up with the certbot profile:
docker compose --profile certbot up -d
```

DNS A-record for `dify.example.com` must point at the host first (certbot uses HTTP-01 challenge by default). If you're already running a reverse proxy (Caddy, Traefik) at the edge, **skip** the built-in certbot — set `NGINX_HTTPS_ENABLED=false` and let your edge proxy terminate TLS.

### Object storage — switch from local to S3

```bash
# In .env:
STORAGE_TYPE=s3
S3_ENDPOINT=https://s3.amazonaws.com           # or your S3-compatible endpoint
S3_BUCKET_NAME=dify-storage-prod
S3_ACCESS_KEY=AKIA...
S3_SECRET_KEY=...
S3_REGION=us-east-1
# For S3-compatible (MinIO, Cloudflare R2):
S3_USE_PATH_STYLE=true

# Restart api + worker (services that touch storage):
docker compose restart api worker worker_beat
```

Existing local files are NOT auto-migrated. Before switching, sync `./volumes/app/storage/` to S3 manually (`aws s3 sync ./volumes/app/storage s3://dify-storage-prod/`).

### Updating

```bash
cd dify
git pull                                   # pull new compose + .env.example
cd docker
# Diff your .env against .env.example for new keys
diff <(sed 's/=.*//' .env.example | sort) <(sed 's/=.*//' .env | sort)

docker compose pull                        # pull new image versions
docker compose up -d                       # recreate changed services
docker compose logs -f api                 # watch migrations apply
```

DB migrations run automatically on `api` startup when `MIGRATION_ENABLED=true` (default). Watch for migration errors in the api logs.

### Lifecycle

```bash
docker compose ps                                          # what's running
docker compose logs -f <service>                           # tail one service
docker compose restart api worker worker_beat              # restart app tier (after .env changes)
docker compose down                                        # stop everything (keeps volumes)
docker compose down -v                                     # nuke volumes too — DESTRUCTIVE
docker compose exec api flask db current                   # show DB migration version
docker compose exec api flask shell                        # Python REPL with app context
docker compose exec db_postgres psql -U postgres dify      # connect to the DB
```

### Backup + restore

The state lives in:

- `./volumes/app/storage/` (local STORAGE_TYPE) or your S3 bucket.
- The `db_postgres` (or `db_mysql`) volume.
- The vector DB's volume (`./volumes/weaviate/` etc.) — though you can re-index from sources if the vector DB dies.
- The plugin daemon's volume (`./volumes/plugin_daemon/`).

A complete backup:

```bash
docker compose down

# Tar the volumes
tar czf dify-backup-$(date +%F).tgz ./volumes/

# (Optional) DB-only logical backup
docker compose up -d db_postgres
docker compose exec db_postgres pg_dump -U postgres dify > dify-db-$(date +%F).sql
docker compose down

# Bring everything back up
docker compose up -d
```

### Docker Compose-specific gotchas (Dify-only)

- **The `/install` URL is open to whoever hits it first.** During initial setup, restrict access (firewall, `127.0.0.1` bind via Nginx, NetworkPolicy) until you've registered the admin. After that, `/install` redirects to login.
- **Hundreds of `.env` keys.** Don't try to edit them all — start with `.env.example` defaults, change only what you need (`SECRET_KEY`, `*_URL`, `VECTOR_STORE`, storage). Run-time settings live in the *Settings* UI; env vars are infrastructure.
- **`SECRET_KEY` empty by default in `.env.example`.** Set it explicitly via `openssl rand -base64 42` before first launch — a randomly-regenerated key per restart logs everyone out.
- **`*_API_URL` / `*_WEB_URL` mismatches break OAuth + invite emails silently.** When behind a custom domain or reverse proxy, set ALL the URL env vars to your public hostname.
- **Vector DB switch = re-index everything.** Embeddings don't migrate. Plan for it.
- **`docker compose --profile <name>` is sticky.** Once you've started a profile, `docker compose down && docker compose up -d` (without `--profile`) brings only the default profile up; old profile services keep running unless you `docker compose down` first or include the `--profile` flag in subsequent commands. Be explicit.
- **Plugin daemon needs persistent storage.** `./volumes/plugin_daemon/` holds installed plugins + their venvs. Lose this and all plugin installs are gone.
- **`init_permissions` runs as root** to chown the storage volume to the non-root user the api container uses. Don't skip it; permissions errors are the symptom.
- **`weaviate` doesn't have CPU AVX requirements** (some vector DBs do); `qdrant` does. On older / cheaper VPSes, prefer Weaviate.
- **MySQL profile + Postgres profile can't both be active.** The API's `DB_TYPE` env var picks one.
- **`worker` and `api` share the same image.** A failure to pull `langgenius/dify-api:<ver>` breaks both.
- **`NGINX_PROXY_READ_TIMEOUT` defaults to 3600s (1h).** Long-running workflow executions or model responses near that limit will get cut off. Raise to 7200s (2h) for production agentic use.

---

## Kubernetes / Helm (community-maintained)

When the user picks **any k8s cluster → Helm or manifests**. Pair with [`references/runtimes/kubernetes.md`](../runtimes/kubernetes.md) for kubectl + Helm prereqs and Secret hygiene.

> **Verify the chart source first.** Dify upstream's README points at multiple community Helm charts and YAML manifest sets but does **not ship a first-party chart**. Confirm with the user which one they intend before installing. The most-active community charts (per upstream README) are:
>
> - [LeoQuote/dify-helm](https://github.com/LeoQuote/dify-helm)
> - [BorisPolonsky/dify-helm](https://github.com/BorisPolonsky/dify-helm)
> - [magicsong/ai-charts](https://github.com/magicsong/ai-charts)
>
> And community YAML manifests:
>
> - [Winson-030/dify-kubernetes](https://github.com/Winson-030/dify-kubernetes)
> - [wyy-holding/dify-k8s](https://github.com/wyy-holding/dify-k8s)
> - [Zhoneym/DifyAI-Kubernetes](https://github.com/Zhoneym/DifyAI-Kubernetes) — for Dify v1.6.0+

### Prereqs

- A running Kubernetes cluster with `kubectl` connected.
- Helm v3.
- A default `StorageClass` (PVCs for db, redis, vector DB, plugin daemon, app storage).
- An ingress controller (nginx-ingress, Traefik, or a cloud-native one).
- Optionally: cert-manager for automated TLS.
- Per chart: review the `values.yaml` to understand the dependency graph (some charts bundle Postgres + Redis + Weaviate, some assume external).

### Install (illustrative — `BorisPolonsky/dify-helm` flavor)

```bash
helm repo add dify https://borispolonsky.github.io/dify-helm/
helm repo update

kubectl create namespace dify

# Inspect defaults before installing — value schemas drift between community charts
helm show values dify/dify > /tmp/dify-defaults.yaml

# Install — example values; adjust to match the chart's actual schema
helm upgrade --install dify dify/dify \
  --namespace dify --create-namespace \
  --set api.secretKey="$(openssl rand -base64 42)" \
  --set ingress.enabled=true \
  --set ingress.host=dify.example.com \
  --set ingress.tls.enabled=true \
  --set postgresql.enabled=true \
  --set postgresql.persistence.size=20Gi \
  --set redis.enabled=true \
  --set vectorDb.type=weaviate
```

Always `helm show values <chart> > defaults.yaml` and read it before installing. The exact `--set` keys above are illustrative — community-chart schemas vary.

### Verify + access

```bash
kubectl -n dify rollout status deploy/dify-api
kubectl -n dify rollout status deploy/dify-worker
kubectl -n dify rollout status deploy/dify-web
kubectl -n dify get pods,svc,ingress,pvc
kubectl -n dify logs deploy/dify-api -f

# Local probe before DNS lands:
kubectl -n dify port-forward svc/dify-nginx 8080:80
# → http://localhost:8080/install
```

For public exposure via Ingress, pair with cert-manager + an ingress controller. **Don't expose** the `/install` URL without an authenticated path in front during the initial-setup window — first-user-becomes-admin race condition.

### Operating

```bash
# Scale workers for higher throughput
kubectl -n dify scale deploy/dify-worker --replicas=4

# Restart api to pick up env changes
kubectl -n dify rollout restart deploy/dify-api

# Database access
kubectl -n dify exec -it sts/dify-postgresql-0 -- psql -U postgres dify

# Tail combined logs
kubectl -n dify logs -f -l app.kubernetes.io/name=dify
```

### Updating

```bash
helm repo update
helm upgrade dify dify/dify --namespace dify --reuse-values
```

DB migrations run on api startup (`MIGRATION_ENABLED=true`). For a major-version bump, **always** snapshot the DB volume before upgrading — Dify's migrations occasionally break across major versions.

### Kubernetes-specific gotchas (Dify-only)

- **No first-party chart.** Multiple community options with different value schemas. Pick one and **commit** to it — switching between charts later is painful (different naming conventions for resources / Secrets / PVCs).
- **PVC reclaim policy.** Default `Delete` reclaim wipes datasets on `helm uninstall`. For long-lived clusters, switch the StorageClass to `Retain` or take regular pg_dump + S3-storage backups.
- **Ingress + `/install` race.** Don't expose the Ingress before you've registered the admin. Either deploy with the Ingress disabled / NetworkPolicy-restricted, register admin via port-forward, then enable Ingress.
- **Vector DB sub-chart vs external.** Most community charts bundle Weaviate / Qdrant / Milvus as sub-charts. For production, prefer running the vector DB as its own dedicated deployment (or a managed service) — chart sub-deployments lag upstream and aren't sized for production load.
- **Plugin daemon needs persistent storage.** Each community chart handles this differently; verify the `pluginDaemon.persistence.*` (or equivalent) values.
- **Postgres + Redis + Weaviate sub-charts** carry separate maintenance burdens. For production, externalize: managed Postgres (RDS / Cloud SQL / Aurora), managed Redis (ElastiCache / Memorystore), Weaviate Cloud or self-hosted on a separate cluster.
- **`*_URL` env vars** still apply — set `CONSOLE_API_URL`, `CONSOLE_WEB_URL`, `SERVICE_API_URL`, `APP_API_URL`, `APP_WEB_URL` to your Ingress hostname.

---

## Cloud Templates (Terraform / CDK / Computing Nest)

Vendor-shaped one-shot deploys. Each is upstream-linked but maintained in a separate repo; verify the version + the parent docs page before running.

### Azure — Terraform (community-maintained)

Upstream's README links a Terraform module that provisions: an Azure VM (or AKS cluster) + storage + networking + the Dify services on top. Useful when the user is already in Azure and wants `terraform apply` to do everything.

```bash
git clone https://github.com/<community-author>/dify-azure-terraform   # verify the URL upstream
cd dify-azure-terraform

cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set subscription, location, sizes, domain

az login
terraform init
terraform plan
terraform apply
```

Terraform creates the Azure resources, runs the `cloud-init` script that installs Docker + clones Dify + brings up the compose stack. SSH into the VM after for any post-install config.

### GCP — Terraform (community-maintained)

Same shape as Azure: Terraform module provisions a Compute Engine VM (or GKE cluster) + Cloud SQL + GCS bucket + Cloud DNS, then bootstraps Dify on top.

```bash
git clone https://github.com/<community-author>/dify-gcp-terraform   # verify the URL upstream
cd dify-gcp-terraform

cp terraform.tfvars.example terraform.tfvars
# Edit: project ID, region, machine type, domain

gcloud auth application-default login
terraform init
terraform apply
```

### AWS — CDK (EKS or ECS variants)

AWS CDK templates ship two flavors:

- **EKS-based** — Dify runs as Kubernetes Deployments on EKS. Use when the user already operates EKS clusters.
- **ECS-based** — Dify runs as ECS services on Fargate. Lower ops burden than EKS; better for "just deploy it" use cases.

```bash
git clone https://github.com/<community-author>/dify-aws-cdk         # verify the URL upstream
cd dify-aws-cdk

npm install
# Edit cdk.json or app.ts — pick eks or ecs stack, set domain, instance sizes

aws sso login --profile dify-prod    # or your AWS auth flow
cdk bootstrap
cdk deploy
```

Both flavors provision: VPC + subnets, the compute layer (EKS or ECS), RDS Postgres, ElastiCache Redis, OpenSearch (vector DB), an ALB + ACM cert, S3 bucket for storage. Heavier than Docker Compose; appropriate for production-grade deploys.

### Alibaba Cloud — Computing Nest + DMS

Vendor-blessed one-click deploy from the Alibaba Cloud marketplace (Computing Nest). Browser-driven; out of open-forge's autonomous-mode scope. Recommend to users on Alibaba Cloud who want a fully-managed install path.

### Cloud-Template gotchas (Dify-only)

- **All templates lag upstream Dify by some amount.** Each is a separate repo with its own release cadence; check the template's pinned Dify version against the latest release before deploying. Production users sometimes prefer to use the template for infra + manually update the Dify version after.
- **Templates assume a "blank-slate" cloud account.** Re-running on an existing account that already has a VPC named `default` (or similar) often fails with name collisions. Either start fresh or be ready to import existing resources into Terraform/CDK state.
- **Domain + DNS prereqs.** Most templates expect the user to own the domain and add a DNS record pointing at the provisioned LB / VM after `apply`. Templates can't do this for you.
- **TLS via ACM (AWS) / Cloud DNS Authorization (GCP) / Key Vault Certs (Azure)** — each template picks one. Verify the user has the right IAM permissions before `apply`.
- **Cost differs dramatically across templates.** AWS CDK + EKS is the most expensive (~$300/mo idle); Azure + GCP + Alibaba CN are typically $50–150/mo. Surface this before the user runs `apply`.

---

## Source code deployment

For contributors hacking on Dify itself, or anyone who wants full control of the stack. Pair with [`references/runtimes/native.md`](../runtimes/native.md) for OS prereqs.

Upstream docs: <https://docs.dify.ai/getting-started/install-self-hosted/local-source-code>.

### Prereqs

- Python 3.11 (Dify pins this).
- Node.js 20+ + pnpm 9+ for the frontend.
- Postgres 14+ + Redis 6+ — running locally or external.
- A vector DB — Weaviate is the simplest local-dev option (`docker run` it standalone).
- ~10 GB disk for the venv + node_modules + repo.

### Install + run (Linux / macOS)

```bash
# Clone
git clone https://github.com/langgenius/dify.git
cd dify

# --- API + Worker ---
cd api
cp .env.example .env
# Edit .env — set DATABASE_URL, REDIS_URL, SECRET_KEY, VECTOR_STORE, etc.

python3.11 -m venv venv
source venv/bin/activate
pip install --upgrade pip wheel
pip install -r requirements.txt -r requirements-dev.txt

# Run DB migrations
flask db upgrade

# Start the API in one terminal:
flask run --host 0.0.0.0 --port 5001 --debug

# Start the worker in another terminal:
celery -A app.celery worker -P gevent -c 1 --loglevel INFO -Q dataset,generation,mail,ops_trace

# Start the worker_beat in a third terminal:
celery -A app.celery beat --loglevel INFO

cd ..

# --- Web frontend ---
cd web
cp .env.example .env.local
# Edit .env.local — set NEXT_PUBLIC_API_PREFIX=http://localhost:5001/console/api etc.

pnpm install
pnpm build         # production
pnpm start         # or `pnpm dev` for development hot-reload

cd ..

# --- Sandbox + plugin daemon + ssrf_proxy + vector DB ---
# Easiest: run these via docker-compose alongside, since they don't need source-level customization
cd docker
docker compose up -d sandbox plugin_daemon ssrf_proxy weaviate redis db_postgres
```

### Source-install gotchas (Dify-only)

- **Three terminals minimum** — api, worker, worker_beat. Frontend is a fourth. tmux / a process manager (overmind, foreman, supervisord) is the practical answer.
- **`flask db upgrade` must run after every `git pull`** — Dify ships migrations frequently. Forgetting this causes `column does not exist` errors at runtime.
- **Sandbox + plugin daemon are the most painful to run from source** — they're Go services with their own build chain. Most contributors run them via the Docker images even when developing api/worker/web from source.
- **`.env` files are split across `api/`, `web/`, and `docker/.env`.** Settings that need to match (URLs, secrets) have to be set in multiple files. Easy to drift.
- **Migration order matters across PRs.** When pulling a branch with new migrations, run `flask db upgrade` BEFORE running the new code, or you'll hit "table already exists" / "column missing" errors mid-run.
- **`pnpm dev` watches a lot of files.** Default macOS / Linux file-watcher limits are too low for the web frontend; raise `fs.inotify.max_user_watches` (Linux) or use `pnpm build && pnpm start` for non-dev work.

---

## Per-cloud / per-PaaS pointers

Dify is a CPU-bound stack — LLM inference happens at whatever provider you wire up (OpenAI, Anthropic, Ollama, etc.). The infra adapter just needs enough RAM (4 GB minimum, 8+ GB recommended) and disk for the vector DB.

| Where | Adapter | Typical setup |
|---|---|---|
| AWS Lightsail | `infra/aws/lightsail.md` | Docker Compose; `medium_3_0` (4 GB RAM) for hobby, `large_3_0` (8 GB) for real |
| AWS EC2 | `infra/aws/ec2.md` | Docker Compose on `t3.medium`/`t3.large`; OR the AWS CDK template above |
| AWS EKS / ECS | (use CDK template) | The CDK template provisions everything; alternatively, point `infra/aws/ec2.md` Helm at an existing cluster |
| Azure VM | `infra/azure/vm.md` | Docker Compose; OR the Azure Terraform template above |
| Hetzner | `infra/hetzner/cloud-cx.md` | Docker Compose on CX22 (4 GB) for hobby, CX32 (8 GB) for real |
| DigitalOcean | `infra/digitalocean/droplet.md` | Docker Compose on `s-2vcpu-4gb` (hobby) or larger |
| GCP Compute Engine | `infra/gcp/compute-engine.md` | Docker Compose; OR the GCP Terraform template above |
| Oracle Cloud (free ARM) | `infra/oracle/free-tier-arm.md` | Docker Compose on the A1.Flex 4-core / 24 GB free tier — **excellent fit** if you can get the capacity |
| Hostinger | `infra/hostinger.md` | VPS plan + Docker Compose via Hostinger Docker Manager |
| Raspberry Pi | `infra/raspberry-pi.md` | Pi 5 with 8 GB RAM works for hobby; smaller Pis are too tight |
| BYO Linux VPS | `infra/byo-vps.md` | Docker Compose |
| localhost | `infra/localhost.md` | Docker Compose for dev / personal |
| Any Kubernetes cluster | (user-provided) | Community Helm chart (BorisPolonsky / LeoQuote / magicsong) |
| **Alibaba Cloud** | (Computing Nest one-click) | The marketplace listing handles everything |
| Fly.io | (no first-party — limited fit) | Tricky — Dify wants a Postgres + Redis + vector DB and Fly's preferred pattern is single-process services. Skip unless the user really wants it. |
| Render / Railway / Northflank | (no first-party) | Possible but each requires multiple services + persistent volumes + backing DBs. Higher friction than the 12-service compose. |

**Cloud-template flavors** (Azure / GCP / AWS / Alibaba) are typically the right call for production deploys when the user is already in those clouds. Docker Compose on a VPS is the right call for hobby / staging / single-user. Helm is the right call when the user already has a Kubernetes cluster they're operating well.

---

## Verification before marking `provision` done

- All ~12 default services running: `docker compose ps` shows everything as `running` (not `restarting`).
- HTTP health: `curl -sIo /dev/null -w '%{http_code}\n' http://127.0.0.1/` returns `200` (or 302 redirect to `/install` on first launch).
- API health: `curl -s http://127.0.0.1/console/api/health` returns valid JSON.
- `/install` page loads and accepts admin credentials.
- After admin login, *Settings → Model Providers* lists at least one configured provider.
- *Studio → Apps* — create a "Hello world" chatflow, send a message, get a response. Confirms the full chain (UI → api → worker → vector DB → LLM provider → back).
- (If RAG-relevant) *Knowledge* — upload a PDF, wait for indexing, query it. Confirms vector DB + worker + embeddings.
- (If multi-user) *Workspace Settings → Members* — invite a test user, confirm the invite email arrives.

---

## Consolidated gotchas

Universal:

- **`SECRET_KEY` empty by default in `.env.example`.** Set explicitly via `openssl rand -base64 42` before first launch.
- **First user becomes admin.** Guard `/install` during initial setup window.
- **`*_API_URL` / `*_WEB_URL` env vars must match your public hostname.** Wrong values silently break OAuth, invite emails, and CORS.
- **Vector DB choice locks in the dataset format.** Switching later requires re-indexing every dataset.
- **Provider keys live in the DB, not env vars** — configured via *Settings → Model Providers* UI.
- **Email config is required for any non-localhost deploy.** Without it, invites + password resets fail silently.
- **The `/install` URL stays accessible until the first user registers.** Lock down early.
- **Hundreds of env vars.** Don't try to set them all — start with `.env.example` defaults and change only what you need.
- **Dify is multi-tenant.** A single deployment serves multiple workspaces; users → workspaces → apps. Don't conflate "deployment" with "workspace."
- **Plugin marketplace plugins ≠ first-party.** Local-upload + GitHub-direct plugins bypass the marketplace review — supply-chain risk.

Per-method gotchas live alongside each section above:

- **Docker Compose** — see *Docker Compose-specific gotchas* + `runtimes/docker.md` § *Common gotchas*.
- **Kubernetes** — see *Kubernetes-specific gotchas* + `runtimes/kubernetes.md` § *Common gotchas*.
- **Cloud Templates** — see *Cloud-Template gotchas*.
- **Source code** — see *Source-install gotchas* + `runtimes/native.md` § *Common gotchas*.

---

## TODO — verify on subsequent deployments

- **First end-to-end Docker Compose deploy** on Linux + a real domain. Validate: certbot service flow (`NGINX_HTTPS_ENABLED=true` + `NGINX_ENABLE_CERTBOT_CHALLENGE=true` + `CERTBOT_DOMAIN`), `*_API_URL` / `*_WEB_URL` configuration, OAuth callback after a domain attaches.
- **Vector DB switch end-to-end** — start on Weaviate, switch to Qdrant, observe re-indexing behavior.
- **MySQL alternative** — never validated. Verify the `--profile mysql` path works as documented.
- **Helm community charts** — verify which one is most actively maintained at first-deploy time. The recipe documents `BorisPolonsky/dify-helm` as illustrative; consider whether open-forge should standardize on one chart and pin to a specific tag.
- **AWS CDK template** (EKS + ECS variants) — never validated. Verify the current upstream-linked URL, the IAM permissions required, the cost estimate per variant.
- **Azure / GCP / Alibaba Terraform / Computing Nest templates** — same as AWS CDK; documented from upstream-linked but unvalidated.
- **S3 storage backend** — verify the local→S3 migration story (manual `aws s3 sync` works but is fragile).
- **Plugin marketplace** — verify the install flow for both marketplace + local-upload plugins; verify `MARKETPLACE_ENABLED=false` correctly disables the marketplace UI.
- **`init_permissions` service behavior** — root chown on the storage volume; verify it works on rootless Docker / Podman; verify it doesn't spuriously re-run.
- **Composing with Ollama / Open WebUI** — first-run validation: Dify in Docker Compose pointing at Ollama via `host.docker.internal`, exercise a chat round-trip + a RAG ingest.
- **Major-version migrations** — pull a 1.0 → 1.x major version at first-deploy and confirm migrations apply cleanly. Document any pre-/post-upgrade steps the upstream `RELEASE.md` references.
- **`SECRET_KEY` rotation procedure** — what happens if the user wants to rotate it post-deploy? Verify (sessions invalidated; encrypted provider keys still readable / re-readable?).
- **Backup + restore drill** — exercise the documented `tar volumes/` + `pg_dump` flow against a populated install; verify restore works on a fresh host.
- **Source-install end-to-end** — never validated. Verify the four-process layout (api + worker + worker_beat + web) + the `.env` file split + the `flask db upgrade` cadence.