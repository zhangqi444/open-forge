---
name: anythingllm-project
description: AnythingLLM recipe for open-forge — open-source RAG-focused workspace + AI agent platform (github.com/Mintplex-Labs/anything-llm, ~30k★). Different niche from chat UIs (Open WebUI, LibreChat) — workspace-style "drop a folder of PDFs, ask questions over them" UX with built-in vector DB (LanceDB), built-in agents (Browse / Scrape / Save / etc.), built-in MCP support, and per-workspace LLM provider + embedder selection. Covers every upstream-blessed install path documented in the repo: Docker (the canonical path; per `docker/HOW_TO_USE_DOCKER.md`), Desktop installers (Mac / Windows / Linux DMG/EXE/AppImage from anythingllm.com), bare metal / source install (per `BARE_METAL.md`, explicitly flagged as "not supported by core team"), plus a constellation of upstream-published one-click cloud-platform deploys (AWS CloudFormation, GCP Cloud Run, DigitalOcean Terraform, Render, Railway, RepoCloud, Elestio, Northflank). Pairs with `references/runtimes/{docker,native}.md` and `references/infra/*.md`.
---

# AnythingLLM

A self-hostable workspace + agent platform built around RAG. Each "workspace" is a scoped collection: drop in PDFs / URLs / Confluence / GitHub / etc., AnythingLLM ingests them via the **collector** service, embeds them into a **LanceDB** vector store (by default — swap for Pinecone / Weaviate / Qdrant / Chroma / Milvus / Astra etc. via env vars), and exposes a chat UI scoped to those documents. Beyond chat: built-in agents, MCP server support, per-workspace permissions, multi-user, embeddable chat widget, browser extension.

Default port: **3001**. The architecture is three services — `frontend` (Vite/React → built into static `server/public/`), `server` (Node/Express on 3001, the main API), `collector` (Node service that ingests + embeds documents). Storage: SQLite via Prisma + LanceDB on disk under a `STORAGE_DIR` you configure.

Upstream: <https://github.com/Mintplex-Labs/anything-llm>. Hosted (paid) at <https://my.mintplexlabs.com/aio-checkout?product=anythingllm>; open-forge is for self-hosting.

## Compatible combos

Verified against upstream README + `docker/HOW_TO_USE_DOCKER.md` + `BARE_METAL.md` + `cloud-deployments/` per CLAUDE.md § *Strict doc-verification policy*.

| How (runtime / install) | Module | Notes |
|---|---|---|
| **Docker** (canonical) | `runtimes/docker.md` + project section below | What upstream's docs lead with. `docker/HOW_TO_USE_DOCKER.md` documents Linux/Mac shell, Windows PowerShell, and Docker Compose flavors. Default storage at `~/anythingllm/`. |
| **Desktop App** (Mac / Windows / Linux) | (no infra adapter — runs locally) | Single-user app, downloadable from <https://anythingllm.com/download>. DMG (Mac) / EXE (Windows) / AppImage (Linux). Different deployment model — bundles a local server inside an Electron app; data stays on your laptop. |
| **Bare metal / source** | `runtimes/native.md` + project section below | Per `BARE_METAL.md`. NodeJS v18 + yarn. **Explicitly "not supported by core team"** in upstream docs — flag-and-warn per the strict-doc policy. |
| **Cloud one-clicks** (AWS / GCP / DO / Render / Railway / RepoCloud / Elestio / Northflank) | (vendor-managed) | Upstream README links Deploy buttons / Terraform templates / CloudFormation for each. See per-vendor section below. |
| **Hosted instance** (paid SaaS) | (out of scope) | <https://my.mintplexlabs.com/aio-checkout> — pointer-only; open-forge is for self-hosting. |

For the **where** axis, AnythingLLM (server + collector) is CPU-bound for the orchestration layer; embeddings + LLM inference happen at whatever provider you wire up. Built-in LanceDB indexing + the collector's PDF/text parsing benefit from disk speed and modest RAM (4+ GB for active RAG).

## Inputs to collect

