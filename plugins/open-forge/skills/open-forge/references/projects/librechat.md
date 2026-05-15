---
name: librechat-project
description: LibreChat recipe for open-forge — multi-provider chat UI with deep enterprise plumbing (github.com/danny-avila/LibreChat, ~25k★). Alternative to Open WebUI; positioned for teams that want a polished ChatGPT-like UI fronting OpenAI / Anthropic / Google / Bedrock / Azure / Mistral / Groq / OpenRouter / Helicone / Portkey / any OpenAI-compatible (Ollama, vLLM, LocalAI) — all configurable per-deployment via `librechat.yaml`. Built-in features: multi-user with social logins (GitHub / Google / Discord / OIDC / SAML / Apple / Facebook), per-user balance + transactions, agents + assistants, MCP servers, file uploads with multi-strategy storage (local / S3 / Firebase), RAG via pgvector + a dedicated rag_api service, web search (Serper / SearXNG / Jina / Firecrawl), TTS/STT, prompt library, conversation bookmarks, model presets. Covers every upstream-blessed install method (verified per CLAUDE.md § *Strict doc-verification policy*): Docker Compose dev (`docker-compose.yml`), Docker Compose production (`deploy-compose.yml` with bundled Nginx + TLS), npm / source install, **first-party Helm chart** at `helm/librechat/` (Chart v2.0.3, app v0.8.6-rc1, with Bitnami MongoDB / Meilisearch / Redis / first-party rag-api as dependencies), plus upstream-published one-click deploy buttons for Railway, Zeabur, and Sealos. Pairs with `references/runtimes/{docker,native,kubernetes}.md`.
---

# LibreChat

A polished, multi-user, multi-provider chat UI in the same category as Open WebUI but with deeper enterprise / team-ops plumbing — per-user token balances, transaction logs, role-based UI customization, per-domain SSRF allowlists, and a dedicated RAG service. Default port `3080` (configurable via `PORT` in `.env`); served by a Node.js Express API + a Vite/React client behind it.

The Docker Compose default deploys 5 services: `api` (the LibreChat backend), `mongodb` (chat history + users), `meilisearch` (search), `vectordb` (pgvector for RAG embeddings), and `rag_api` (a separate Python service that processes documents into vectors). The first user to register becomes admin/owner; subsequent registrations are gated by `ALLOW_REGISTRATION=true` and (optionally) social logins.

Configuration is split:

- **`.env`** — infrastructure: ports, DB URIs, secrets, provider API keys, social-login client IDs.
- **`librechat.yaml`** — runtime: which providers + models are exposed, custom OpenAI-compatible endpoints, registration UI, balance/transaction settings, MCP servers, file-storage strategy, web search, agent capabilities, rate limits.

Upstream: <https://github.com/danny-avila/LibreChat> — docs at <https://librechat.ai/docs>.

## Compatible combos

Verified against the upstream repo + README per CLAUDE.md § *Strict doc-verification policy*. Five upstream-blessed install paths:

| How (runtime / install) | Module | Notes |
|---|---|---|
| **Docker Compose — dev** (`docker-compose.yml`) | `runtimes/docker.md` + project section below | What the upstream README leads with for first-time / dev installs. 5 services: api + mongodb + meilisearch + vectordb (pgvector) + rag_api. Default port `3080`. |
| **Docker Compose — production** (`deploy-compose.yml`) | `runtimes/docker.md` + project section below | Production-oriented variant in the same repo: adds an Nginx `client` service on ports 80/443 for SSL termination + static-content serving in front of the api. Same 5 backend services. |
| **npm / source install** | `runtimes/native.md` + project section below | Clone repo + `npm ci` + run `npm run backend` and `npm run frontend` separately. Requires Node 20+, MongoDB, Meilisearch, optionally pgvector + the rag_api service running alongside. For contributors and tightly-controlled deploys. |
| **Helm — first-party chart** (`helm/librechat/` in upstream repo) | `runtimes/kubernetes.md` + project section below | **Upstream-blessed.** Chart v2.0.3 / app v0.8.6-rc1 (verified against upstream `Chart.yaml`). Sub-charts: Bitnami MongoDB, Meilisearch, Bitnami Redis, plus the in-repo `librechat-rag-api` chart. Configurable image / ingress / persistence / autoscaling / security-context. |
| **One-click cloud deploys** (Railway, Zeabur, Sealos) | (vendor handles infra) | README ships Deploy buttons for **Railway** (referral-code link), **Zeabur**, and **Sealos**. Each provisions LibreChat + its dependencies on the chosen vendor. |

For the **where** axis, LibreChat is CPU-bound (LLM inference happens at whatever provider is configured). The compose stack runs comfortably on a 2 GB / 1 vCPU VPS for personal use; production with active RAG benefits from 4+ GB and SSD.

## Inputs to collect

