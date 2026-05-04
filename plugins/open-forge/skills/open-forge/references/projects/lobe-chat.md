# LobeChat (LobeHub)

Modern open-source AI chat platform with multi-model support, MCP plugin system, voice/vision capabilities, and a polished UI. Supports 40+ LLM providers (OpenAI, Claude, Gemini, Ollama, and more). Offers both a stateless single-user mode (localStorage) and a full server-side mode with PostgreSQL for multi-user/sync. 76K+ GitHub stars. Upstream: <https://github.com/lobehub/lobe-chat>. Docs: <https://lobehub.com/docs/self-hosting>.

## Compatible install methods

Verified against upstream README at <https://github.com/lobehub/lobe-chat#-self-hosting>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (with database) | `bash <(curl -fsSL https://lobe.li/setup.sh)` | ✅ | Recommended for production with multi-user auth + sync |
| Docker (stateless) | `docker run -p 3210:3210 lobehub/lobe-chat` | ✅ | Single-user, personal use, no database needed |
| Vercel one-click | <https://lobehub.com/docs/self-hosting/platform/vercel> | ✅ | Serverless deploy on Vercel (stateless mode) |
| Source | `pnpm install && pnpm build` | ✅ | Development |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| llm | "OpenAI API key (or other LLM provider key)?" | Free-text (sensitive) | All — at least one LLM key required |
| mode | "Deployment mode?" | `AskUserQuestion`: `Stateless (single user, localStorage)` / `Server-side (PostgreSQL, multi-user, auth)` | All |
| domain | "Public URL for LobeChat (e.g. `https://chat.example.com`)?" | Free-text | Server-side / production |
| auth | "Auth provider for server-side mode?" | `AskUserQuestion`: `Clerk` / `NextAuth (GitHub/Google/...)` / `None` | Server-side only |
| db | "PostgreSQL connection URL?" | Free-text (sensitive) | Server-side only |

## Software-layer concerns

### Stateless (single-user) Docker — simplest

```bash
docker run -d \
  -p 3210:3210 \
  -e OPENAI_API_KEY=sk-xxxx \
  -e ACCESS_CODE=your-password \
  --name lobe-chat \
  lobehub/lobe-chat
```

Visit `http://localhost:3210`. Data is stored in the browser. No database, no auth.

### Server-side mode (multi-user, with database)

Uses the lobehub setup script to initialize infrastructure:

```bash
mkdir lobehub-db && cd lobehub-db
bash <(curl -fsSL https://lobe.li/setup.sh)
docker compose up -d
```

The setup script generates a `docker-compose.yml` + `.env` with PostgreSQL, MinIO (S3-compatible storage), and LobeChat configured.

### Key environment variables

| Variable | Purpose | Notes |
|---|---|---|
| `OPENAI_API_KEY` | OpenAI API key | Any compatible provider key |
| `OPENAI_PROXY_URL` | Custom OpenAI-compatible base URL | For Ollama, LM Studio, etc. |
| `ACCESS_CODE` | Password to access the app | Comma-separate multiple codes |
| `APP_URL` | Public URL | Required for server-side mode |
| `DATABASE_URL` | PostgreSQL connection string | Server-side mode |
| `S3_*` | S3/MinIO storage credentials | Server-side mode (file uploads) |
| `NEXT_PUBLIC_S3_DOMAIN` | Public S3/MinIO domain | Server-side mode |
| `CLERK_SECRET_KEY` | Clerk auth secret key | When using Clerk for auth |
| `NEXTAUTH_SECRET` | NextAuth secret | When using NextAuth |
| `NEXTAUTH_URL` | NextAuth callback URL | When using NextAuth |
| `DISABLE_TELEMETRY` | Opt out of telemetry | `1` |

### Supported LLM providers

LobeChat supports 40+ providers via environment variables. Key ones:

| Provider | Env variable |
|---|---|
| OpenAI | `OPENAI_API_KEY` |
| Anthropic Claude | `ANTHROPIC_API_KEY` |
| Google Gemini | `GOOGLE_API_KEY` |
| Ollama (local) | `OLLAMA_PROXY_URL=http://host.docker.internal:11434` |
| OpenRouter | `OPENROUTER_API_KEY` |
| Mistral | `MISTRAL_API_KEY` |
| Azure OpenAI | `AZURE_API_KEY`, `AZURE_ENDPOINT` |

Full list: <https://lobehub.com/docs/self-hosting/environment-variables>

### MCP (Model Context Protocol) plugins

LobeChat supports MCP plugins for connecting AI to external tools and data. Configure in Settings → MCP. Works with any MCP-compatible server.

### Port layout

| Port | Service |
|---|---|
| `3210` | LobeChat web app (stateless Docker image) |
| `3000` | LobeChat web app (server-side setup script) |

### Data directories (server-side)

| Component | Storage |
|---|---|
| Conversations, settings | PostgreSQL |
| File uploads, attachments | S3/MinIO (`lobehub-db` volume) |
| Browser localStorage | Browser only (stateless mode) |

## Upgrade procedure

- **Docker:** `docker pull lobehub/lobe-chat && docker compose up -d`
- **Server-side:** `docker compose pull && docker compose up -d`

## Gotchas

- **Two very different deployment modes.** Stateless (localStorage) is simple but data is per-browser only. Server-side requires PostgreSQL + S3 + auth provider setup.
- **Stateless mode has no server auth beyond `ACCESS_CODE`.** For anything exposed to the internet, set `ACCESS_CODE`.
- **Ollama integration.** When running Ollama locally alongside Docker, use `http://host.docker.internal:11434` as `OLLAMA_PROXY_URL` so the container can reach the host.
- **Server-side mode requires Clerk or NextAuth.** You cannot run server-side mode without an auth provider. Clerk has a generous free tier.
- **S3 must be publicly readable for file previews.** MinIO in the default setup is configured for this; if using AWS S3, set bucket policy accordingly.
- **License: Apache 2.0.** Fully open-source.

## Links

- Upstream: <https://github.com/lobehub/lobe-chat>
- Docs: <https://lobehub.com/docs/self-hosting>
- Docker setup: <https://lobehub.com/docs/self-hosting/server-database/docker-compose>
- Environment variables: <https://lobehub.com/docs/self-hosting/environment-variables>
- Vercel deploy: <https://lobehub.com/docs/self-hosting/platform/vercel>
