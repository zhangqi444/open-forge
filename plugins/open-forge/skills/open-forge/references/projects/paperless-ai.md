---
name: Paperless-AI
description: "AI-powered extension for Paperless-ngx — automatic document classification, smart tagging, title + type + correspondent assignment, and RAG-based chat across your archive. Works with OpenAI, Ollama, DeepSeek, OpenRouter, Gemini, and more. Node.js. License per repo."
---

# Paperless-AI

Paperless-AI is **an AI-powered companion for Paperless-ngx** — the popular self-hosted document archiver. It monitors your Paperless-ngx instance, runs new documents through an LLM (OpenAI API, local **Ollama**, DeepSeek, OpenRouter, Perplexity, Together.ai, LiteLLM, vLLM, Fastchat, Gemini, or any OpenAI-compatible endpoint), and **automatically assigns title, tags, document type, and correspondent**. It also ships a **RAG-based chat interface** — ask "when did I sign my rental agreement?" or "what was the last electricity bill amount?" and get answers grounded in your own documents.

> **⚠️ IMPORTANT upstream notice — read before adopting:**
>
> From the project README (as of writing): *"This repo is currently not maintained. I'm rewriting the entire codebase... With the upcoming official AI integration in Paperless-ngx itself, I'm also not sure if I'll complete the rewrite or continue maintaining this repo at all."*
>
> **Implications:**
> - Pin exact Docker tag; do not rely on `latest`
> - New features + bug fixes are paused
> - **Paperless-ngx is adding native AI** — evaluate upstream's roadmap before committing
> - Community may fork / carry forward; watch for announcements

Features (when it works):

- **Automatic workflow** — new document → AI classification → tags/title/type/correspondent set
- **RAG chat** — semantic Q&A across full archive (not just keyword search)
- **Multi-provider support** — OpenAI, Ollama, OpenRouter, DeepSeek, Perplexity, Gemini, Together.ai, LiteLLM, vLLM, Fastchat, more
- **Manual processing mode** — review AI suggestions before applying (useful for sensitive docs)
- **Smart rules** — limit processing to specific tags/correspondents/types
- **Custom output tags** — mark classified docs so you can filter/audit
- **Docker-first** — clean deployment
- **Web UI** — configuration + chat + manual processing at `/manual`

- Upstream repo: <https://github.com/clusterzx/paperless-ai>
- Installation Wiki: <https://github.com/clusterzx/paperless-ai/wiki/2.-Installation>
- Docker Hub: <https://hub.docker.com/r/clusterzx/paperless-ai>

**Requires Paperless-ngx already running:** Paperless-AI is an addon, not a replacement. See Paperless-ngx: <https://github.com/paperless-ngx/paperless-ngx>.

## Architecture in one minute

- **Node.js** backend + simple web UI
- **SQLite** for local state (RAG index, settings, job history)
- Polls Paperless-ngx REST API for new documents
- Sends OCR text + thumbnail to configured LLM
- Parses LLM response → writes tags/title/type back via Paperless-ngx API
- RAG index built from your Paperless-ngx archive (embedded via chosen provider)
- **Resource**: light when using cloud LLM (~200 MB RAM); heavier with local Ollama (LLM needs GPU or 16+ GB RAM)

## Compatible install methods

| Infra              | Runtime                                                         | Notes                                                                        |
| ------------------ | --------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| Single VM          | **Docker (`clusterzx/paperless-ai`)**                               | **Upstream-recommended primary path**                                            |
| Same host as Paperless-ngx | Typical — shared docker-compose stack                                       | Reduces network hops                                                                     |
| Raspberry Pi       | Works with cloud LLMs; local Ollama needs more                                              | Depends on Pi model                                                                                  |
| Kubernetes         | Community manifests                                                                          | Simple Deployment                                                                                                |

## Inputs to collect

| Input                     | Example                                      | Phase        | Notes                                                                     |
| ------------------------- | -------------------------------------------- | ------------ | ------------------------------------------------------------------------- |
| Paperless-ngx URL         | `http://paperless:8000`                          | Integration  | API-reachable from Paperless-AI container                                         |
| Paperless-ngx API token   | per-user token                                         | Auth         | Generate in Paperless-ngx settings                                                                |
| LLM provider              | OpenAI / Ollama / OpenRouter / ...                             | AI           | Pick one; Ollama for privacy, OpenAI for quality                                                                  |
| LLM API key / Ollama URL  | depends on provider                                                      | Auth         | Env vars                                                                                                             |
| Model                     | `gpt-4o-mini` / `llama3.2` / `mistral` / `phi-3` / ...                   | AI           | Smaller models cheaper; larger more accurate                                                                                                               |
| Embeddings model          | for RAG                                                                       | AI           | Per-provider                                                                                                                                       |
| Admin password            | first-run setup                                                                              | Bootstrap    | Web UI auth                                                                                                                                                       |

## Install via Docker