| Phase | Prompt | Tool | Notes |
|---|---|---|---|
| preflight | "What do you want to host?" | (inferred from "LibreChat" in user's ask) | — |
| preflight | "Where?" | `AskUserQuestion`: AWS / Azure / Hetzner / DO / GCP / Oracle / Hostinger / BYO VPS / localhost / Kubernetes / Railway / Zeabur / Sealos | Loads matching infra adapter or the one-click deploy flow |
| preflight | "How?" (dynamic from combo) | `AskUserQuestion`: Docker Compose / one-click / npm-source / Kubernetes-Helm | — |
| preflight | "Provider(s) to wire up?" | `AskUserQuestion`: OpenAI / Anthropic / Google / Azure OpenAI / Bedrock / Mistral / Groq / OpenRouter / Helicone / Portkey / Ollama (local) / Other OpenAI-compatible / Multiple | Drives `.env` API-key vars + `librechat.yaml` `endpoints.custom` entries |
| provision | "Public domain?" | Free-text or skip | Triggers reverse proxy + cert-manager via `runtimes/native.md` (LibreChat itself doesn't terminate TLS) |
| provision | "Auth model?" | `AskUserQuestion`: Email-password only / Add social logins (GitHub / Google / Discord / OIDC / SAML / Apple / Facebook) / Restrict by domain (`allowedDomains`) | Drives `.env` social-login client IDs + `librechat.yaml` `registration` block |
| provision | "Allow registration?" | `AskUserQuestion`: Open / Closed (admin-creates-users) | `ALLOW_REGISTRATION=false` + invite flow after admin exists |
| provision | "Per-user balance enabled?" | `AskUserQuestion`: No (unlimited) / Yes (set starting balance + refill) | `librechat.yaml` `balance` block |
| provision | "File storage backend?" | `AskUserQuestion`: Local (default) / S3 / Firebase | `librechat.yaml` `fileStrategy` |
| provision | "Web search?" | `AskUserQuestion`: None / Serper / SearXNG / Brave / Jina / Firecrawl | `librechat.yaml` `webSearch` block + matching `.env` keys |
| provision | "MCP servers to wire?" | `AskUserQuestion`: None / Filesystem / Puppeteer / Custom | `librechat.yaml` `mcpServers` block |
| provision | "MEILI_MASTER_KEY?" | Free-text or generated | Required for Meilisearch auth; auto-generate with `openssl rand -hex 32` if not provided |
| provision | "JWT_SECRET / JWT_REFRESH_SECRET / CREDS_KEY / CREDS_IV?" | Auto-generated via `openssl rand -base64 32` × 4 | Treat as admin-grade |

Project-conditional outputs:

| Recorded as | Derived from |
|---|---|
| `outputs.public_url` | `http://<host>:3080/` (or `https://<domain>/`) |
| `outputs.compose_dir` | `<install_dir>/LibreChat/` (where `docker-compose.yml` + `.env` + `librechat.yaml` live) |
| `outputs.providers` | List of configured providers (`["openai", "anthropic", "groq", "ollama"]`) |
| `outputs.auth_methods` | `["email"]` / `["email", "github", "google"]` / etc. |
| `outputs.file_strategy` | `local` / `s3` / `firebase` |
| `outputs.web_search` | `none` / `serper` / `searxng` / `jina` / `firecrawl` |

## Software-layer concerns (apply to every deployment)

### Architecture — what's actually running

The Docker Compose default starts 5 services:

| Service | Image | Role |
|---|---|---|
| `api` | `registry.librechat.ai/danny-avila/librechat-dev:latest` (or `librechat:<ver>` tag) | The Express + Vite app. Serves the React client on `/` and the API on `/api/*`. Internal port `3080` (override via `PORT`). |
| `mongodb` | `mongo:8.0.x` | Document store: users, conversations, messages, presets, agents, memories. |
| `meilisearch` | `getmeili/meilisearch:v1.x` | Full-text search index over conversations + messages. Requires `MEILI_MASTER_KEY`. |
| `vectordb` | `pgvector/pgvector:0.x-pg15` | Postgres + pgvector extension. Stores RAG embeddings. |
| `rag_api` | `registry.librechat.ai/danny-avila/librechat-rag-api-dev-lite:latest` | Python service (FastAPI) that ingests documents → chunks → embeds → writes to `vectordb`. Talks to OpenAI / Ollama / your embedder of choice. |

Optional: a reverse proxy (Nginx / Caddy / Traefik) terminating TLS in front of `api`. LibreChat does not bundle one — bring your own (see `runtimes/native.md` § *Reverse proxy*).

### `.env` vs `librechat.yaml` — the split that confuses everyone

LibreChat splits config across two files:

| File | What goes here | Loaded when |
|---|---|---|
| **`.env`** | Infrastructure: ports, DB connection strings, secrets, provider API keys, social-login client IDs, debug flags | Read at process start; `docker compose up -d` re-reads it on recreate |
| **`librechat.yaml`** | Runtime: which providers + models are exposed, custom OpenAI-compatible endpoints, registration UI policy, balance/transactions, MCP servers, file-storage strategy, web search, agent capabilities, rate limits | Read at process start; some changes need a container restart, others (like model lists) can hot-reload |

Rule of thumb: secrets and host-level wiring live in `.env`; per-deployment policy + UI behavior + provider definitions live in `librechat.yaml`.

### Critical `.env` keys

`.env.example` ships with hundreds of keys. The ones to set explicitly:

| Key | Purpose |
|---|---|
| `HOST` / `PORT` | API bind. Default `0.0.0.0:3080`. |
| `MONGO_URI` | Mongo connection. Default `mongodb://mongodb:27017/LibreChat` for compose. |
| `MEILI_HOST` / `MEILI_MASTER_KEY` | Meilisearch endpoint + auth. Generate the master key with `openssl rand -hex 32`. |
| `RAG_PORT` / `RAG_API_URL` | Where the rag_api service listens. Default compose handles this. |
| `JWT_SECRET` / `JWT_REFRESH_SECRET` | Session signing. Generate with `openssl rand -base64 32`. **Rotate to log everyone out.** |
| `CREDS_KEY` / `CREDS_IV` | Used to encrypt provider API keys at rest in MongoDB. **Set explicitly and never rotate** without a documented re-key procedure (rotating breaks all stored provider creds). |
| `DOMAIN_CLIENT` / `DOMAIN_SERVER` | Public URLs used in OAuth callbacks + emails. Must match your reverse proxy's domain. |
| `ALLOW_REGISTRATION` | `true` (open) or `false` (admin-creates-users). |
| `ALLOW_EMAIL_LOGIN` / `ALLOW_SOCIAL_LOGIN` / `ALLOW_SOCIAL_REGISTRATION` | Per-method gates. |
| `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` / `GOOGLE_KEY` / `BEDROCK_AWS_*` / `AZURE_*` / `MISTRAL_API_KEY` / `GROQ_API_KEY` / `OPENROUTER_KEY` / etc. | Provider keys. |
| `GITHUB_CLIENT_ID` / `GITHUB_CLIENT_SECRET` (and Google / Discord / OIDC / Facebook / Apple / SAML equivalents) | Social-login OAuth credentials. |
| `MEILI_NO_ANALYTICS=true` | Disable Meilisearch usage telemetry. |
| `OPENAI_MODELS` / `ANTHROPIC_MODELS` / etc. | Comma-separated model allowlists. Lets you hide models without removing the provider. |
| `LIMIT_CONCURRENT_MESSAGES=true` + `CONCURRENT_MESSAGE_MAX=2` | Rate-limit per user. |
| `LIMIT_MESSAGE_IP=true` + `MESSAGE_IP_MAX=40` + `MESSAGE_IP_WINDOW=1` | Rate-limit per IP. |
| `BAN_VIOLATIONS=true` + `BAN_DURATION` + `BAN_INTERVAL` | Auto-ban abusive IPs. |
| `SEARCH=true` | Enable Meilisearch indexing. |
| `RAG_OPENAI_API_KEY` / `EMBEDDINGS_PROVIDER` / `EMBEDDINGS_MODEL` | rag_api embedder config. Defaults to OpenAI; switch to `ollama` to use a local Ollama embedder (`mxbai-embed-large` / `nomic-embed-text`). |

For the full env-var matrix, see <https://www.librechat.ai/docs/configuration/dotenv>.

### `librechat.yaml` — the rich config surface

Configuration version is required at the top (`version: 1.x.x`); upstream bumps it when the schema changes. Major sections:

| Section | What it controls |
|---|---|
| `interface` | UI branding (welcome message, ToS modal), feature toggles (file search, agents, marketplace, prompts, bookmarks), per-feature permissions |
| `registration` | Social-login providers exposed in the registration UI; `allowedDomains` for email-domain restriction |
| `endpoints.custom` | Custom OpenAI-compatible providers — Groq, Mistral, OpenRouter, Helicone, Portkey, Ollama, vLLM, LocalAI. Each entry: `name`, `apiKey`, `baseURL`, `models`, `titleConvo`, `titleModel`, optional `headers` / `dropParams` |
| `endpoints.anthropic.vertex` | Run Anthropic Claude models via Google Vertex AI (alternative to direct Anthropic API) |
| `endpoints.bedrock` | AWS Bedrock model list + inference profiles + guardrail config |
| `endpoints.assistants` / `endpoints.agents` | OpenAI Assistants + LibreChat Agents capabilities + recursion limits + citations |
| `mcpServers` | Model Context Protocol server definitions (stdio + sse + http transports). Plus `mcpSettings.allowedDomains` SSRF allowlist for remote servers. |
| `actions.allowedDomains` | OpenAPI Actions SSRF allowlist. Default blocks localhost + RFC1918 + `.internal` / `.local` TLDs. |
| `fileStrategy` | `local` / `s3` / `firebase`. New format allows per-type: `avatar`, `image`, `document`. |
| `fileConfig` | Per-endpoint file size + MIME-type limits |
| `webSearch` | Provider keys for Serper / SearXNG / Brave / Jina (rerank) / Firecrawl (scraper) |
| `speech.tts` / `speech.stt` | TTS + STT provider config |
| `rateLimits` | Per-IP + per-user limits for file uploads + conversation imports |
| `balance` | Per-user token-balance system (start balance, auto-refill rate) |
| `transactions` | Persist DB records of every API call |
| `memory` | User memory feature config (which agent stores memory; valid keys; token limits) |
| `modelSpecs` | Curated "model spec" picker — present pre-configured model+system-prompt pairs in the UI |
| `turnstile` | Cloudflare Turnstile (CAPTCHA) for registration |

For the full spec, see <https://www.librechat.ai/docs/configuration/librechat_yaml>.

### Adding a custom OpenAI-compatible provider (Ollama, vLLM, etc.)

Edit `librechat.yaml`:

```yaml
endpoints:
  custom:
    - name: 'Ollama'
      apiKey: 'ollama'                            # Ollama doesn't require a key but the field must be non-empty
      baseURL: 'http://host.docker.internal:11434/v1'
      models:
        default: ['llama3.2', 'qwen2.5', 'mistral']
        fetch: true                               # Auto-list installed models from /v1/models
      titleConvo: true
      titleModel: 'llama3.2'
      modelDisplayLabel: 'Ollama'
```

For Docker Compose, the `api` service's `extra_hosts: "host.docker.internal:host-gateway"` (which the upstream compose already sets) makes `host.docker.internal` resolve to the host gateway on Linux. Verify with `docker compose exec api curl -sf http://host.docker.internal:11434/api/tags`.

For a remote Ollama on the LAN: replace `host.docker.internal` with the IP. Make sure that Ollama is bound to a non-loopback interface (`OLLAMA_HOST=0.0.0.0:11434`).

### Multi-user + auth

LibreChat is multi-user by design. The first registered user becomes admin (gets a special role in MongoDB). Subsequent registrations follow the rules in `.env` + `librechat.yaml`:

| Mode | Set via | Behavior |
|---|---|---|
| **Open registration** | `ALLOW_REGISTRATION=true` (default in example) | Anyone can sign up via email + password |
| **Closed** | `ALLOW_REGISTRATION=false` | New users only via admin invite (admin creates accounts in MongoDB or via the soon-to-be-shipped admin UI) |
| **Domain-restricted** | `librechat.yaml` → `registration.allowedDomains: ['acme.com']` | Only users with email matching listed domains |
| **Social-only** | `ALLOW_EMAIL_LOGIN=false` + social providers configured | Force OAuth |
| **Cloudflare Turnstile gated** | `librechat.yaml` → `turnstile.siteKey` | CAPTCHA on registration |

For social logins, each provider needs:

1. Client ID + secret in `.env` (`GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET`, etc.).
2. Callback URL configured in the provider's app settings: `https://<your-domain>/oauth/<provider>/callback`.
3. Listed in `librechat.yaml` → `registration.socialLogins: [...]`.

Providers supported out of the box: GitHub, Google, Discord, generic OIDC, Facebook, Apple, SAML.

### Per-user token balance + transactions

Optional but powerful for shared deployments. In `librechat.yaml`:

```yaml
balance:
  enabled: true
  startBalance: 20000     # tokens granted to each new user
  autoRefillEnabled: true
  refillIntervalValue: 30
  refillIntervalUnit: 'days'
  refillAmount: 10000

transactions:
  enabled: true            # records every API call's token cost in MongoDB
```

When a user runs out of balance, their requests fail with a clear error. Admins can adjust balances via direct MongoDB updates (no admin UI as of upstream's docs).

### File storage strategies

| Strategy | When to pick |
|---|---|
| `local` (default) | Single-host deploys. Files live in `./images/` and `./uploads/` bind-mounts. Lose them = lose user uploads. |
| `s3` | Multi-host or production. Set `AWS_BUCKET_NAME`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `AWS_ENDPOINT_URL` (for S3-compatible). |
| `firebase` | Already on Firebase. Set `FIREBASE_*` keys in `.env`. |

Granular variant (newer):

```yaml
fileStrategy:
  avatar: 's3'
  image: 'firebase'
  document: 'local'
```

### Built-in security features

LibreChat takes security further than most chat UIs:

- **SSRF allowlists** for OpenAPI Actions (`actions.allowedDomains`) and remote MCP servers (`mcpSettings.allowedDomains`). By default, blocks `localhost`, RFC1918 ranges, and `.internal` / `.local` TLDs — explicit opt-in required for internal targets.
- **`CREDS_KEY` / `CREDS_IV`** encrypt provider API keys at rest in MongoDB.
- **`BAN_VIOLATIONS`** auto-bans abusive IPs after threshold.
- **Cloudflare Turnstile** integration for CAPTCHA-gated registration.
- **`fileSizeLimit`** + `fileLimit` + `mimeType` allowlists per endpoint.

But:

- Provider keys in MongoDB are encrypted with `CREDS_KEY` — if you leak that, all keys are exposed. Treat as admin-grade.
- The `api` service exposes `/api/*` and `/oauth/*` directly; reverse proxy + WAF in front for production.
- No built-in rate limit on `/api/auth/*` beyond `BAN_VIOLATIONS`; brute-force protection requires upstream proxy (Cloudflare, fail2ban) for serious threats.

### Composing with Ollama, Open WebUI, A1111, ComfyUI

| Backend | How |
|---|---|
| **Ollama** | `librechat.yaml` → `endpoints.custom` entry with `baseURL: http://host.docker.internal:11434/v1` (see *Adding a custom OpenAI-compatible provider* above) |
| **Open WebUI as a model router** | `endpoints.custom` with `baseURL: http://openwebui-host:8080/v1` + a per-user API key generated from Open WebUI's *Settings → Account → API Keys*. Open WebUI's RAG / image-gen / model permissions all apply transparently. |
| **A1111 / ComfyUI as image-gen** | LibreChat doesn't directly integrate image-gen backends as of current docs. Workaround: set up a custom MCP server that wraps A1111's `/sdapi/v1/txt2img` or ComfyUI's `/api/prompt`, then expose it via `mcpServers`. |
| **vLLM / LocalAI / TGI** | Same as Ollama — `endpoints.custom` with the OpenAI-compatible base URL. |

---

## Docker Compose (the canonical path)

When the user picks **any infra → Docker**. Pair with [`references/runtimes/docker.md`](../runtimes/docker.md) for host-level Docker install.

Upstream docs: <https://www.librechat.ai/docs/local/docker>.

### Prereqs

- Docker Engine 24+ + Compose v2 on the host.
- 2 GB RAM minimum (4 GB+ recommended for active RAG).
- 10 GB disk free (more if many users + large file uploads).
- Outbound HTTPS for image pulls + your chosen LLM provider APIs.

### Install

```bash
git clone https://github.com/danny-avila/LibreChat.git
cd LibreChat

# .env
cp .env.example .env

# librechat.yaml
cp librechat.example.yaml librechat.yaml

# Generate secrets — replace the .env placeholders
sed -i.bak \
  -e "s|^JWT_SECRET=.*|JWT_SECRET=$(openssl rand -base64 32)|" \
  -e "s|^JWT_REFRESH_SECRET=.*|JWT_REFRESH_SECRET=$(openssl rand -base64 32)|" \
  -e "s|^CREDS_KEY=.*|CREDS_KEY=$(openssl rand -hex 32)|" \
  -e "s|^CREDS_IV=.*|CREDS_IV=$(openssl rand -hex 16)|" \
  -e "s|^MEILI_MASTER_KEY=.*|MEILI_MASTER_KEY=$(openssl rand -hex 32)|" \
  .env

# Edit .env — set DOMAIN_CLIENT, DOMAIN_SERVER, ALLOW_REGISTRATION,
# and any provider API keys (OPENAI_API_KEY, ANTHROPIC_API_KEY, etc.)

# Edit librechat.yaml — comment/uncomment endpoints.custom entries you want;
# adjust registration.socialLogins / interface settings to taste

# Bring up
docker compose up -d
docker compose logs -f api
```

First `docker compose up -d` pulls ~3 GB of images (5 services). Watch `api` logs for startup completion — look for `LibreChat v<ver> started` and `connected to mongodb`.

### Customizing the compose

LibreChat's compose pattern is "edit `docker-compose.override.yml`, never the upstream `docker-compose.yml`". Upstream documents this pattern; common overrides:

```yaml
# docker-compose.override.yml — created by user; merged with docker-compose.yml on every `up -d`
services:
  api:
    # Mount librechat.yaml from the host (compose already does this, but useful for non-default location)
    volumes:
      - ./librechat.yaml:/app/librechat.yaml
      - ./images:/app/client/public/images
      - ./uploads:/app/uploads
      - ./logs:/app/api/logs
    extra_hosts:
      - 'host.docker.internal:host-gateway'   # Linux: makes Ollama on host reachable
    environment:
      # Override any .env value here without editing .env
      - DEBUG_OPENAI=true

  # Bring up an Ollama sidecar in the same compose
  ollama:
    image: ollama/ollama:latest
    ports:
      - '11434:11434'
    volumes:
      - ./ollama:/root/.ollama

  # Or a Caddy reverse proxy for TLS
  caddy:
    image: caddy:2
    ports:
      - '80:80'
      - '443:443'
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
```

### Bootstrapping the admin

Unlike Open WebUI's "first-user-becomes-admin in the UI" flow, LibreChat's admin role lives in MongoDB. The first user to register **does** get admin role automatically — but verify after first login by checking *Settings → Profile* (admin sees additional menus).

To manually grant admin:

```bash
docker compose exec mongodb mongosh LibreChat \
  --eval 'db.users.updateOne({email: "admin@example.com"}, {$set: {role: "ADMIN"}})'
```

### Updating

```bash
cd LibreChat
git pull                        # pull new compose + .env.example + librechat.example.yaml
# Diff your .env vs .env.example; same for librechat.yaml
diff <(sed 's/=.*//' .env.example | sort) <(sed 's/=.*//' .env | sort)

docker compose pull             # pull new image versions
docker compose up -d            # recreate changed services
docker compose logs -f api      # watch startup
```

For major-version bumps, **back up MongoDB + meili_data + pgdata2 + uploads/** before pulling — schema migrations occasionally happen and aren't always reversible.

### Lifecycle

```bash
docker compose ps                                             # what's running
docker compose logs -f api                                    # tail one service
docker compose restart api                                    # restart after .env or librechat.yaml changes
docker compose exec api npm run create-user                   # create user from CLI (script ships in repo)
docker compose exec mongodb mongosh LibreChat                 # poke at the DB
docker compose down                                           # stop everything (keeps volumes)
docker compose down -v                                        # nuke volumes — DESTRUCTIVE
```

### Backup + restore

State volumes:

- `./data-node/` — MongoDB. The big one — chat history, users, presets, agents.
- `./meili_data_v1.x/` — search index. Re-buildable from MongoDB.
- `pgdata2` — pgvector. Re-buildable by re-ingesting documents.
- `./images/` + `./uploads/` — user-uploaded files.
- `./logs/` — runtime logs.

Backup script:

```bash
docker compose down
tar czf librechat-backup-$(date +%F).tgz \
  data-node meili_data_v1.* pgdata2 images uploads .env librechat.yaml

# Restore: extract over a fresh checkout, then docker compose up -d
docker compose up -d
```

For production: schedule a nightly `mongodump` of MongoDB to S3, plus periodic `tar` of the file dirs. The `pgdata2` volume isn't backup-critical (re-ingestable).

### Reverse proxy + TLS

LibreChat doesn't terminate TLS. Front with Caddy (simplest):

```text
# Caddyfile
chat.example.com {
  reverse_proxy localhost:3080
}
```

Caddy fetches Let's Encrypt certs automatically. Set `DOMAIN_CLIENT=https://chat.example.com` and `DOMAIN_SERVER=https://chat.example.com` in `.env` — without those, OAuth callbacks break silently.

For nginx + certbot, see `references/runtimes/native.md` § *Reverse proxy*. For Cloudflare Tunnel, see `references/modules/tunnels.md`.

### Docker Compose-specific gotchas (LibreChat-only)

- **`CREDS_KEY` rotation breaks every stored provider key.** Once stored API keys are encrypted with the current key, rotating it without re-encrypting all of them is an outage. Set once and treat as immutable; if you must rotate, drop the affected MongoDB collection (`tokens`) first.
- **`docker-compose.override.yml` is the right way to customize.** Upstream's `docker-compose.yml` gets pulled fresh on every `git pull`; in-place edits are fragile.
- **`librechat.yaml` schema version** at the top of the file must match what your `api` image expects. If you bumped the image (`git pull` + `docker compose pull`) and didn't update `librechat.yaml`, you'll see schema-validation errors at startup. The example file shows the current version.
- **`extra_hosts: "host.docker.internal:host-gateway"`** is mandatory on Linux for "host Ollama" deploys. Docker Desktop (mac/win) provides it automatically.
- **`MEILI_MASTER_KEY` change requires re-indexing.** Meilisearch refuses to read indexes encrypted with a different master key. After rotation, drop `./meili_data_*/` and trigger re-index via `api` startup.
- **`fileStrategy: 'local'` + container recreation = lost files** unless `./images/` and `./uploads/` are bind-mounted. Upstream compose mounts them by default; verify before assuming.
- **Long-running RAG ingest blocks the rag_api worker.** A single 200-page PDF can take 30+ seconds. Batch uploads sequentially or scale `rag_api` (multi-replica via override).
- **OAuth callback URL must match the configured domain exactly.** `DOMAIN_CLIENT` / `DOMAIN_SERVER` mismatch with the actual public URL = OAuth round-trip lands at `localhost:3080/...` instead of your domain. Set `.env` BEFORE registering the OAuth app at GitHub/Google/etc.
- **`fetch: true` on a custom endpoint hits `<baseURL>/v1/models` on every UI render.** For slow/flaky upstream APIs, this can make the UI feel sluggish. Use `fetch: false` + an explicit `default: [...]` model list for production stability.
- **`balance.enabled: true` forces `transactions.enabled: true`** silently. You can't have one without the other for token accounting to work.

---

## npm / source install

When the user wants full control of the stack, contributes to LibreChat, or runs in an environment where Docker isn't viable. Pair with [`references/runtimes/native.md`](../runtimes/native.md) for OS prereqs and daemon-lifecycle.

Upstream docs: <https://www.librechat.ai/docs/local/npm>.

### Prereqs

- **Node.js 20+** (LibreChat ships against Node 20 LTS as of current docs).
- **MongoDB 6+** running locally or external (Atlas, self-hosted, Docker sidecar).
- **Meilisearch v1.x** running and reachable.
- **Postgres 15 with pgvector** + the `rag_api` service if you want RAG.
- ~3 GB disk for `node_modules` + repo; more for user uploads + Mongo data.

### Install + run

```bash
git clone https://github.com/danny-avila/LibreChat.git
cd LibreChat

# Configure
cp .env.example .env
cp librechat.example.yaml librechat.yaml
# Edit both — set MONGO_URI, MEILI_HOST, JWT_*, CREDS_*, provider keys.
# When Mongo / Meilisearch / pgvector run on the host (not Docker), point at localhost:27017 / localhost:7700 / localhost:5432.

# Generate secrets
sed -i.bak \
  -e "s|^JWT_SECRET=.*|JWT_SECRET=$(openssl rand -base64 32)|" \
  -e "s|^JWT_REFRESH_SECRET=.*|JWT_REFRESH_SECRET=$(openssl rand -base64 32)|" \
  -e "s|^CREDS_KEY=.*|CREDS_KEY=$(openssl rand -hex 32)|" \
  -e "s|^CREDS_IV=.*|CREDS_IV=$(openssl rand -hex 16)|" \
  -e "s|^MEILI_MASTER_KEY=.*|MEILI_MASTER_KEY=$(openssl rand -hex 32)|" \
  .env

# Install deps + build the frontend
npm ci
npm run frontend                   # build the React client into client/dist/

# Start backend in foreground (or under a process manager)
npm run backend
```

The backend serves both the API and the pre-built client out of `client/dist/`. Default bind: `0.0.0.0:3080`.

For dev mode (frontend hot-reload):

```bash
# Terminal 1: backend
npm run backend:dev

# Terminal 2: frontend with Vite dev server (proxies API calls to backend)
npm run frontend:dev
```

### Daemon lifecycle (systemd-user, Linux)

```bash
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/librechat.service <<'EOF'
[Unit]
Description=LibreChat
After=network-online.target

[Service]
Type=simple
WorkingDirectory=%h/LibreChat
EnvironmentFile=%h/LibreChat/.env
ExecStart=/usr/bin/node api/server/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now librechat
sudo loginctl enable-linger "$USER"
journalctl --user -u librechat -f
```

If MongoDB / Meilisearch / pgvector run on the host: install them via your distro's package manager (`apt install mongodb-org`, etc.) and ensure they start before LibreChat. Use the systemd `Wants=` / `After=` directives to express the dependency.

### Updating

```bash
cd LibreChat
git pull
npm ci                             # pick up new deps
npm run frontend                   # rebuild client
systemctl --user restart librechat # if running as a service
```

DB migrations run on backend startup. Watch `journalctl --user -u librechat` for migration errors.

### npm-install gotchas (LibreChat-only)

- **MongoDB / Meilisearch / pgvector installation is your problem.** The compose path bundles them; npm-source assumes they exist. Most users run them via Docker even when LibreChat itself runs from npm — use `docker run` or a sidecar compose.
- **Frontend build is heavy.** `npm run frontend` allocates 4+ GB during the Vite production build. On a 2 GB VPS, build it on a beefier machine and rsync the `client/dist/` over.
- **`npm ci` (not `npm install`).** Upstream pins exact versions in `package-lock.json`. `npm install` may "upgrade" minor versions and break.
- **Node 20 LTS specifically.** Node 18 lacks some features the codebase uses; Node 22 hasn't been validated upstream as of current docs.
- **The rag_api is Python (FastAPI), not Node.** Running RAG natively means a separate Python venv + service. Most users keep `rag_api` in Docker even when running LibreChat itself from npm.
- **`.env` location matters.** The backend looks for `.env` in `process.cwd()` — set `WorkingDirectory=` correctly in systemd, or run from the repo root.

---

## Docker Compose — production (`deploy-compose.yml`)

When the user wants the upstream-blessed production layout: an Nginx static-content + TLS-terminating service in front of the api, plus the same backend stack. Pair with [`references/runtimes/docker.md`](../runtimes/docker.md).

Upstream file: <https://github.com/danny-avila/LibreChat/blob/main/deploy-compose.yml>.

### What's different from `docker-compose.yml`

`deploy-compose.yml` keeps the same five backend services (`api` + `mongodb` + `meilisearch` + `vectordb` + `rag_api`) but adds a sixth:

| Added service | Image | Role |
|---|---|---|
| `client` | `nginx:1.27.0-alpine` | Public-facing reverse proxy on **ports 80 + 443**. Serves the pre-built React client from `client/dist/`, proxies `/api/*` to the `api` service. **TLS termination** lives here. |

Implications:

- The `api` service is no longer the public entry point — it's internal. Public traffic hits `client` first.
- Custom Nginx config is mounted from `client/nginx.conf` (verify upstream's exact path); customize there for redirects, custom headers, or extra-host routing.
- TLS certs aren't auto-provisioned — you bring them yourself or front the entire stack with another reverse proxy (Caddy / Cloudflare Tunnel) that handles certs.

### Install

```bash
git clone https://github.com/danny-avila/LibreChat.git
cd LibreChat

# Same .env + librechat.yaml setup as the dev path (see Docker Compose section above)
cp .env.example .env
cp librechat.example.yaml librechat.yaml
# generate JWT_SECRET / JWT_REFRESH_SECRET / CREDS_KEY / CREDS_IV / MEILI_MASTER_KEY (see dev section)

# Set DOMAIN_CLIENT and DOMAIN_SERVER to your public HTTPS URL — required for OAuth callbacks
sed -i.bak \
  -e "s|^DOMAIN_CLIENT=.*|DOMAIN_CLIENT=https://chat.example.com|" \
  -e "s|^DOMAIN_SERVER=.*|DOMAIN_SERVER=https://chat.example.com|" \
  .env

# Provision TLS certs (Let's Encrypt via certbot, or your existing certs)
# Place them where deploy-compose.yml expects (verify upstream's volume mounts)
# Typical: client/nginx.conf references /etc/nginx/ssl/{fullchain,privkey}.pem

docker compose -f deploy-compose.yml up -d
docker compose -f deploy-compose.yml logs -f client api
```

### Cert provisioning options

Upstream doesn't bundle certbot in `deploy-compose.yml`. Three patterns for production TLS:

1. **External Caddy / Traefik / Nginx in front** — keep `client` listening on a high port (or just the API on `3080`) and let your edge proxy handle TLS + routing. Simplest if you already operate one.
2. **Bring your own certs** — provision via certbot on the host, mount the cert files into the `client` container. Renewal is your responsibility.
3. **Cloudflare proxied + Origin CA cert** — Cloudflare terminates TLS at the edge; you use a long-lived Origin CA cert in `client`. Pair with `--listen` from a different angle (Cloudflare Tunnel skips the public-IP requirement entirely).

### Lifecycle (production)

```bash
docker compose -f deploy-compose.yml ps
docker compose -f deploy-compose.yml logs -f client      # nginx access + error logs
docker compose -f deploy-compose.yml logs -f api         # app logs
docker compose -f deploy-compose.yml restart api         # restart after .env changes
docker compose -f deploy-compose.yml pull && \
  docker compose -f deploy-compose.yml up -d             # upgrade (preserves named volumes)
docker compose -f deploy-compose.yml down                # stop everything
```

### Production-Compose-specific gotchas (LibreChat-only)

- **Two compose files coexist in the repo.** `docker-compose.yml` (dev) and `deploy-compose.yml` (prod) both work; pick one and stick with it. Mixing them on the same host = port collisions + volume confusion.
- **`-f deploy-compose.yml` on every command.** Don't forget the `-f` flag — bare `docker compose` falls back to `docker-compose.yml` (dev), bringing up dev-port-3080 alongside prod-port-80. Aliasing `dcprod='docker compose -f deploy-compose.yml'` saves grief.
- **TLS is your responsibility.** Unlike Dify's bundled certbot, LibreChat's prod compose assumes you handle certs. Plan for renewal day-one.
- **`client/nginx.conf` is upstream-managed.** Edits get clobbered on `git pull`. Use a `docker-compose.override.yml` to mount a custom nginx.conf, or fork the repo.
- **`DOMAIN_CLIENT` + `DOMAIN_SERVER` mismatch with the public URL** = OAuth callbacks land at the wrong host. Set both to the exact public HTTPS URL before the first OAuth provider is registered.

---

## Helm — first-party chart (`helm/librechat/`)

When the user picks **any k8s cluster → Helm**. Pair with [`references/runtimes/kubernetes.md`](../runtimes/kubernetes.md) for kubectl + Helm prereqs and Secret hygiene.

Upstream-blessed: a real first-party chart lives in the repo at <https://github.com/danny-avila/LibreChat/tree/main/helm/librechat>. Verified Chart.yaml metadata at recipe-write time:

| Field | Value |
|---|---|
| Chart name | `librechat` |
| Chart version | `2.0.3` |
| App version | `v0.8.6-rc1` |
| Type | `application` |
| Dependencies | `mongodb` 16.5.45 (Bitnami), `meilisearch` 0.11.0 (Meilisearch's repo), `redis` 24.1.3 (Bitnami), `librechat-rag-api` 0.5.3 (sibling chart in the same repo at `helm/librechat-rag-api/`) |

The sibling `librechat-rag-api` chart is included as a dependency, so `helm install` of the main chart pulls everything required.

### Prereqs

- Reachable k8s cluster (`kubectl get nodes` returns ready nodes).
- Helm v3.
- A default `StorageClass` (PVCs for MongoDB / Meilisearch / pgvector / image-volume).
- Ingress controller installed (nginx-ingress, Traefik, or cloud-native) if you want public reach via Ingress.
- cert-manager (only if using Ingress + automatic Let's Encrypt).

### Install

There's no public chart repo yet (verify upstream README at first install — packaging may have moved to OCI / GitHub-Pages chart repo by the time you deploy). Until then, install from the repo directly:

```bash
git clone https://github.com/danny-avila/LibreChat.git
cd LibreChat/helm/librechat

helm dependency update                                  # pull mongodb / meilisearch / redis / rag-api sub-charts

kubectl create namespace librechat

# Inspect defaults before installing
helm show values . > /tmp/librechat-defaults.yaml

# Install with explicit secrets + ingress config
helm upgrade --install librechat . \
  --namespace librechat \
  --create-namespace \
  --set ingress.enabled=true \
  --set ingress.host=chat.example.com \
  --set ingress.tls.enabled=true \
  --set librechat.configEnv.JWT_SECRET="$(openssl rand -base64 32)" \
  --set librechat.configEnv.JWT_REFRESH_SECRET="$(openssl rand -base64 32)" \
  --set librechat.configEnv.CREDS_KEY="$(openssl rand -hex 32)" \
  --set librechat.configEnv.CREDS_IV="$(openssl rand -hex 16)"
```

For values you'd rather not put on the command line, use `--values my-values.yaml`. The default `values.yaml` covers (verified against upstream):

| Section | What it controls |
|---|---|
| `replicaCount` | Pod replicas (default 1; multi-replica needs MongoDB ReplicaSet + Meilisearch readiness) |
| `image` | Repository, registry, pullPolicy, tag |
| `imagePullSecrets` | Private-registry auth |
| `serviceAccount` | Creation + naming + automounting + annotations |
| `service` | Type (ClusterIP / LoadBalancer / NodePort), port `3080`, annotations |
| `ingress` | Hostname + TLS toggle |
| `librechat.imageVolume` | 10 GB PVC for `images/` (uploaded media, generated images) |
| `librechat.configEnv` | `JWT_SECRET`, `JWT_REFRESH_SECRET`, `CREDS_KEY`, `CREDS_IV` |
| `librechat.configYamlContent` | The `librechat.yaml` content, injected as a ConfigMap |
| `global.librechat` | References to existing Secrets for credentials |
| `mongodb`, `meilisearch`, `redis` | Sub-chart values; `enabled: true` by default — set false to use external instances |
| `librechat-rag-api` | Optional RAG sub-chart; embeddings provider selection |
| `resources` | CPU/memory limits + requests (commented out in defaults) |
| `autoscaling` | HPA config (off by default; range 1-100) |
| `livenessProbe` / `readinessProbe` | `/health` endpoint |
| `podSecurityContext` / `securityContext` | Non-root UID 1000, capability dropping |
| `nodeSelector` / `tolerations` / `affinity` | Pod scheduling |
| `dnsPolicy` / `dnsConfig` | Custom DNS (for proxies) |
| `updateStrategy` | RollingUpdate by default |

### Verify + access

```bash
kubectl -n librechat rollout status deploy/librechat
kubectl -n librechat get pods,svc,ingress,pvc
kubectl -n librechat logs deploy/librechat -f

# Local probe via port-forward (before DNS lands)
kubectl -n librechat port-forward svc/librechat 3080:3080
# → http://localhost:3080
```

### Upgrades

```bash
cd LibreChat
git pull
cd helm/librechat
helm dependency update                            # refresh sub-charts
helm upgrade librechat . --namespace librechat --reuse-values
```

For major-version chart bumps (e.g. 2.x → 3.x), **always snapshot the MongoDB volume + the librechat-image-volume PVC** before `helm upgrade`. App-level migrations are handled by the api on startup (`MIGRATION_ENABLED=true` default), but chart-level breaking changes (renamed values, restructured sub-charts) can require manual values.yaml fixups.

### Operating

```bash
# Scale RAG worker (separate deployment from the main librechat)
kubectl -n librechat scale deploy/librechat-rag-api --replicas=2

# Restart api after configMap (librechat.yaml) changes
kubectl -n librechat rollout restart deploy/librechat

# Connect to MongoDB
kubectl -n librechat exec -it sts/librechat-mongodb-0 -- mongosh -u root
```

### Helm-specific gotchas (LibreChat-only)

- **Chart bundles MongoDB / Meilisearch / Redis as sub-charts.** Convenient for first install, but you inherit Bitnami's chart conventions for MongoDB ReplicaSet + Redis sentinel. For production, prefer external managed services (MongoDB Atlas, Redis Cloud, Meilisearch Cloud) and `--set mongodb.enabled=false redis.enabled=false meilisearch.enabled=false`, then point the LibreChat values at external connection strings.
- **`librechat.configYamlContent` is a giant inline string.** The chart injects your `librechat.yaml` content as a ConfigMap. Keeping a separate `librechat.yaml` file under version control + reading it via `--set-file librechat.configYamlContent=librechat.yaml` is cleaner than inlining in `values.yaml`.
- **PVC reclaim policy.** Default `Delete` reclaim wipes MongoDB + image-volume on `helm uninstall`. For long-lived clusters, switch the StorageClass to `Retain` or take regular `mongodump` backups.
- **`librechat-rag-api` sub-chart is its own pod.** Distinct from the main librechat pod; talks to pgvector (also a sub-chart). Verify both come up before declaring success.
- **No public chart repo at recipe-write time.** Install is "git clone + helm install ." pattern. Watch upstream for a published OCI/Pages chart repo — it'll change the install one-liner.
- **`DOMAIN_CLIENT` / `DOMAIN_SERVER`** still apply — set them in `librechat.configEnv` to your Ingress hostname or OAuth + invite emails break the same way as Compose deploys.
- **ConfigMap size limit (1 MiB)** can be hit if `librechat.yaml` grows large with many `endpoints.custom` entries + per-endpoint model lists. Mitigations: shorten lists, use `fetch: true`, or split provider config into separately-managed Secrets.

---

## One-click cloud deploys (Railway / Zeabur / Sealos)

Upstream README publishes Deploy buttons for three vendors. These are upstream-blessed shortcuts — the deploy-template manifests live in the LibreChat repo or are upstream-controlled, so they qualify as official install methods per CLAUDE.md § *Strict doc-verification policy*.

> **Vendor-managed infra.** open-forge can't automate vendor click-flows; we narrate the steps and verify the result. For users who want full Claude-driven provisioning, prefer Docker Compose on a VPS or the Helm chart on a managed k8s cluster.

### Railway

1. Open the Deploy button from the upstream README (currently a referral-code-bearing template URL — verify the link before sharing widely).
2. Sign in to Railway. Railway forks LibreChat into the user's account and provisions:
   - LibreChat service (Node.js)
   - MongoDB plugin
   - Meilisearch plugin
   - (Optional) pgvector + rag_api services
3. Set required env vars at deploy-config screen: `OPENAI_API_KEY` (or whichever provider), `JWT_SECRET`, `JWT_REFRESH_SECRET`, `CREDS_KEY`, `CREDS_IV`, `MEILI_MASTER_KEY`. Use `openssl rand` to generate the secrets locally and paste.
4. (Optional) Custom domain via Railway's Custom Domains tab.
5. Set `DOMAIN_CLIENT` + `DOMAIN_SERVER` to the Railway-assigned `*.up.railway.app` URL or your custom domain.

Day-to-day: Railway's *Service → Settings* + browser shell handle ops. `railway` CLI works for log tailing.

### Zeabur

1. Open the Zeabur Deploy button from the README.
2. Sign in; Zeabur provisions LibreChat + dependencies as separate services in a Zeabur project.
3. Configure env vars in Zeabur's per-service settings panel.
4. (Optional) bind a custom domain; Zeabur handles TLS.

### Sealos

1. Open the Sealos Deploy button from the README.
2. Sealos deploys LibreChat as a Kubernetes-backed app on their hosted cluster.
3. Configure env vars + storage settings in Sealos's web UI.
4. Public URL is auto-assigned at `*.sealoscloud.io`; custom domain via DNS CNAME.

### One-click-specific gotchas (LibreChat-only)

- **Each vendor's template lags upstream.** The Deploy button targets a specific LibreChat version pinned in the template repo; verify against the latest LibreChat release before deploying. For latest-and-greatest, fork upstream and point the deploy at your fork.
- **Browser-driven config flow.** open-forge can read out the steps but can't click for the user. Plan for ~10 minutes of manual button-clicking per vendor.
- **`MEILI_MASTER_KEY` rotation requires re-indexing.** Generate carefully on first deploy; treat as set-once.
- **Vendor-imposed limits.** Railway's free tier has CPU/RAM caps that LibreChat + MongoDB + Meilisearch + rag_api can saturate. Plan for paid tier for any non-toy use.
- **`DOMAIN_CLIENT` / `DOMAIN_SERVER` must match the vendor-assigned URL.** Forget this and OAuth callbacks land at `localhost:3080` instead of your `*.up.railway.app` / `*.zeabur.app` / `*.sealoscloud.io` host.

---

## Per-cloud / per-PaaS pointers

LibreChat is CPU-bound (LLM inference happens at whatever provider you wire up). The 5-service compose stack runs on 2 GB / 1 vCPU for personal use; production with active RAG benefits from 4+ GB and SSD.

| Where | Adapter | Recommended path |
|---|---|---|
| AWS Lightsail | `infra/aws/lightsail.md` | Docker Compose (dev or prod variant); `medium_3_0` for hobby, `large_3_0` for real |
| AWS EC2 | `infra/aws/ec2.md` | Docker Compose on `t3.medium`/`t3.large` |
| Azure VM | `infra/azure/vm.md` | Docker Compose |
| Hetzner | `infra/hetzner/cloud-cx.md` | Docker Compose on CX22 (4 GB) for hobby, CX32 (8 GB) for real |
| DigitalOcean | `infra/digitalocean/droplet.md` | Docker Compose on `s-2vcpu-4gb` or larger |
| GCP Compute Engine | `infra/gcp/compute-engine.md` | Docker Compose |
| Oracle Cloud (free ARM) | `infra/oracle/free-tier-arm.md` | Docker Compose on the A1.Flex 4-core / 24 GB free tier — **excellent fit** if you can get the capacity |
| Hostinger | `infra/hostinger.md` | VPS plan + Docker Compose via Hostinger Docker Manager |
| Raspberry Pi | `infra/raspberry-pi.md` | Pi 5 with 8 GB RAM works for hobby; Pi 4 is tight (rag_api memory) |
| BYO Linux VPS | `infra/byo-vps.md` | Docker Compose |
| localhost | `infra/localhost.md` | Docker Compose (dev variant) |
| Any Kubernetes cluster (EKS / GKE / AKS / DOKS / k3s) | (user-provided) | First-party Helm chart at `helm/librechat/` |
| **Railway** | `infra/paas/railway.md` (existing PaaS adapter) + the upstream Deploy button | One-click — see *One-click cloud deploys* above |
| **Zeabur** | (no first-party adapter — vendor handles infra) | One-click — see *One-click cloud deploys* above |
| **Sealos** | (no first-party adapter — vendor handles infra) | One-click — see *One-click cloud deploys* above |
| Fly.io | `infra/paas/fly.md` (existing PaaS adapter) | Possible with custom `fly.toml` (multi-process: api + mongo sidecar + meili sidecar). Heavier than Compose; not upstream-templated. |
| Render / Northflank / exe.dev | (existing PaaS adapters) | Same — possible but each requires multi-service config + persistent volumes + backing DBs. Not upstream-templated; use Railway/Zeabur/Sealos instead. |

---

## Verification before marking `provision` done

- All 5 (or 6 with the prod compose) services running:
  - Compose dev: `docker compose ps` shows `api`, `mongodb`, `meilisearch`, `vectordb`, `rag_api` as `running`.
  - Compose prod: same plus `client` (Nginx).
  - Helm: `kubectl -n librechat get pods` shows main pod + sub-chart pods.
  - npm: `systemctl --user is-active librechat` and the dependent DBs.
- HTTP health: `curl -sIo /dev/null -w '%{http_code}\n' http://127.0.0.1:3080/` (dev) or `https://<your-domain>/` (prod) returns `200` or `302`.
- API health: `curl -s http://127.0.0.1:3080/api/config` returns valid JSON listing the configured providers.
- Browser loads the UI; first-user registration page is accessible.
- After registering admin: model picker shows at least one model from a configured provider — confirms the `endpoints.custom` (or `OPENAI_API_KEY`) plumbing reaches the LLM provider.
- One test message round-trips (UI sends → API → model provider → response renders) — confirms the full chain.
- (If RAG configured) Upload a PDF, wait for indexing, ask a question that requires the doc — confirms vectordb + rag_api + embedder.
- (If multi-user) Invite a test user, confirm the invite email arrives (requires `MAIL_TYPE=resend|smtp` configured) — confirms email plumbing.

---

## Consolidated gotchas

Universal:

- **Two config files split the surface.** `.env` for infrastructure, `librechat.yaml` for runtime UX. Both must be set; missing the right one in the right place breaks subtle behavior (OAuth callbacks, CORS, model lists).
- **`CREDS_KEY` rotation breaks every stored provider key.** Set once and treat as immutable; rotating without re-encrypting the `tokens` collection is an outage.
- **`DOMAIN_CLIENT` / `DOMAIN_SERVER` mismatch with the public URL** silently breaks OAuth, invite emails, and CORS-checked browser flows.
- **First user becomes admin.** Race condition on `/install`-equivalent (the registration page) during initial setup — restrict access until admin exists.
- **`MEILI_MASTER_KEY` is set-once.** Rotating requires re-indexing every conversation.
- **Email config is mandatory for any non-localhost deploy.** Without `MAIL_TYPE=resend|smtp` + provider keys, invites + password resets silently fail.
- **`fileStrategy: 'local'` + container recreate = data loss** unless `./images/` and `./uploads/` are bind-mounted (Compose) or backed by PVCs (Helm).
- **Custom OpenAI-compatible endpoints with `fetch: true`** hit `<baseURL>/v1/models` on every UI render. Use `fetch: false` + explicit `default: [...]` for prod stability.
- **`balance.enabled: true` forces `transactions.enabled: true`** silently. Can't have one without the other.
- **`librechat.yaml` schema version must match the running api image.** After `git pull` + `docker compose pull`, verify the example file's `version:` against your custom `librechat.yaml`.

Per-method gotchas live alongside each section above:

- **Docker Compose dev** — see *Docker Compose-specific gotchas* + `runtimes/docker.md` § *Common gotchas*.
- **Docker Compose prod** — see *Production-Compose-specific gotchas*.
- **npm / source** — see *npm-install gotchas* + `runtimes/native.md` § *Common gotchas*.
- **Helm** — see *Helm-specific gotchas* + `runtimes/kubernetes.md` § *Common gotchas*.
- **One-click cloud deploys** — see *One-click-specific gotchas*.

---

## TODO — verify on subsequent deployments

- **First end-to-end Docker Compose dev deploy** on Linux + a real domain — verify `DOMAIN_CLIENT` / `DOMAIN_SERVER` configuration; verify OAuth callback after attaching a domain.
- **First end-to-end Docker Compose prod deploy** (`deploy-compose.yml`) — verify Nginx `client` service config, TLS cert provisioning pattern (the recipe lists three options; pick one and document the exact path).
- **First-party Helm chart** (`helm/librechat/` v2.0.3 / app v0.8.6-rc1) — never deployed end-to-end. Verify: `helm dependency update` works against the published chart-dependency repos (Bitnami, Meilisearch); verify the in-repo `librechat-rag-api` sub-chart resolves locally; verify `librechat.configYamlContent` ConfigMap injection works for a non-trivial `librechat.yaml`; verify `librechat.imageVolume` 10GB PVC sizing on real RAG workloads.
- **Helm chart with external MongoDB / Redis / Meilisearch** (set `mongodb.enabled=false` etc. + point at managed services) — never validated. Document the values.yaml pattern.
- **Railway / Zeabur / Sealos one-click flows** — none has been exercised by open-forge. The browser-driven nature means we narrate the steps; first user to deploy via each should fold gotchas back into the relevant subsection.
- **OAuth providers** (GitHub / Google / Discord / OIDC / SAML / Apple / Facebook) — never tested. Verify the callback URL pattern + `WEBUI_URL`-equivalent env-var settings + `ALLOW_SOCIAL_LOGIN` / `ALLOW_SOCIAL_REGISTRATION` interactions.
- **`CREDS_KEY` rotation procedure** — what happens if the user wants to rotate post-deploy? Verify and document the re-encrypt-tokens-collection pattern (or document the "don't rotate, drop tokens collection" workaround).
- **MongoDB ReplicaSet for HA** — sub-chart supports it; never tested end-to-end. Verify the values.yaml pattern + LibreChat's connection-string handling.
- **Migration story** — major LibreChat version bumps occasionally introduce DB schema changes. Verify the `MIGRATION_ENABLED=true` flow on a populated DB across at least one major-version bump.
- **Backup + restore drill** — exercise the documented MongoDB `mongodump` + filesystem-tar flow against a populated install; verify restore on a fresh host preserves users / chats / RAG indexes / file uploads.
- **`librechat.yaml` schema-version drift across `git pull`** — verify the failure mode when a freshly-pulled api image expects a higher `version:` than the user's `librechat.yaml`. Document the upgrade procedure (read `librechat.example.yaml` for the new keys, merge into your version-bumped yaml).
- **MCP server configuration end-to-end** — `mcpServers` in `librechat.yaml` documented from the example, but not validated. Verify with at least one stdio MCP server (`npx -y @modelcontextprotocol/server-puppeteer` per the example).
- **Composing with Ollama / Open WebUI / OpenClaw / Hermes** — first-run validation: LibreChat as the user-facing UI fronting Ollama (`endpoints.custom`), or LibreChat as a model router that OpenClaw/Hermes/Aider point at via Open-WebUI-equivalent /v1 API.
- **Web search providers** (Serper / SearXNG / Jina / Firecrawl / Brave) — never tested. Verify the `webSearch` block in `librechat.yaml`.
- **Image-generation backend integration** — LibreChat doesn't currently integrate A1111 / ComfyUI directly (per current docs). Workaround documented as MCP-server wrapper; verify whether upstream has shipped first-party image-gen support since recipe-write time.