---
name: open-webui-project
description: Open WebUI recipe for open-forge — a feature-rich web UI for any OpenAI-compatible LLM backend (github.com/open-webui/open-webui, ~70k★). Pairs naturally with Ollama (the most-deployed pairing) but also speaks raw OpenAI / Anthropic / Azure / any custom OpenAI-compatible endpoint. Beyond chat: RAG, web search, image generation (Stable Diffusion / DALL-E), voice (TTS/STT), MCP tools, function calls, multi-user with role-based access. Covers every upstream-blessed install method: pip (Python 3.11), Docker (`:main` / `:cuda` / `:ollama` / `:dev` tags), docker-compose (with bundled Ollama or external), and Kubernetes via Kustomize / Helm (pointer to upstream docs, no in-repo manifests). Pairs with `references/runtimes/{docker,native,kubernetes}.md` and `references/infra/*.md`.
---

# Open WebUI

A self-hosted, feature-rich web UI for any OpenAI-compatible LLM backend. Started as the Ollama UI and grew to support OpenAI / Anthropic / Azure / Bedrock / any OpenAI-compatible endpoint. Adds a stack of features beyond raw chat: RAG over uploaded documents, web search (SearXNG / Tavily / Brave / etc.), image generation (Stable Diffusion / ComfyUI / DALL-E / Automatic1111), voice (Whisper STT + multiple TTS providers), MCP tool calls, function calls, multi-user with admin / user / pending roles, model permissions per-user/group, prompt templates, Pipelines for plugin-style extensions.

Default port `8080`; most Docker examples remap to host `3000`. State + SQLite database live at `/app/backend/data` inside the container — losing this volume = losing all chats, users, RAG indexes, settings.

Upstream: <https://github.com/open-webui/open-webui> — docs at <https://docs.openwebui.com>.

## Compatible combos

| How (runtime / install) | Module | Notes |
|---|---|---|
| **Docker** (image `ghcr.io/open-webui/open-webui`, multiple tags) | `runtimes/docker.md` + project section below | Recommended default. Tags: `:main` / `:cuda` (GPU for embeddings/OCR/image gen) / `:ollama` (bundles Ollama in same container) / `:dev`. |
| **Docker Compose** (upstream ships variants for GPU / API-only / observability) | `runtimes/docker.md` + project section below | Easiest "Open WebUI + Ollama in one stack" path. |
| **pip** (`pip install open-webui`; Python 3.11 required) | `runtimes/native.md` + project section below | When you want Open WebUI as a Python service alongside other Python apps; or for development. |
| **Kubernetes** (Kustomize manifests + community Helm chart at upstream docs) | `runtimes/kubernetes.md` + project section below | Upstream README mentions kubectl / Kustomize / Helm but ships no in-repo manifests; refer to docs.openwebui.com. |

For the **where** axis, pick any infra adapter under `references/infra/`. Open WebUI is light on its own — the heavy resources are the backend it points at (Ollama, OpenAI API, etc.). It runs comfortably on a 2 GB / 1 vCPU VPS when the LLM is elsewhere.

## Inputs to collect