| Phase | Prompt | Tool | Notes |
|---|---|---|---|
| preflight | "What do you want to host?" | (inferred from "AnythingLLM" / "anything-llm" in user's ask) | — |
| preflight | "Where?" | `AskUserQuestion`: AWS (CloudFormation) / GCP (Cloud Run) / DigitalOcean (Terraform) / Hetzner / Azure / Render / Railway / RepoCloud / Elestio / Northflank / BYO VPS / localhost / Desktop (laptop) / Kubernetes | Branches into matching upstream one-click OR open-forge infra adapter |
| preflight | "How?" (dynamic from combo) | `AskUserQuestion`: Docker / Desktop App / bare metal / cloud one-click | Filtered by infra |
| preflight | "Vector DB?" | `AskUserQuestion`: LanceDB (default, on-disk) / Pinecone / Weaviate / Qdrant / Chroma / Milvus / Astra / Other | `VECTOR_DB` env var |
| preflight | "LLM provider(s)?" | `AskUserQuestion`: Ollama (local) / OpenAI / Anthropic / Azure OpenAI / Bedrock / Gemini / Mistral / Groq / OpenRouter / Other OpenAI-compatible / Multiple | Configured via Settings UI on first login (NOT env vars by default — though per-key env-var overrides exist) |
| preflight | "Embedder?" | `AskUserQuestion`: AnythingLLM Native (default, local) / OpenAI / Ollama / Azure / Cohere / Voyage / LM Studio / LocalAI / Other | Drives `EMBEDDING_ENGINE` env var |
| provision | "Public domain?" | Free-text or skip | Triggers reverse proxy + cert-manager via runtimes/native.md (AnythingLLM doesn't terminate TLS itself) |
| provision | "Multi-user mode?" | `AskUserQuestion`: Single-user (default) / Multi-user with admin invite / Open registration | Toggled in Settings UI; backed by `AUTH_TOKEN` / multi-user env vars |
| provision | "Storage path?" | Free-text | Maps to `STORAGE_DIR` (Docker volume / bare-metal absolute path) |
| provision | "Browser extension + embed widget?" | `AskUserQuestion`: Yes (configure CORS + API keys) / No | Affects CORS settings + the embedded chat-widget setup |

Project-conditional outputs:

| Recorded as | Derived from |
|---|---|
| `outputs.public_url` | `http://<host>:3001/` (or `https://<domain>/`) |
| `outputs.install_method` | `docker` / `desktop` / `bare-metal` / `aws-cf` / `gcp-cloud-run` / `do-terraform` / `render` / `railway` / `repocloud` / `elestio` / `northflank` |
| `outputs.storage_dir` | The `STORAGE_DIR` host path (e.g. `~/anythingllm/`) |
| `outputs.vector_db` | `lancedb` (default) / `pinecone` / `weaviate` / `qdrant` / `chroma` / `milvus` / `astra` / etc. |
| `outputs.embedder` | `native` / `openai` / `ollama` / etc. |
| `outputs.llm_providers` | List of configured providers |

## Software-layer concerns (apply to every deployment)

### Architecture — three services in one container/process tree

| Service | Purpose | Default port |
|---|---|---|
| `frontend` | Vite/React SPA. Built into static files at `frontend/dist/`, then copied to `server/public/` for production. Not a separate runtime process at deploy-time. | (served by `server`) |
| `server` | Node/Express API. Authentication, workspace + chat CRUD, LLM routing, vector queries against the configured vector DB, multi-user, agent execution. | **3001** |
| `collector` | Node service that ingests + parses + embeds documents (PDFs, URLs, GitHub repos, Confluence, etc.). Talks back to `server` via internal API. | **8888** (internal) |

The Docker image bundles all three; bare-metal deploy runs `server` and `collector` as two separate Node processes. The frontend is always built ahead of time and served as static content by `server`.

### Storage

- **SQLite via Prisma** — workspaces, users, chats, settings, prompts, agents.
- **LanceDB** (default) — vector embeddings, on-disk under `STORAGE_DIR/lancedb/`.
- **Files** — uploaded source documents + generated chunks under `STORAGE_DIR/documents/`.
- **Models cache** — downloaded embedder models (if using the built-in native embedder) under `STORAGE_DIR/models/`.

`STORAGE_DIR` is the single most important env var. Lose this directory = lose every workspace, document, and embedding. Bind-mount in Docker; absolute path in bare metal. Upstream Docker convention is `~/anythingllm/` on the host; in-container it lives at `/app/server/storage/`.

### Vector DB choice

LanceDB ships built-in and works without any external service — recommended default for self-hosters. Switching is via the `VECTOR_DB` env var + per-provider keys:

| `VECTOR_DB` value | Notes |
|---|---|
| `lancedb` (default) | On-disk under `STORAGE_DIR/lancedb/`. Single-node only; no external deps. |
| `pinecone` | Managed cloud vector DB. Set `PINECONE_API_KEY` + `PINECONE_INDEX`. |
| `weaviate` | Self-hosted or Weaviate Cloud. Set `WEAVIATE_ENDPOINT` + optional API key. |
| `qdrant` | Self-hosted or Qdrant Cloud. Set `QDRANT_ENDPOINT` + optional API key. |
| `chroma` | Self-hosted Chroma. Set `CHROMA_ENDPOINT`. |
| `milvus` | Self-hosted or Zilliz Cloud. Set `MILVUS_ADDRESS` + creds. |
| `astra` | DataStax Astra DB. Set `ASTRA_DB_*` keys. |
| `pgvector` | Postgres + pgvector. Set `PGVECTOR_CONNECTION_STRING`. |

Switching after data exists requires re-embedding every workspace's documents. There's no migration tool — drop the old workspace, re-create on the new vector DB, re-upload sources.

### LLM provider + embedder configuration

Most provider config lives in **Settings UI** (per-workspace, encrypted in the SQLite DB), not env vars. Single-user / first-launch defaults can be pre-staged via env vars (`OPEN_AI_KEY`, `ANTHROPIC_API_KEY`, `OLLAMA_BASE_PATH`, etc.) so Docker / cloud one-click deploys come up working without manual config — but the canonical config surface is the UI.

Common provider env vars (set in `.env` for Docker / bare metal):

| Env var | Purpose |
|---|---|
| `LLM_PROVIDER` | `openai` / `anthropic` / `azure` / `bedrock` / `gemini` / `mistral` / `groq` / `ollama` / `lmstudio` / `localai` / `openrouter` / etc. |
| `OPEN_AI_KEY` / `ANTHROPIC_API_KEY` / `GROQ_API_KEY` / `OPEN_ROUTER_API_KEY` / etc. | Per-provider API keys. |
| `OLLAMA_BASE_PATH` | `http://host.docker.internal:11434` for host-running Ollama (Linux Docker also needs `--add-host=host.docker.internal:host-gateway`); in-container: container name + port. |
| `EMBEDDING_ENGINE` | `native` (default, downloads model on first use) / `openai` / `ollama` / `azure` / `cohere` / `voyage` / `lmstudio` / `localai`. |
| `EMBEDDING_MODEL_PREF` | Model ID for the chosen embedder. |
| `WHISPER_PROVIDER` | `local` (built-in) / `openai`. |
| `TTS_PROVIDER` | `native` (browser) / `openai` / `elevenlabs`. |

Switching providers post-deploy is a Settings-UI click for the new provider + paste new key; existing workspaces gracefully fall back to the new default.

### Auth + multi-user

Default install is **single-user** (no auth). To enable multi-user:

1. Settings → Security → enable Multi-User mode.
2. Set an admin password (which auto-creates the admin account).
3. Subsequently invite users via *Settings → Users*.

Server-side controls also exist via env vars:

| Env var | Effect |
|---|---|
| `AUTH_TOKEN` | Single-user-mode shared password. Anyone with this token has full access. |
| `JWT_SECRET` | Used to sign session tokens. Generate explicitly with `openssl rand -base64 32`. **Rotation logs everyone out.** |
| `DISABLE_TELEMETRY` | `true` to opt out of usage telemetry. Default is opt-in (telemetry on). |
| `ENABLE_HTTPS=true` + cert paths | Lets `server` terminate TLS directly (uncommon — usually a reverse proxy is upstream). |

There's no built-in OAuth/OIDC/SAML in the default open-source build. SSO is in the paid commercial tier.

### Critical environment variables (any deploy)

| Variable | Purpose |
|---|---|
| `STORAGE_DIR` | Absolute path to the persistent state dir. **Critical** — survives container restarts iff bind-mounted. |
| `JWT_SECRET` | Session-token signing. Auto-generated on first run if unset, but explicitly set to avoid logout-everyone-on-restart. |
| `SIG_KEY` + `SIG_SALT` | Used to encrypt API keys + provider creds at rest. Set explicitly via `openssl rand -hex 32` × 2. **Rotation breaks all stored keys** — set once. |
| `LLM_PROVIDER` + provider key | Default LLM (overridable per-workspace). |
| `EMBEDDING_ENGINE` + embedder key | Default embedder. |
| `VECTOR_DB` + vector-DB connection | Default vector store. |
| `DISABLE_VIEW_CHAT_HISTORY` | `true` for compliance; users can't review past chats in the UI. |
| `WHISPER_PROVIDER` / `TTS_PROVIDER` | STT / TTS backends. |
| `SERVER_PORT` | Override the default 3001. |
| `SUPPORTED_FILE_EXTENSIONS` | Comma-separated allowlist for uploaded docs. Defaults to a wide set; tighten for production. |

For the full env-var matrix, see `server/.env.example` in the repo (canonical source) and `docker/.env.example` (Docker-flavored variant).

### Composing with Ollama / Open WebUI / OpenClaw / Hermes / LibreChat

- **Ollama as LLM + embedder backend** — `LLM_PROVIDER=ollama` + `OLLAMA_BASE_PATH=http://host.docker.internal:11434`. Make sure Ollama is bound to a non-loopback interface (`OLLAMA_HOST=0.0.0.0:11434`).
- **Open WebUI / LibreChat fronting AnythingLLM** — AnythingLLM exposes its own OpenAI-compatible API (per-workspace API keys generated under *Settings → API Keys*). Point Open WebUI / LibreChat at `http://anythingllm:3001/api/v1/openai` with that key, and the chat UI gets RAG-augmented responses transparently.
- **OpenClaw / Hermes / Aider as agents** — same pattern — point them at AnythingLLM's OpenAI-compatible base URL with an API key. The agents inherit all configured workspaces' RAG context.
- **Sharing vector DB with another tool** — Pinecone / Qdrant / Weaviate are the path; if multiple tools point at the same `pgvector` instance, namespace them with distinct collection names.

---

## Docker (the canonical path)

When the user picks **any infra → Docker**. Pair with [`references/runtimes/docker.md`](../runtimes/docker.md).

Upstream docs: <https://github.com/Mintplex-Labs/anything-llm/blob/master/docker/HOW_TO_USE_DOCKER.md>. Image: `mintplexlabs/anythingllm` on Docker Hub.

### Prereqs (per upstream)

- Docker installed.
- Node.js + Yarn (only if you'll customize / rebuild the image; not needed for `docker run` of the published image).
- Access to an LLM (local Ollama or remote API).
- ≥ 2 GB RAM for cloud deploys.
- ≥ 10 GB disk for state (more for active document ingestion).

### Linux / macOS one-liner

```bash
export STORAGE_LOCATION=$HOME/anythingllm
mkdir -p "$STORAGE_LOCATION"
touch "$STORAGE_LOCATION/.env"

docker run -d \
  --name anythingllm \
  --add-host=host.docker.internal:host-gateway \
  --env STORAGE_DIR=/app/server/storage \
  --health-cmd "/bin/bash /usr/local/bin/docker-healthcheck.sh || exit 1" \
  --health-interval 60s --health-start-period 60s \
  --mount type=bind,source="$STORAGE_LOCATION",target=/app/server/storage \
  --mount type=bind,source="$STORAGE_LOCATION/.env",target=/app/server/.env \
  -p 3001:3001/tcp \
  --restart=always \
  --user anythingllm \
  --cap-add SYS_ADMIN \
  mintplexlabs/anythingllm
```

`--add-host=host.docker.internal:host-gateway` is mandatory on **Linux** for "host Ollama" deploys. Docker Desktop (Mac/Win) provides it automatically. `--cap-add SYS_ADMIN` is required for the Chromium sandbox the document scraper uses.

Open `http://<host>:3001/` after ~30 s for first-run setup.

### Windows PowerShell

```powershell
$env:STORAGE_LOCATION="$HOME\Documents\anythingllm"
If(!(Test-Path $env:STORAGE_LOCATION)) {New-Item $env:STORAGE_LOCATION -ItemType Directory}
If(!(Test-Path "$env:STORAGE_LOCATION\.env")) {New-Item "$env:STORAGE_LOCATION\.env" -ItemType File}

docker run -d `
  --name anythingllm `
  --add-host=host.docker.internal:host-gateway `
  --env STORAGE_DIR="/app/server/storage" `
  --mount type=bind,source="$env:STORAGE_LOCATION",target=/app/server/storage `
  --mount type=bind,source="$env:STORAGE_LOCATION\.env",target=/app/server/.env `
  -p 3001:3001/tcp `
  --restart=always `
  --user anythingllm `
  --cap-add SYS_ADMIN `
  mintplexlabs/anythingllm
```

### Docker Compose (recommended for production)

```yaml
services:
  anythingllm:
    image: mintplexlabs/anythingllm
    container_name: anythingllm
    ports:
      - "3001:3001"
    cap_add:
      - SYS_ADMIN
    environment:
      - STORAGE_DIR=/app/server/storage
      - JWT_SECRET=${JWT_SECRET}
      - SIG_KEY=${SIG_KEY}
      - SIG_SALT=${SIG_SALT}
      - LLM_PROVIDER=ollama
      - OLLAMA_BASE_PATH=http://host.docker.internal:11434
      - EMBEDDING_ENGINE=ollama
      - EMBEDDING_BASE_PATH=http://host.docker.internal:11434
      - EMBEDDING_MODEL_PREF=nomic-embed-text:latest
      - VECTOR_DB=lancedb
      - DISABLE_TELEMETRY=true
    volumes:
      - ./storage:/app/server/storage
      - ./.env:/app/server/.env
    extra_hosts:
      - "host.docker.internal:host-gateway"
    restart: unless-stopped
```

Bring up:

```bash
export JWT_SECRET=$(openssl rand -base64 32)
export SIG_KEY=$(openssl rand -hex 32)
export SIG_SALT=$(openssl rand -hex 32)
echo -e "JWT_SECRET=$JWT_SECRET\nSIG_KEY=$SIG_KEY\nSIG_SALT=$SIG_SALT" > .env

docker compose up -d
docker compose logs -f anythingllm
```

### Localhost connectivity from inside the container

When AnythingLLM runs in Docker but Ollama / LM Studio / etc. run on the host:

- Linux: use `host.docker.internal` + `--add-host=host.docker.internal:host-gateway`. Or substitute `172.17.0.1` (Docker's default bridge gateway).
- Mac / Windows: `host.docker.internal` works without flags (Docker Desktop maps it).
- **Don't** use `localhost` / `127.0.0.1` from inside the container — that points at the container itself, not the host.

### Updating

```bash
docker pull mintplexlabs/anythingllm
docker stop anythingllm && docker rm anythingllm
# Re-run the same `docker run` command (state survives in the bind-mounted STORAGE_DIR)
# Or `docker compose pull && docker compose up -d`
```

State + config persist via the bind-mounted `STORAGE_DIR` and `.env`. The image upgrade picks up new app code; existing workspaces, embeddings, users, prompts all survive.

### Lifecycle

```bash
docker exec -it anythingllm /bin/bash    # shell into the container
docker logs -f anythingllm               # tail logs
docker compose restart anythingllm       # restart after .env changes
docker stats anythingllm                 # quick CPU/RAM check
```

### Docker-specific gotchas (AnythingLLM-only)

- **`--cap-add SYS_ADMIN` is required**, not optional. The document scraper uses Chromium with sandboxing; without `SYS_ADMIN` the scraper crashes silently and document ingestion fails. Upstream calls this out in `HOW_TO_USE_DOCKER.md` — don't drop it.
- **`STORAGE_DIR` bind-mount is mandatory.** Without it, container recreate wipes every workspace + embedding + user. Upstream's recommended layout is `~/anythingllm/` on the host bind-mounted to `/app/server/storage`.
- **Two bind mounts: the dir AND the `.env` file.** Easy to mount only the dir and forget the `.env` — then env-var changes don't survive container recreate.
- **`--user anythingllm`** — the image creates a non-root `anythingllm` user. Don't override unless you also adjust ownership of the bind-mount dirs (`chown -R 1000:1000 ~/anythingllm/`).
- **Long document ingestion can OOM the container.** A 200-page PDF with images can exceed 2 GB during embedding. For production, allocate 4+ GB and set Docker `memory:` limits explicitly.
- **`SIG_KEY` / `SIG_SALT` rotation breaks every stored API key.** Like LibreChat's `CREDS_KEY` — set once and never rotate.
- **`localhost` is not what you want inside the container.** First-time users repeatedly trip on this when configuring host-running Ollama. Document the `host.docker.internal` substitution prominently.

---

## Desktop App (Mac / Windows / Linux)

When the user wants AnythingLLM on a single laptop, no server, no Docker — pure local-only single-user use. Different deployment model from server-based deploys: the Desktop App is an Electron-wrapped `server` + `collector` + bundled SQLite + LanceDB, all data on the laptop disk, no network exposure.

Upstream download page: <https://anythingllm.com/download>.

### Install

The download page detects the user's OS and offers the matching installer:

- **macOS** — `.dmg` (Apple Silicon + Intel separate downloads). Drag to `/Applications`, double-click to launch.
- **Windows** — `.exe` installer. Run, follow wizard.
- **Linux** — `.AppImage`. `chmod +x AnythingLLMDesktop.AppImage && ./AnythingLLMDesktop.AppImage`. (Some distros need `--no-sandbox` if the AppImage's sandboxing trips on your kernel.)

open-forge can't drive GUI installers autonomously, but it can fetch the matching binary via `curl` and document the launch steps. Alternative on macOS: `brew install --cask anythingllm`.

### Configuration

Settings + workspaces + chats live under platform-standard app-data dirs:

- macOS: `~/Library/Application Support/anythingllm-desktop/`
- Windows: `%APPDATA%\anythingllm-desktop\`
- Linux: `~/.config/anythingllm-desktop/`

Single-user by design — no multi-user mode, no auth (the laptop's user account IS the auth boundary). For multi-user, use Docker or bare-metal.

### Updating

The Desktop App auto-updates when launched (verified per upstream's behavior). Force-update via *Help → Check for Updates*.

### Sharing data with a server install

There's no built-in import/export between Desktop and server installs at recipe-write time. If a user starts on Desktop and migrates to server, they re-create the workspace + re-upload sources. (Or copy the `lancedb/`, `documents/`, `anythingllm.db` files directly between the Desktop app-data dir and the server's `STORAGE_DIR` — undocumented but works structurally; verify before relying.)

### Desktop-specific gotchas (AnythingLLM-only)

- **Single-user only.** No multi-user mode in the Desktop App; for shared deployments, server-based.
- **No public URL.** Desktop App listens only on the local loopback; can't be reached from another device on the LAN by design.
- **macOS Gatekeeper** may block first launch. Right-click → Open the first time, or `xattr -cr /Applications/AnythingLLM.app` if codesign is missing.
- **AppImage on some distros** needs `--no-sandbox` for Electron's chromium. Adds attack surface; only when necessary.
- **Updates can break workspace integrity** rarely (unrelated to recipe scope, but document the symptom — sudden "workspace not found" errors after auto-update). Mitigation: keep regular backups of the app-data dir.
- **Browser extension + embed widget don't work with Desktop.** Those features need a server-mode install with a public URL.

---

## Bare metal / source install

> **Not supported by upstream's core team.** Per `BARE_METAL.md`: *"This method of deployment is not supported by the core-team and is to be used as a reference for your deployment. You are fully responsible for securing your deployment and data in this mode. Any issues experienced from bare-metal or non-containerized deployments will be not answered or supported."* Pair with [`references/runtimes/native.md`](../runtimes/native.md) for OS prereqs.

For users who need full control (custom Node version, no Docker, integration with system services, regulatory/policy reasons against containers).

Upstream docs: <https://github.com/Mintplex-Labs/anything-llm/blob/master/BARE_METAL.md>.

### Prereqs

- **NodeJS v18** (specifically v18 — newer versions may work but aren't tested by upstream).
- **Yarn** (not npm — upstream pins to yarn).
- ≥ 2 GB RAM, ≥ 10 GB disk.

### Install

```bash
git clone git@github.com:Mintplex-Labs/anything-llm.git
cd anything-llm

# Install dependencies for all three sub-projects (frontend, server, collector)
yarn setup

# Configure server
cp server/.env.example server/.env
# Edit server/.env — at minimum set:
#   STORAGE_DIR="/your/absolute/path/to/server/storage"
# Plus generate JWT_SECRET, SIG_KEY, SIG_SALT (openssl rand -hex 32)

# Configure frontend
# Edit frontend/.env — set VITE_API_BASE='/api' for non-localhost / Docker deploys
```

### Build + run

AnythingLLM bare-metal runs as **two separate Node processes** (`server` and `collector`); the frontend is built ahead of time into static files served by `server`.

```bash
# 1. Build the frontend
cd frontend && yarn build
# → produces frontend/dist/

# 2. Copy built frontend into server's public dir
cp -R frontend/dist server/public
cd ..

# 3. Run DB migrations
cd server && npx prisma generate --schema=./prisma/schema.prisma
cd server && npx prisma migrate deploy --schema=./prisma/schema.prisma

# 4. Start server (foreground or backgrounded)
cd server && NODE_ENV=production node index.js &

# 5. Start collector in another process
cd collector && NODE_ENV=production node index.js &
```

UI at `http://localhost:3001/`.

### Daemon lifecycle (systemd-user)

Two services to manage. systemd-user units:

```bash
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/anythingllm-server.service <<'EOF'
[Unit]
Description=AnythingLLM Server
After=network-online.target

[Service]
Type=simple
WorkingDirectory=%h/anything-llm/server
EnvironmentFile=%h/anything-llm/server/.env
Environment=NODE_ENV=production
ExecStart=/usr/bin/node index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

cat > ~/.config/systemd/user/anythingllm-collector.service <<'EOF'
[Unit]
Description=AnythingLLM Collector
After=network-online.target

[Service]
Type=simple
WorkingDirectory=%h/anything-llm/collector
Environment=NODE_ENV=production
ExecStart=/usr/bin/node index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now anythingllm-server anythingllm-collector
sudo loginctl enable-linger "$USER"
journalctl --user -u anythingllm-server -f
```

### Updating (per upstream's example script)

```bash
cd ~/anything-llm
git checkout .
git pull origin master

# Rebuild frontend
cd frontend && yarn && yarn build && cd ..

# Copy to server/public
rm -rf server/public
cp -r frontend/dist server/public

# Stop processes
systemctl --user stop anythingllm-server anythingllm-collector
# (or: pkill node — but be careful if other Node processes run)

# Reinstall + migrate
cd collector && yarn && cd ..
cd server && yarn && npx prisma migrate deploy && npx prisma generate && cd ..

# Restart
systemctl --user start anythingllm-server anythingllm-collector
```

Upstream's `BARE_METAL.md` ships an example update script — adapt for your systemd / pm2 / supervisord layout.

### Reverse proxy + websocket support

AnythingLLM uses websockets for streaming chat AND for the agent-invocation protocol. Upstream provides this Nginx config snippet (verbatim per `BARE_METAL.md`):

```nginx
server {
   # Enable websocket connections for agent protocol
   location ~* ^/api/agent-invocation/(.*) {
      proxy_pass http://0.0.0.0:3001;
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "Upgrade";
   }

   listen 80;
   server_name your-domain.example;
   location / {
      # Prevent timeouts on long-running requests
      proxy_connect_timeout       605;
      proxy_send_timeout          605;
      proxy_read_timeout          605;
      send_timeout                605;
      keepalive_timeout           605;

      # Enable readable HTTP streaming for LLM responses
      proxy_buffering off;
      proxy_cache off;

      proxy_pass  http://0.0.0.0:3001;
   }
}
```

For Caddy (simpler), the key directives are equivalent: WebSocket upgrade + streaming-friendly buffering off + long timeouts. Caddyfile sketch:

```text
your-domain.example {
  reverse_proxy localhost:3001 {
    flush_interval -1                # streaming-friendly
    transport http {
      read_timeout 605s
    }
  }
}
```

### Bare-metal-specific gotchas (AnythingLLM-only)

- **Upstream explicitly does not support this path.** When opening issues, the maintainers will close them as out-of-scope. Surface this caveat to the user before they invest time.
- **Two processes, not one.** `server` AND `collector` — forgetting to start the collector means document uploads silently fail to index.
- **Frontend rebuild after every `git pull`.** The `cp -R frontend/dist server/public` step is easy to forget; without it, `git pull` brings new server code but the UI still serves the old built frontend.
- **`pkill node` in the upstream update script is dangerous.** It kills *every* Node process on the box — Ollama if it's running as Node, other apps, etc. Use systemd unit names instead.
- **NodeJS v18 specifically.** v20 may work but isn't tested upstream; v22 has known breaks in some Prisma versions used by AnythingLLM.
- **`STORAGE_DIR` must be absolute.** Relative paths break depending on the cwd at process launch.
- **WebSocket headers in your reverse proxy** are mandatory for streaming + agents. Forgetting them = chat loads but messages silently never stream.
- **`yarn setup` runs in all three sub-projects.** Re-running on update needs `yarn` in collector AND server (and frontend rebuild). The example script in `BARE_METAL.md` does this.

---

## Cloud one-click deploys

Upstream README publishes Deploy buttons / templates for **eight** cloud platforms. Two are first-party Infrastructure-as-Code (CloudFormation + Terraform) maintained in the upstream repo; six are vendor-published one-click templates. Per CLAUDE.md § *Strict doc-verification policy*, all qualify as official install methods.

| Platform | Type | Upstream artifact / link |
|---|---|---|
| **AWS** | CloudFormation template (first-party, in repo) | `cloud-deployments/aws/cloudformation/DEPLOY.md` |
| **GCP** | Cloud Run Deploy button (vendor template) | README Deploy-on-GCP button |
| **DigitalOcean** | Terraform template (first-party, in repo) | `cloud-deployments/digitalocean/terraform/DEPLOY.md` |
| **Render.com** | Render Blueprint Deploy button (vendor) | README Deploy-on-Render button |
| **Railway** | Railway template (vendor) | <https://railway.app/template/HNSCS1> |
| **RepoCloud** | RepoCloud one-click (vendor) | README Deploy-on-RepoCloud button |
| **Elestio** | Elestio managed deploy (vendor) | README Elestio link |
| **Northflank** | Northflank stack template (vendor) | README Deploy-on-Northflank button |

### AWS — CloudFormation

Per `cloud-deployments/aws/cloudformation/DEPLOY.md`. Upstream ships a CloudFormation template that provisions an EC2 instance + EBS volume for `STORAGE_DIR` + security group + auto-installs the Docker container on first boot.

```bash
git clone https://github.com/Mintplex-Labs/anything-llm.git
cd anything-llm/cloud-deployments/aws/cloudformation

aws cloudformation create-stack \
  --stack-name anythingllm \
  --template-body file://aws-cloudformation-template.yaml \
  --parameters ParameterKey=KeyName,ParameterValue=your-key-pair-name
# Watch progress via:
aws cloudformation describe-stack-events --stack-name anythingllm --max-items 20
```

After `CREATE_COMPLETE`, the stack outputs the public URL. SSH key in `KeyName` lets you debug.

For teardown: `aws cloudformation delete-stack --stack-name anythingllm`.

### DigitalOcean — Terraform

Per `cloud-deployments/digitalocean/terraform/DEPLOY.md`. Upstream Terraform module provisions a Droplet + reserved IP + firewall + cloud-init that installs the Docker container.

```bash
cd anything-llm/cloud-deployments/digitalocean/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set DigitalOcean API token, SSH key fingerprint, droplet size, region

terraform init
terraform plan
terraform apply
```

### GCP — Cloud Run

Vendor-managed Deploy button from the README. Click → authorizes against the user's GCP account → deploys AnythingLLM as a Cloud Run service backed by a GCS bucket for `STORAGE_DIR`. open-forge can't drive the click flow; we narrate.

### Render.com — Blueprint Deploy

Render's Deploy button reads a `render.yaml` (verify location in upstream repo at first deploy — the button URL has the path baked in). Provisions: web service for AnythingLLM + persistent disk for `STORAGE_DIR`. User configures env vars in Render's UI before kickoff.

### Railway — template

Railway template URL: <https://railway.app/template/HNSCS1>. Click → forks AnythingLLM into the user's Railway account → provisions web service + persistent volume + assigns `*.up.railway.app` URL. User sets env vars in Railway's UI.

Railway has a referral-code-bearing variant in the README; either works. Recommend the upstream one in the README for upstream-stat tracking.

### RepoCloud / Elestio / Northflank — vendor-managed

Each is a vendor's marketplace listing. Click → user signs into the vendor → vendor handles provisioning + storage + URL assignment. Differences are in pricing model and SLAs; functionality is the same single AnythingLLM container.

### Cloud-one-click gotchas (AnythingLLM-only)

- **CloudFormation + Terraform templates lag upstream.** They pin specific AnythingLLM image tags / EC2 AMI IDs / Droplet image slugs. Verify the pinned version against the latest AnythingLLM release before deploying — for production, fork upstream's templates and pin to your tested version.
- **`STORAGE_DIR` persistence varies per provider.** EC2 + EBS = persistent. Cloud Run + GCS = persistent (but with copy-on-write semantics that can corrupt LanceDB if not handled correctly — verify the Cloud Run template's volume mount). Render + persistent disk = persistent. Railway = persistent volume by default. Verify before treating as production.
- **One-click templates set defaults you may not want.** Default LLM provider is often OpenAI with no key configured (which means the UI loads but chat fails). Always set provider env vars before considering the deploy "done".
- **Browser-driven flows** (Render, Railway, RepoCloud, Elestio, Northflank) are not automatable from open-forge; we narrate the click flow and verify the result via the vendor's URL.
- **`SIG_KEY` / `SIG_SALT`** — make sure each one-click deploy generates these per-instance. Some templates default to a known-fixed value (insecure) — override via env vars on first deploy.
- **AWS stack rollback on failure leaves orphaned EBS.** If CloudFormation fails mid-deploy, the EBS volume sometimes survives the rollback. Check `aws ec2 describe-volumes` after a failed `create-stack` and clean up manually.

---

## Per-cloud / per-PaaS pointers

AnythingLLM (server + collector) is CPU-bound for orchestration; the LLM provider does the heavy lifting. The Docker stack runs on 2 GB / 1 vCPU for personal use; production with active document ingestion + LanceDB indexing benefits from 4 GB + SSD.

| Where | Adapter | Recommended path |
|---|---|---|
| **AWS** | (use upstream CloudFormation) OR `infra/aws/lightsail.md` / `infra/aws/ec2.md` + Docker | Upstream CloudFormation is a 1-click for a vanilla EC2 deploy; pick the open-forge adapter for fancier setups (custom VPC, ALB, autoscaling). |
| **GCP** | (use upstream Cloud Run button) OR `infra/gcp/compute-engine.md` + Docker | Cloud Run for serverless / spiky traffic; Compute Engine + Docker for always-on. |
| **DigitalOcean** | (use upstream Terraform template) OR `infra/digitalocean/droplet.md` + Docker | Terraform template if you already use Terraform; plain Droplet + Docker is simpler. |
| Azure | `infra/azure/vm.md` + Docker | No upstream Azure template; use the Bastion-hardened VM adapter + Docker. |
| Hetzner | `infra/hetzner/cloud-cx.md` + Docker | CX22 (4 GB) for hobby, CX32 (8 GB) for real. |
| Oracle Cloud (free ARM) | `infra/oracle/free-tier-arm.md` + Docker | A1.Flex 4-core / 24 GB free tier — **excellent fit** if you can get capacity. Verify the Docker image runs on `linux/arm64` (upstream publishes multi-arch). |
| Hostinger | `infra/hostinger.md` + Docker | VPS plan + Docker via Hostinger Docker Manager. |
| Raspberry Pi | `infra/raspberry-pi.md` + Docker | Pi 5 with 8 GB for hobby; Pi 4 is tight (collector + Chromium memory). |
| BYO Linux VPS | `infra/byo-vps.md` + Docker | Any of the above. |
| localhost (laptop) | `infra/localhost.md` + Docker OR Desktop App | Desktop App is simpler for single-user; Docker if you also want the API exposed to local-LAN. |
| Any Kubernetes cluster | (no upstream Helm chart) | Workaround: convert the upstream `docker-compose` to a Deployment + PVC manually, or use Kompose. Treat as community-maintained. |
| **Render / Railway / RepoCloud / Elestio / Northflank** | (vendor-managed) | One-click — see *Cloud one-click deploys* above. |

---

## Verification before marking `provision` done

- Container running: `docker ps | grep anythingllm` shows `Up` + healthy. Or systemd-user units `is-active`.
- HTTP health: `curl -sIo /dev/null -w '%{http_code}\n' http://127.0.0.1:3001/` returns `200`.
- API: `curl -s http://127.0.0.1:3001/api/ping` returns `{"online":true}`.
- Browser loads the UI; first-launch *Get Started* wizard appears.
- After completing the setup wizard:
  - LLM provider configured (model dropdown shows ≥ 1 model).
  - Embedder configured (default native works without keys; first embedding triggers model download — verify by uploading a small `.txt` file and checking the workspace's *Documents* tab).
  - Vector DB selected (LanceDB default needs no config; for external DBs verify the connection from *Settings → Vector Database*).
- Workspace round-trip: create a workspace, upload a `.txt`, ask a question that requires the doc — confirms the full chain (collector → embedder → vector DB → LLM).
- (If multi-user) Enable multi-user, invite a test user — confirms session-token + JWT plumbing.

---

## Consolidated gotchas

Universal:

- **Storage path is sacred.** `STORAGE_DIR` (Docker bind mount, bare-metal absolute path, Desktop app-data dir) holds workspaces, embeddings, users, prompts, agents. Lose it = lose everything. Back it up.
- **`SIG_KEY` + `SIG_SALT` rotation breaks every stored API key.** Set once and treat as immutable.
- **`JWT_SECRET` rotation logs everyone out.** Set explicitly to control rotation timing.
- **Provider keys live in SQLite (encrypted via SIG_KEY/SIG_SALT), not env vars** — config is via the Settings UI. Env vars are first-launch defaults.
- **LanceDB is on-disk single-node.** For multi-node / HA, switch to an external vector DB.
- **Switching vector DBs requires re-embedding every workspace.** No migration tool.
- **Bare-metal is explicitly unsupported by upstream.** Surface this caveat to the user before they invest time.
- **Document scraper needs `SYS_ADMIN` capability in Docker.** Don't drop it — silent ingestion failure is the symptom.
- **Two processes (server + collector) in bare-metal.** Forgetting collector = silent ingestion failure.
- **Reverse-proxy WebSocket headers are mandatory.** For chat streaming + agent invocation. Forgetting them = chat loads but never streams.

Per-method gotchas live alongside each section above:

- **Docker** — see *Docker-specific gotchas* + `runtimes/docker.md` § *Common gotchas*.
- **Desktop App** — see *Desktop-specific gotchas*.
- **Bare metal** — see *Bare-metal-specific gotchas* + `runtimes/native.md` § *Common gotchas*.
- **Cloud one-click** — see *Cloud-one-click gotchas*.

---

## TODO — verify on subsequent deployments

- **First end-to-end Docker deploy** on Linux + a real domain — verify `--cap-add SYS_ADMIN`, `host.docker.internal` resolution, document upload + RAG round-trip.
- **Docker Compose with Ollama as both LLM + embedder** — verify the `EMBEDDING_ENGINE=ollama` + `EMBEDDING_MODEL_PREF=nomic-embed-text` path works, including auto-pull of the embedder model.
- **Desktop App on macOS / Windows / Linux** — never validated. Verify Gatekeeper / SmartScreen / AppImage sandbox quirks.
- **Bare-metal install** — never validated. Verify Node 18 specifically + the two-process systemd-user pattern + Nginx / Caddy reverse-proxy WebSocket config.
- **AWS CloudFormation template** — verify against current AnythingLLM image tag; verify EBS-volume backup pattern; verify teardown leaves no orphans.
- **DigitalOcean Terraform template** — same as AWS; verify Reserved IP attachment behavior on droplet recreate.
- **GCP Cloud Run + GCS** — verify LanceDB on GCS works (write-only? eventual-consistency issues?). May need to switch to an external vector DB on Cloud Run.
- **Render / Railway / RepoCloud / Elestio / Northflank** — none has been exercised. Browser-driven flows; first user to deploy via each should fold gotchas back into the relevant subsection.
- **External vector-DB integrations** (Pinecone / Weaviate / Qdrant / Chroma / Milvus / Astra / pgvector) — only LanceDB has been (mentally) walked through. Verify connection-string format + auth handling per provider.
- **Multi-user mode end-to-end** — invite flow, role-based permissions, password-reset email plumbing.
- **OpenAI-compatible API + per-workspace API keys** — for composing AnythingLLM with Open WebUI / LibreChat / OpenClaw / Hermes / Aider as the upstream RAG layer. Document the exact base URL pattern + auth header format.
- **Browser extension + embed widget** — server-mode-only features; verify CORS configuration + the embed-widget JS snippet works against a public-domain deploy.
- **Major-version migrations** — verify Prisma migration path on `git pull` across at least one upstream major-version bump.
- **Backup + restore drill** — `STORAGE_DIR` tar + restore on fresh host; verify workspaces / embeddings / users / prompts all survive.
- **`SIG_KEY` rotation procedure** — what happens if a user wants to rotate? Verify the "drop tokens" workaround vs documented re-encrypt flow.