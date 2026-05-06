---
name: lobehub
description: LobeHub recipe for open-forge. Covers Docker Compose self-hosted deployment (recommended) using the upstream setup.sh script. LobeHub is a modern AI chat framework and agent workspace supporting multiple AI providers, MCP marketplace, and collaborative agent workflows.
---

# LobeHub

Modern AI chat framework and human-agent collaboration workspace. Supports multiple AI providers (OpenAI, Anthropic, Gemini, Ollama, and more), one-click MCP marketplace, Artifacts/Thinking, TTS/STT voice, image generation, file upload/RAG knowledge base, and multi-user management. Upstream: <https://github.com/lobehub/lobehub>. Docs: <https://lobehub.com/docs/self-hosting/server-database/docker-compose>.

**License:** Proprietary (source-available) · **Language:** Node.js / Next.js · **Default port:** 3210 · **Stars:** ~76,000

> **Note:** LobeHub is licensed as proprietary source-available software. Review the [LICENSE](https://github.com/lobehub/lobehub/blob/main/LICENSE) before commercial use.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (setup.sh) | <https://lobehub.com/docs/self-hosting/server-database/docker-compose> | ✅ | Recommended self-hosted path — spins up LobeHub + PostgreSQL + Minio (S3) + Casdoor (auth). |
| Vercel / Zeabur / Sealos | <https://lobehub.com/docs/self-hosting/platform/vercel> | ✅ | Serverless one-click deploy; limited to stateless mode (no DB persistence). |
| Docker single container | <https://hub.docker.com/r/lobehub/lobe-chat> | ✅ | Lightweight stateless mode; no user auth, no file storage. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Which install method — Docker Compose (full stack) or stateless single container?" | AskUserQuestion | Determines section below. |
| domain | "What domain will LobeHub be served on?" | Free-text | Docker Compose full stack. |
| ai_provider | "Which AI provider API key do you want to configure first? (OpenAI / Anthropic / Ollama / Other)" | AskUserQuestion | Both methods — at least one key needed. |
| api_key | "API key for <provider>?" | Free-text (sensitive) | All methods. |
| auth | "Enable multi-user auth via Casdoor (bundled), or single-user no-auth mode?" | AskUserQuestion: Casdoor / No auth | Docker Compose full stack. |
| s3 | "Use bundled Minio for file storage, or external S3-compatible storage?" | AskUserQuestion: Minio / External S3 | Docker Compose full stack. |

## Install — Docker Compose (recommended full stack)

Reference: <https://lobehub.com/docs/self-hosting/server-database/docker-compose>

```bash
mkdir lobehub-db && cd lobehub-db

# Run the official setup script — generates docker-compose.yml and .env interactively
bash <(curl -fsSL https://lobe.li/setup.sh)

# Start all services
docker compose up -d
```

The setup script provisions:
- **LobeHub** — Next.js frontend + API server
- **PostgreSQL** — persistent database
- **Minio** — S3-compatible file/image storage
- **Casdoor** — OAuth2/OIDC auth provider (multi-user)

After startup, LobeHub is available at `http://localhost:3210` (or your configured domain with TLS from your reverse proxy).

### Manual docker-compose.yml (reference structure)

If you prefer to compose manually, see the upstream template:
<https://github.com/lobehub/lobehub/blob/main/docker-compose/docker-compose.yml>

Key environment variables in `.env`:

```bash
# App
APP_URL=https://chat.example.com
NEXTAUTH_SECRET=<random 32-char string>

# Database
DATABASE_URL=postgresql://postgres:password@postgresql:5432/lobe

# Auth (Casdoor)
AUTH_CASDOOR_ISSUER=http://casdoor:8000
AUTH_CASDOOR_CLIENT_ID=<from casdoor app>
AUTH_CASDOOR_CLIENT_SECRET=<from casdoor app>

# S3 (Minio)
S3_ACCESS_KEY_ID=<minio root user>
S3_SECRET_ACCESS_KEY=<minio root password>
S3_BUCKET=lobe
S3_ENDPOINT=http://minio:9000
```

## Install — Single container (stateless mode)

Reference: <https://hub.docker.com/r/lobehub/lobe-chat>

```bash
docker run -d \
  -p 3210:3210 \
  -e OPENAI_API_KEY=sk-xxxx \
  -e ACCESS_CODE=yourpassword \
  --name lobehub \
  lobehub/lobe-chat
```

In stateless mode there is no persistent database — conversation history lives in the browser's localStorage only. No multi-user support; `ACCESS_CODE` is a simple shared password gate.

## Software-layer concerns

| Concern | Detail |
|---|---|
| Database | PostgreSQL — conversation history, agents, knowledge base. Required for full-stack mode. |
| File storage | Minio (bundled) or any S3-compatible endpoint — user file uploads, knowledge base assets. |
| Auth | Casdoor (bundled OAuth2 provider) for multi-user; or ACCESS_CODE env var for single-user stateless. |
| AI providers | Configure via env vars: OPENAI_API_KEY, ANTHROPIC_API_KEY, OLLAMA_PROXY_URL, etc. See full list in docs. |
| MCP marketplace | MCP plugins install per-agent via the in-app marketplace; requires internet access from the container. |
| Port | Default 3210; change via PORT env var or docker-compose ports mapping. |
| HTTPS | Required for camera/microphone access (TTS/STT). Put behind nginx/Caddy with TLS. |
| ARM support | Multi-arch Docker images available (amd64, arm64). |

## Upgrade procedure

```bash
cd lobehub-db
docker compose pull
docker compose up -d
```

Database migrations run automatically on startup. Back up PostgreSQL before major version upgrades:

```bash
docker compose exec postgresql pg_dump -U postgres lobe > lobe-backup-$(date +%Y%m%d).sql
```

## Gotchas

- **Proprietary license:** LobeHub is source-available but NOT open source. Review the license for commercial use restrictions before deploying publicly.
- **setup.sh required for full stack:** The setup script handles Casdoor application registration, secret generation, and inter-service wiring. Manual setup is complex — follow the upstream Docker Compose guide closely.
- **HTTPS for media features:** TTS/STT voice and camera features require a secure context (HTTPS). The app will work over HTTP but those features will be disabled.
- **Stateless vs full-stack:** The single `lobehub/lobe-chat` image is stateless — no DB, no auth, history lost on container restart. For production multi-user use, deploy the full stack via setup.sh.
- **MCP plugins internet access:** The MCP marketplace fetches plugin metadata from the internet. If your container is air-gapped, MCP discovery won't work (manually specify MCP server URLs instead).
- **Minio public URL:** If serving files to browsers, Minio must be accessible from the public internet (or your internal network) at the S3_ENDPOINT URL — not just container-internal.

## Upstream links

- GitHub: <https://github.com/lobehub/lobehub>
- Self-hosting docs: <https://lobehub.com/docs/self-hosting/start>
- Docker Compose guide: <https://lobehub.com/docs/self-hosting/server-database/docker-compose>
- Docker Hub: <https://hub.docker.com/r/lobehub/lobe-chat>
- Environment variables: <https://lobehub.com/docs/self-hosting/environment-variables>