| Phase | Prompt | Tool | Notes |
|---|---|---|---|
| preflight | "What do you want to host?" | (inferred from "Open WebUI" in user's ask) | — |
| preflight | "Where?" | `AskUserQuestion`: AWS / Azure / Hetzner / DO / GCP / Oracle / Hostinger / Pi / macOS-VM / BYO VPS / localhost / Kubernetes | Loads matching infra adapter |
| preflight | "How?" (dynamic from combo table) | `AskUserQuestion`: Docker / Docker Compose / pip / Kubernetes-Helm | — |
| preflight | "Backend?" | `AskUserQuestion`: Ollama-on-same-host / Ollama-on-remote-host / OpenAI / Anthropic / Azure OpenAI / Other OpenAI-compatible / Multiple | Drives `OLLAMA_BASE_URL` + `OPENAI_API_KEY` + `OPENAI_API_BASE_URL` configuration |
| preflight | "Image variant?" (Docker only) | `AskUserQuestion`: `:main` (default — points at remote LLM) / `:cuda` (NVIDIA GPU for built-in features) / `:ollama` (bundles Ollama; CPU or GPU) / `:dev` (development branch) | Defaults to `:main` |
| provision | "Backend URL?" | Free-text | e.g. `http://host.docker.internal:11434` (host Ollama from container) / `http://ollama:11434` (compose service name) / your remote URL |
| provision | "API key for OpenAI-compatible backend?" | Free-text (sensitive) | Skipped for Ollama-only deploys |
| provision | "WEBUI_SECRET_KEY?" | Free-text or auto-generated (`openssl rand -hex 32`) | Treat as admin-grade secret. Auto-rotate by restarting with a new value invalidates all sessions. |
| provision | "Public domain?" (optional) | Free-text | Triggers Caddy / nginx + cert-manager / Let's Encrypt setup via runtimes/native.md. |
| provision | "Disable signup?" | `AskUserQuestion`: `Yes (single-user / closed)` / `No (open signup)` / `Pending approval (admin approves new users)` | Maps to `WEBUI_AUTH=False` (single-user, no auth) / signup-enabled / `ENABLE_SIGNUP=false` (admin-creates-users) |

Project-conditional outputs:

| Recorded as | Derived from |
|---|---|
| `outputs.public_url` | `https://<domain>` or `http://<host>:3000` |
| `outputs.image_tag` | `:main` / `:cuda` / `:ollama` / `:dev` |
| `outputs.data_volume` | `open-webui:/app/backend/data` (named volume) or `~/open-webui-data` (bind mount) |
| `outputs.backends` | List of configured LLM backends (e.g. `["ollama", "openai"]`) |

## Software-layer concerns (apply to every deployment)

### What you're hosting

A FastAPI backend (Python 3.11) + SvelteKit frontend bundled into one container/process. The backend serves the UI, brokers requests to LLM providers, runs the RAG indexer, hosts the multi-user database, and exposes its own OpenAI-compatible API for clients that want to talk to it instead of the underlying LLM.

### Image variants — pick the right one

| Tag | When | Size |
|---|---|---|
| `ghcr.io/open-webui/open-webui:main` | **Default.** Points at a remote LLM (Ollama, OpenAI, etc.). No GPU support inside the container — the container itself doesn't run models. | ~1 GB |
| `ghcr.io/open-webui/open-webui:cuda` | When you want **built-in features that run locally**: embeddings (RAG), Whisper STT, document OCR, image gen via integrated Stable Diffusion. Needs `--gpus=all` + NVIDIA Container Toolkit. | ~5 GB |
| `ghcr.io/open-webui/open-webui:ollama` | Bundles Ollama in the same container. One-stop deploy when you don't want to manage Ollama separately. CPU + GPU variants. | ~2 GB + model size |
| `ghcr.io/open-webui/open-webui:dev` | Tracks the development branch — bleeding-edge features, occasionally broken. Avoid for production. | ~1 GB |

If you're already running Ollama (per the Ollama recipe in this skill), use `:main`. If you want everything in one container, use `:ollama`. Use `:cuda` only when the *Open WebUI features themselves* need a GPU (embeddings, image gen) — not for chat throughput, which is the LLM backend's job.

### State — persistent volume is mandatory

```text
/app/backend/data/
├── webui.db                  # SQLite — users, chats, settings, RAG indexes (default; swap to Postgres for multi-user prod)
├── uploads/                  # Files uploaded for RAG
├── cache/                    # Model + embedding caches
├── vector_db/                # ChromaDB / Qdrant index files (RAG)
├── docs/                     # Indexed knowledge bases
└── audit.log                 # Auth + admin actions
```

Upstream's README is explicit: **"include the `-v open-webui:/app/backend/data`"**. Without it, every container restart wipes users / chats / RAG. Bind-mounting a host directory works just as well as a named volume, and is easier to back up.

### Authentication + multi-user model

| Mode | Set via | Behavior |
|---|---|---|
| **Single-user, no auth** | `WEBUI_AUTH=False` | Anyone hitting the URL gets in. Use only on `127.0.0.1` or behind a separate auth layer. |
| **Multi-user, open signup** (default) | `ENABLE_SIGNUP=true` (default) | First user to register becomes admin. Subsequent users are regular `user` role. |
| **Multi-user, admin-approves** | `ENABLE_SIGNUP=false` | Admin creates users in the UI; new self-registrations rejected. Recommended for any non-localhost deployment. |
| **OAuth / OIDC** | `OAUTH_*` env vars | Federate with Google / Microsoft / Discord / GitHub / generic OIDC. See upstream docs. |
| **Trusted-header / proxy auth** | `WEBUI_AUTH_TRUSTED_EMAIL_HEADER` | When fronting with Authelia / Authentik / oauth2-proxy. |

Roles: `pending` (signup-not-yet-approved) → `user` (chat) → `admin` (manage users, models, settings). The admin role is bootstrapped from whoever registers first when `ENABLE_SIGNUP=true`.

### Connecting to backends

Open WebUI can talk to multiple LLM backends simultaneously. Configure via env vars (auto-loaded into the UI's *Connections* settings), or add them via the UI after first launch.

```bash
# Ollama (single backend)
OLLAMA_BASE_URL=http://host.docker.internal:11434       # Docker → host Ollama
OLLAMA_BASE_URL=http://ollama:11434                     # docker-compose service name
OLLAMA_BASE_URL=http://10.0.0.5:11434                   # remote Ollama on LAN

# OpenAI / Anthropic / Azure / any OpenAI-compatible
OPENAI_API_KEY=sk-...
OPENAI_API_BASE_URL=https://api.openai.com/v1           # default; override for Azure / custom
# Multiple OpenAI-compat backends are supported via ;-separated lists:
OPENAI_API_BASE_URLS=https://api.openai.com/v1;https://api.anthropic.com
OPENAI_API_KEYS=sk-...;sk-ant-...

# Disable a backend you don't want
ENABLE_OLLAMA_API=False
ENABLE_OPENAI_API=False
```

The UI's *Settings → Connections* is the runtime equivalent — env vars set defaults, UI changes override and persist to the DB.

### Critical environment variables

| Variable | Default | Purpose |
|---|---|---|
| `WEBUI_SECRET_KEY` | random per-restart | **Set this explicitly to avoid logging-out-everyone-on-restart.** Treat as admin-grade. |
| `OLLAMA_BASE_URL` | `http://localhost:11434` | Ollama endpoint |
| `OPENAI_API_KEY`, `OPENAI_API_BASE_URL` | unset | OpenAI / OpenAI-compat backend |
| `WEBUI_AUTH` | `True` | `False` = single-user mode (no auth at all) |
| `ENABLE_SIGNUP` | `True` | `False` = admin-creates-users-only |
| `DEFAULT_USER_ROLE` | `pending` | New self-registrations land in this role; admin must approve |
| `WEBUI_NAME` | `Open WebUI` | Branding |
| `WEBUI_URL` | unset | Used in OAuth callbacks; required if behind a reverse proxy |
| `DATABASE_URL` | sqlite at `/app/backend/data/webui.db` | Set to `postgresql://...` for multi-user production |
| `ENABLE_RAG_WEB_SEARCH` | `False` | Toggle web search; pair with `RAG_WEB_SEARCH_ENGINE` (`searxng`/`tavily`/`brave`/etc.) |
| `RAG_EMBEDDING_ENGINE` | `""` (uses Ollama if `OLLAMA_BASE_URL` is set) | `"ollama"` / `"openai"` / built-in sentence-transformers |
| `IMAGE_GENERATION_ENGINE` | unset | `"automatic1111"` / `"comfyui"` / `"openai"` for image gen |
| `AUDIO_STT_ENGINE`, `AUDIO_TTS_ENGINE` | local Whisper, browser TTS | `"openai"` / `"elevenlabs"` / etc. |
| `CORS_ALLOW_ORIGIN` | `*` | Lock down for production |
| `ENABLE_API_KEY` | `True` | Allows users to generate per-account API keys to use Open WebUI as their own OpenAI-compatible endpoint |

For the full env-var matrix, see <https://docs.openwebui.com/getting-started/env-configuration>.

### Open WebUI as an OpenAI-compatible endpoint

Once running, Open WebUI itself exposes `/api/chat/completions` (its own API) and `/v1/chat/completions` (OpenAI-compatible). User generates an API key in *Settings → Account → API Keys*; clients then point at `http://<webui-host>:8080/v1` with that key.

This lets agents (OpenClaw, Hermes, Aider) talk to Open WebUI instead of the underlying LLM directly — useful when Open WebUI is doing routing / RAG / model permissions and you want the agent to inherit those.

### Security model

| Surface | Default | Hardening |
|---|---|---|
| HTTP bind | `0.0.0.0:8080` (in container) → mapped to host port | Pair with reverse proxy + TLS for any non-localhost exposure |
| Auth | open signup → first-user-is-admin | Set `ENABLE_SIGNUP=false` after admin account exists |
| `WEBUI_SECRET_KEY` | randomized per restart if unset | Set explicitly; rotate by restart |
| CORS | `*` | Set `CORS_ALLOW_ORIGIN` to the exact origin |
| Backend creds | env vars | Env vars beat config-in-DB for ops; backend keys via env, user-specific via UI |
| Audit | enabled | `audit.log` in the data dir; ship to your log aggregator |

### Composing with Ollama (the default pairing)

Two patterns:

1. **Open WebUI in Docker → Ollama on host**: `OLLAMA_BASE_URL=http://host.docker.internal:11434` + `--add-host=host.docker.internal:host-gateway` on the Open WebUI container. Linux Docker needs the `--add-host` flag; Docker Desktop (mac/win) provides it automatically.
2. **Open WebUI + Ollama in docker-compose**: both as services on a shared network; `OLLAMA_BASE_URL=http://ollama:11434`. See *Docker Compose* section below.

For Ollama on a separate host (LAN or VPC), point at its IP/DNS. Make sure Ollama is bound to a non-loopback interface (`OLLAMA_HOST=0.0.0.0:11434`) — by default Ollama is loopback-only and won't accept connections from another host. See the Ollama recipe in this skill for `OLLAMA_HOST` configuration.

---

## pip install (Python 3.11 native)

When the user wants Open WebUI as a Python service alongside other Python apps, in a pyenv/asdf-managed environment, or for development. Pair with [`references/runtimes/native.md`](../runtimes/native.md) for Python prereqs and daemon-lifecycle basics.

Upstream docs: <https://docs.openwebui.com/getting-started/quick-start/manual>.

### Prereq: Python 3.11 specifically

Open WebUI requires Python **3.11** — not 3.10 (missing typing features) and not 3.12+ (some dependencies don't support it yet). Verify before installing.

```bash
# macOS — Homebrew
brew install python@3.11
python3.11 --version

# Debian/Ubuntu — Deadsnakes PPA (default repos often ship older 3.10 only)
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt-get update
sudo apt-get install -y python3.11 python3.11-venv python3.11-dev
python3.11 --version

# RHEL/Fedora
sudo dnf install -y python3.11 python3.11-devel
python3.11 --version
```

### Install + first run

```bash
# Always use a venv — pip-installing into the system Python is hostile to other apps
python3.11 -m venv ~/open-webui/venv
source ~/open-webui/venv/bin/activate
pip install --upgrade pip wheel
pip install open-webui

# Configure backend(s) before first run
export OLLAMA_BASE_URL=http://localhost:11434
export WEBUI_SECRET_KEY="$(openssl rand -hex 32)"

open-webui serve     # binds 0.0.0.0:8080 by default; --port to override
```

Then open `http://<host>:8080` in a browser. The first user to register becomes admin.

### Daemon lifecycle (systemd-user, Linux)

```bash
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/open-webui.service <<EOF
[Unit]
Description=Open WebUI
After=network-online.target

[Service]
Type=simple
WorkingDirectory=%h/open-webui
EnvironmentFile=%h/open-webui/.env
ExecStart=%h/open-webui/venv/bin/open-webui serve
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
EOF

# Put env vars in ~/open-webui/.env (one KEY=value per line, no quotes, no `export`)
cat > ~/open-webui/.env <<EOF
OLLAMA_BASE_URL=http://localhost:11434
WEBUI_SECRET_KEY=$(openssl rand -hex 32)
ENABLE_SIGNUP=false
EOF
chmod 600 ~/open-webui/.env

systemctl --user daemon-reload
systemctl --user enable --now open-webui
sudo loginctl enable-linger "$USER"     # so service survives logout
journalctl --user -u open-webui -f
```

### Updating

```bash
source ~/open-webui/venv/bin/activate
pip install --upgrade open-webui
systemctl --user restart open-webui
```

### Uninstall

```bash
systemctl --user disable --now open-webui
rm ~/.config/systemd/user/open-webui.service
rm -rf ~/open-webui
# Data is in ~/.open-webui/ by default — wipe explicitly if you want
rm -rf ~/.open-webui
```

### pip-specific gotchas (Open WebUI-only)

- **Python 3.11 specifically.** 3.10 will fail to start (typing features); 3.12+ may fail at install (dep compat) or at runtime. Pin to 3.11.
- **First start downloads embedding models.** The default RAG embedder is `sentence-transformers/all-MiniLM-L6-v2` (~80 MB). First request that uses RAG triggers the download — slow on first hit.
- **Default data dir on pip is `~/.open-webui/`** — not `/app/backend/data/` (that's the Docker convention). Override with `DATA_DIR=/some/path` if you want it elsewhere.
- **The `cuda` and `ollama` Docker variants don't have a pip equivalent.** pip is for the slim "talks to remote LLM" deploy; for built-in GPU features (image gen, CUDA-accelerated RAG embedder), use the `:cuda` Docker image.
- **`open-webui serve` binds `0.0.0.0:8080` by default.** Override with `--host 127.0.0.1` and front with a reverse proxy for any production deployment.

---

## Docker (recommended default)

Pair with [`references/runtimes/docker.md`](../runtimes/docker.md) for host-level Docker install + lifecycle.

Image: `ghcr.io/open-webui/open-webui` on GitHub Container Registry. Tags listed in *Image variants* above.

### `:main` — pointing at remote Ollama on the host

```bash
docker run -d \
  --name open-webui \
  --restart always \
  -p 127.0.0.1:3000:8080 \
  -v open-webui:/app/backend/data \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  -e WEBUI_SECRET_KEY="$(openssl rand -hex 32)" \
  --add-host=host.docker.internal:host-gateway \
  ghcr.io/open-webui/open-webui:main
```

`--add-host=host.docker.internal:host-gateway` is mandatory on Linux (Docker Desktop on macOS/Windows provides it automatically). Without it, `host.docker.internal` doesn't resolve and Open WebUI can't reach host-running Ollama.

### `:main` — pointing at remote Ollama on another host

```bash
docker run -d --name open-webui --restart always \
  -p 127.0.0.1:3000:8080 \
  -v open-webui:/app/backend/data \
  -e OLLAMA_BASE_URL=http://10.0.0.5:11434 \
  -e WEBUI_SECRET_KEY="$(openssl rand -hex 32)" \
  ghcr.io/open-webui/open-webui:main
```

Make sure the remote Ollama is bound to `0.0.0.0` (not just localhost) and the network path is open.

### `:main` — OpenAI-only (no Ollama)

```bash
docker run -d --name open-webui --restart always \
  -p 127.0.0.1:3000:8080 \
  -v open-webui:/app/backend/data \
  -e OPENAI_API_KEY=sk-... \
  -e ENABLE_OLLAMA_API=False \
  -e WEBUI_SECRET_KEY="$(openssl rand -hex 32)" \
  ghcr.io/open-webui/open-webui:main
```

### `:cuda` — when Open WebUI's local features need GPU

For built-in features that run inside the container (RAG embeddings, Whisper STT, OCR, integrated Stable Diffusion), the CUDA image needs `--gpus=all` + NVIDIA Container Toolkit on the host (see Ollama recipe Docker section for installing the toolkit).

```bash
docker run -d --name open-webui --restart always \
  --gpus=all \
  -p 127.0.0.1:3000:8080 \
  -v open-webui:/app/backend/data \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  -e WEBUI_SECRET_KEY="$(openssl rand -hex 32)" \
  --add-host=host.docker.internal:host-gateway \
  ghcr.io/open-webui/open-webui:cuda
```

Use `:cuda` only when you're running RAG, image gen, or local audio inside Open WebUI. Chat-only deployments don't benefit from `:cuda`.

### `:ollama` — Open WebUI + Ollama in one container (CPU)

For "I just want one thing to deploy" use cases:

```bash
docker run -d --name open-webui --restart always \
  -p 127.0.0.1:3000:8080 \
  -v open-webui:/app/backend/data \
  -v ollama:/root/.ollama \
  -e WEBUI_SECRET_KEY="$(openssl rand -hex 32)" \
  ghcr.io/open-webui/open-webui:ollama
```

Two volumes — one for the WebUI database, one for Ollama models. Both must persist.

### `:ollama` — Open WebUI + Ollama in one container (NVIDIA GPU)

```bash
docker run -d --name open-webui --restart always \
  --gpus=all \
  -p 127.0.0.1:3000:8080 \
  -v open-webui:/app/backend/data \
  -v ollama:/root/.ollama \
  -e WEBUI_SECRET_KEY="$(openssl rand -hex 32)" \
  ghcr.io/open-webui/open-webui:ollama
```

### Docker Compose — Open WebUI + external Ollama

Upstream ships `docker-compose.yaml` that pairs Open WebUI with Ollama as separate services. Recommended starting point for production:

```yaml
services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    restart: unless-stopped
    volumes:
      - ollama:/root/.ollama
    # For NVIDIA GPU, uncomment:
    # deploy:
    #   resources:
    #     reservations:
    #       devices:
    #         - driver: nvidia
    #           count: all
    #           capabilities: [gpu]

  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    restart: always
    depends_on:
      - ollama
    ports:
      - "127.0.0.1:3000:8080"
    volumes:
      - open-webui:/app/backend/data
    environment:
      - OLLAMA_BASE_URL=http://ollama:11434
      - WEBUI_SECRET_KEY=${WEBUI_SECRET_KEY}
      - ENABLE_SIGNUP=false      # set to true on first deploy to register the admin
    extra_hosts:
      - "host.docker.internal:host-gateway"

volumes:
  ollama:
  open-webui:
```

Bring up:

```bash
export WEBUI_SECRET_KEY="$(openssl rand -hex 32)"
echo "WEBUI_SECRET_KEY=$WEBUI_SECRET_KEY" > .env

docker compose up -d
docker compose logs -f open-webui

# First-time admin registration: temporarily set ENABLE_SIGNUP=true,
# register the admin user, then flip back to false and `docker compose up -d`
```

For GPU pairing, use upstream's variants: `docker-compose.gpu.yaml` (generic NVIDIA via the `nvidia` runtime) or `docker-compose.amdgpu.yaml` (AMD ROCm). Upstream does **not** ship a separate `docker-compose.cuda.yaml`.

```bash
docker compose -f docker-compose.yaml -f docker-compose.gpu.yaml up -d
```

### Lifecycle

```bash
docker compose ps
docker compose logs -f open-webui
docker compose restart open-webui
docker compose pull && docker compose up -d --force-recreate    # upgrade
docker compose exec open-webui sqlite3 /app/backend/data/webui.db ".tables"   # poke at DB
```

The named volumes survive `docker compose down`. Use `docker compose down -v` to wipe state (destructive).

### Reverse proxy + TLS (production)

Open WebUI doesn't terminate TLS itself. Front with Caddy (simplest):

```text
# /etc/caddy/Caddyfile
chat.example.com {
  reverse_proxy 127.0.0.1:3000
}
```

Caddy fetches Let's Encrypt certs automatically. Or use nginx + certbot per `references/runtimes/native.md` § *Reverse proxy*.

For OAuth: set `WEBUI_URL=https://chat.example.com` so the OAuth callback URLs match. Forgetting this breaks the OAuth round-trip (callback shows up at `localhost:3000/...` instead of your domain).

### Docker-specific gotchas (Open WebUI-only)

- **`open-webui` named volume — DON'T LOSE IT.** Wiping the volume destroys all users / chats / RAG indexes. Back up the volume regularly: `docker run --rm -v open-webui:/data -v "$PWD":/backup alpine tar czf /backup/open-webui-$(date +%F).tgz -C /data .`.
- **`--add-host=host.docker.internal:host-gateway` is mandatory on Linux.** Forgetting it makes "host Ollama" deploys fail mysteriously — the UI shows "no models" because the backend can't resolve `host.docker.internal`.
- **First user becomes admin — guard the URL during initial setup.** If you spin up Open WebUI on a public IP with default `ENABLE_SIGNUP=true`, whoever hits it first gets admin. Either bind to `127.0.0.1`, set up a firewall rule, or pre-provision an admin via the env-var `WEBUI_ADMIN_EMAIL` / `WEBUI_ADMIN_PASSWORD` (verify in upstream docs).
- **`WEBUI_SECRET_KEY` randomized per restart by default = users logged out after every container restart.** Always set explicitly.
- **`:ollama` image bundles Ollama — don't run a second Ollama on the host.** They'll fight for port 11434. Pick one.
- **Image variants are NOT cross-compatible.** A volume created with `:main` + external Ollama won't necessarily work with `:ollama` (different paths). Don't swap variants on a populated volume — fresh deploy or migrate intentionally.
- **`ENABLE_SIGNUP=false` blocks ALL new registrations including the first admin.** The bootstrap pattern is: first start with `true`, register admin, set to `false`, restart.

---

## Kubernetes (Kustomize / Helm — community)

When the user picks **any k8s cluster → Kubernetes**. Pair with [`references/runtimes/kubernetes.md`](../runtimes/kubernetes.md) for kubectl + Helm prereqs and Secret hygiene.

> **Verify the manifest source first.** Open WebUI upstream's README mentions kubectl / Kustomize / Helm support but does **not ship in-repo manifests**. The k8s deploy options are documented at <https://docs.openwebui.com/getting-started/quick-start/advanced-topics/kubernetes>. Multiple community Helm charts exist (`open-webui/helm-charts` is the most-used); confirm with the user which they intend.

### Helm (community chart, illustrative)

```bash
helm repo add open-webui https://helm.openwebui.com
helm repo update

kubectl create namespace open-webui

helm upgrade --install open-webui open-webui/open-webui \
  --namespace open-webui --create-namespace \
  --set ollama.enabled=true \
  --set ollama.gpu.enabled=true \
  --set ollama.gpu.type=nvidia \
  --set persistence.enabled=true \
  --set persistence.size=20Gi \
  --set ingress.enabled=true \
  --set ingress.host=chat.example.com \
  --set ingress.tls.enabled=true \
  --set webuiSecretKey=$(openssl rand -hex 32)
```

Always `helm show values open-webui/open-webui > /tmp/defaults.yaml` first — community chart value schemas drift; the keys above are illustrative.

### Verify + access

```bash
kubectl -n open-webui rollout status deploy/open-webui
kubectl -n open-webui logs deploy/open-webui -f
kubectl -n open-webui port-forward svc/open-webui 3000:8080
# Then open http://localhost:3000
```

For public exposure via Ingress, pair with cert-manager + an ingress controller. Don't expose without auth at the Ingress level — Open WebUI's first-user-becomes-admin pattern is risky on a public hostname during the initial-setup window.

### Kubernetes-specific gotchas

- **No first-party manifests.** Charts vary; verify schema before committing to one.
- **PVC reclaim policy.** Default `Delete` reclaim wipes the WebUI database on `helm uninstall`. For long-lived clusters, switch the StorageClass to `Retain` or take regular SQLite/Postgres backups.
- **Ingress + auth race condition.** If the Ingress is up before you've registered the admin, anyone can grab the role. Either deploy with `ENABLE_SIGNUP=false` first + bootstrap via env vars, or restrict the Ingress (NetworkPolicy / IP allowlist) until admin is set.
- **Embedding model downloads in pod = slow first start.** First pod after `helm install` downloads embedding models (~80 MB+) before serving. Liveness probe needs a generous initial delay.
- **Postgres recommended for multi-replica.** SQLite on a shared PVC across replicas = corruption. Set `DATABASE_URL=postgres://...` and run only when you have a real Postgres.

---

## Per-cloud / per-PaaS pointers

Open WebUI runs anywhere a Linux container runs. The combo with Ollama dictates GPU concerns; on its own (talking to remote OpenAI), it's light enough for the smallest tier of any provider.

| Where | Adapter | Typical setup |
|---|---|---|
| AWS Lightsail | `infra/aws/lightsail.md` | Docker + remote LLM (Lightsail GPU options are limited) |
| AWS EC2 | `infra/aws/ec2.md` | Docker + Ollama on same instance (g5/g6 for GPU) |
| Azure VM | `infra/azure/vm.md` | Docker + remote-or-local Ollama |
| Hetzner | `infra/hetzner/cloud-cx.md` | Docker; CPU-only (CX has no GPU; use Hetzner GEX series for GPU) |
| DigitalOcean | `infra/digitalocean/droplet.md` | Docker; GPU Droplets for combined Ollama + Open WebUI |
| GCP | `infra/gcp/compute-engine.md` | Docker + remote-or-local Ollama |
| Oracle Cloud (free ARM) | `infra/oracle/free-tier-arm.md` | pip or Docker; the `:main` ARM image works (verify); CPU-only |
| Hostinger | `infra/hostinger.md` | Docker via Hostinger Docker Manager |
| Raspberry Pi | `infra/raspberry-pi.md` | pip install (Docker works but heavy on Pi); pair with remote Ollama |
| BYO Linux VPS | `infra/byo-vps.md` | Any of the above |
| localhost | `infra/localhost.md` | Docker (`:main` or `:ollama` for one-stop) |
| Any Kubernetes cluster | (user-provided) | Helm chart |

PaaS adapters: **Fly.io** is a clean fit for `:main` (point at a remote Ollama or OpenAI; persistent volume for the SQLite DB). Render and Railway also work for the `:main` deploy. The `:ollama` and `:cuda` variants need GPU machines, which limits PaaS options to Fly's GPU machines or providers like Modal / RunPod (out of scope for this recipe; treat as TODO).

---

## Verification before marking `provision` done

- Container or process running: `docker ps | grep open-webui` / `systemctl --user is-active open-webui` / `kubectl -n open-webui get pods`.
- HTTP health: `curl -sI http://127.0.0.1:3000/` returns `200 OK` (or the configured port).
- API health: `curl -s http://127.0.0.1:3000/api/config` returns valid JSON with the configured backends.
- Browser opens the UI; admin can register (or pre-existing admin can log in).
- At least one model from the configured backend appears in the model picker — confirms the `OLLAMA_BASE_URL` / `OPENAI_API_KEY` plumbing works end-to-end.
- One test message round-trips (UI sends → backend receives → response renders) — confirms the full chain.

---

## Consolidated gotchas

Universal:

- **The state volume is sacred.** `/app/backend/data` (Docker) or `~/.open-webui/` (pip) holds users, chats, RAG indexes, settings. Lose it = lose everything. Back it up.
- **`WEBUI_SECRET_KEY` must be set explicitly.** Default randomizes per restart, which logs out everyone. Generate once with `openssl rand -hex 32` and persist it.
- **First user = admin.** During initial setup, restrict access (firewall, `127.0.0.1` bind, NetworkPolicy) until you've registered the admin and disabled signup.
- **Open WebUI is the UI; it does not run models.** The LLM runs elsewhere — Ollama, OpenAI, Anthropic, Azure, or any OpenAI-compatible endpoint. The `:ollama` image bundles Ollama in the same container for convenience, but they're separable.
- **Image variants matter.** `:main` for "talk to remote LLM"; `:cuda` only for in-container GPU features (RAG embeddings, image gen, OCR); `:ollama` for one-stop bundle. Don't pick `:cuda` thinking it speeds up chat — it doesn't.
- **`host.docker.internal` requires `--add-host=host.docker.internal:host-gateway` on Linux.** Forgetting this is the #1 cause of "Open WebUI can't see my host Ollama."

Per-method gotchas:

- **Docker** — see *Docker-specific gotchas* + `runtimes/docker.md` § *Common gotchas*.
- **pip** — see *pip-specific gotchas* + `runtimes/native.md` § *Common gotchas*.
- **Kubernetes** — see *Kubernetes-specific gotchas* + `runtimes/kubernetes.md` § *Common gotchas*.

---

## TODO — verify on subsequent deployments

- **First end-to-end Docker `:main` + remote Ollama** on Linux (verify `--add-host` claim) and Docker Desktop (macOS).
- **`:ollama` bundled image** — verify the GPU variant works with NVIDIA Container Toolkit; verify the volume layout for both webui and ollama state across container recreate.
- **`:cuda` image** — verify which features actually use GPU (RAG embeddings? image gen? STT?) and whether the upgrade from `:main` is non-destructive.
- **pip install on Python 3.11** — verify the systemd-user lifecycle pattern; verify embedding model auto-download behavior.
- **Helm chart** — verify which community chart is most actively maintained; confirm the value schema. Consider whether open-forge should standardize on one.
- **OAuth / OIDC providers** — never tested. Verify OAuth callback behavior with `WEBUI_URL` set vs unset; verify the trusted-header pattern with oauth2-proxy.
- **Multi-user Postgres deployment** — verify `DATABASE_URL=postgresql://...` migration from default SQLite (or do you start fresh?).
- **Composing with OpenClaw / Hermes / Aider via Open WebUI's API** — never tested. Verify the per-user API-key flow + `/v1/chat/completions` shape matches what each agent expects.
- **PaaS feasibility on Fly.io** — write an Open WebUI-specific `fly.toml` if there's user demand. Render / Railway one-click templates exist in upstream community channels — verify and link.
- **Backup + restore drill** — document the exact procedure for backing up the SQLite DB + uploaded files + vector DB, and restoring to a fresh instance. Critical for any production deploy.
- **Embedding model + RAG behavior** — first-pull blocking, default `all-MiniLM-L6-v2` model size, switching to Ollama-hosted embeddings for better quality.