```yaml
services:
  paperless-ai:
    image: clusterzx/paperless-ai:2.7.1                 # PIN — unmaintained; don't use 'latest'
    container_name: paperless-ai
    restart: unless-stopped
    depends_on:
      - paperless
    environment:
      PAPERLESS_AI_PORT: 3000
    volumes:
      - ./data:/app/data
    ports:
      - "3000:3000"
```

Browse `http://<host>:3000/` → setup wizard → enter Paperless URL + API token + LLM config → **restart container** (required after first setup to build RAG index; documented).

## First boot

1. Browse → create admin password
2. Configure Paperless-ngx URL + API token
3. Pick LLM provider + model → test connection
4. **Restart container** to build RAG index
5. Let it process existing documents (can take hours for large archives)
6. Monitor `/manual` for any needing review
7. Try RAG chat: "Show me all documents from [correspondent]" / "What's my electricity usage trend?"
8. Tune rules: limit processing scope, exclude sensitive document types

## Data & config layout

- `/app/data/` — SQLite + RAG embeddings + config
- Env vars — provider keys + Paperless URL
- Treat `/app/data` as backup-worthy (rebuild possible but expensive)

## Backup

```sh
sudo tar czf paperless-ai-$(date +%F).tgz data/
```

RAG index can be rebuilt from Paperless-ngx if lost — but takes time + API calls.

## Upgrade

1. Releases: <https://github.com/clusterzx/paperless-ai/releases> — **currently frozen**.
2. Don't upgrade until maintenance resumes or a fork appears.
3. Pin version. Monitor issue tracker for project direction announcement.

## Gotchas

- **Unmaintained status** — repeat: upstream is on pause; Paperless-ngx native AI is coming. **Do not deploy to production** expecting active development. Use as-is or evaluate alternatives.
- **API key exposure**: Paperless-AI holds your Paperless-ngx API token + LLM provider keys. Compromise of the container = both leaked. Use restricted keys where possible (LLM quota caps, Paperless-ngx token scoped to a dedicated user).
- **Cloud-LLM = document content uploaded to provider**: OpenAI/Gemini/Anthropic see your OCR'd documents. **For sensitive docs (medical, legal, financial), use local Ollama or a privacy-focused provider** with a DPA. Consider what regulations cover your archive (HIPAA, GDPR for EU residents).
- **Ollama option for privacy**: runs locally → documents never leave host. Quality depends on model size — llama3.2:3b is OK, llama3.1:8b better, 70B excellent but needs serious hardware.
- **Restart required after setup** — explicitly noted in upstream: first-time install requires restarting the container after entering API keys + preferences, so the RAG index builds. Not required for updates.
- **RAG index build cost**: embeds every document → API calls / GPU time. 10k-document archive at ~$0.0001 per embedding = ~$1 on OpenAI; free on Ollama (just slow).
- **Initial classification pass can be expensive** — each document runs through LLM. Tune smart rules to limit scope before first run.
- **Token / cost blowup risk**: if you have 50k documents and run all through gpt-4o, the bill can surprise you. Set LLM provider spending limits *before* first run. (Extends batch 69 Manifest cost-tracking precedent.)
- **Classification accuracy varies**: tags + correspondents + types are auto-created; LLMs invent new ones liberally. Expect to clean up taxonomy after initial pass. Use controlled-vocabulary rules.
- **Custom prompts**: supported; tune for your language/jurisdiction (e.g., German invoice layouts, US receipts).
- **Paperless-ngx compatibility**: tracks a specific Paperless-ngx API contract. If Paperless-ngx significantly changes its API, Paperless-AI may break (and won't be fixed during the maintenance pause).
- **License**: check repo `LICENSE` file.
- **Alternatives worth knowing:**
  - **Paperless-ngx native AI** (in development) — evaluate first; will likely replace Paperless-AI
  - **paperless-gpt** — similar project; actively maintained fork/alternative
  - **Paperless-ngx + Home Assistant + custom automation** — DIY path
  - **Ollama + manual scripting via Paperless-ngx API** — roll your own
  - **Commercial DMS with AI** — DocuWare, M-Files (expensive)
  - **Choose Paperless-AI if:** you already have Paperless-ngx + accept the unmaintained status + want it working today.
  - **Otherwise**: wait for Paperless-ngx native AI or evaluate paperless-gpt.

## Links

- Repo: <https://github.com/clusterzx/paperless-ai>
- Installation Wiki: <https://github.com/clusterzx/paperless-ai/wiki/2.-Installation>
- Docker Hub: <https://hub.docker.com/r/clusterzx/paperless-ai>
- Paperless-ngx (required): <https://github.com/paperless-ngx/paperless-ngx>
- Paperless-ngx native AI discussion: <https://github.com/paperless-ngx/paperless-ngx/discussions>
- paperless-gpt (alt): <https://github.com/icereed/paperless-gpt>
- Ollama (local LLMs): <https://ollama.com>
- OpenAI pricing: <https://openai.com/pricing>
